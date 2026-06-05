# Plan — Manejo offline (check-in optimista)

## Context

El ticket de Trello *"Manejo offline (check-in optimista)"* es bloqueante de lanzamiento: una app de hábitos se usa sin cobertura. Tras explorar el código (vía graphify + lectura directa), **la mayor parte de la infraestructura ya existe**:

- `ConnectivityService` (singleton con `ValueNotifier<bool> isOnline`), inicializado en `main.dart`.
- `OfflineBanner` ya montado en `main_shell.dart` (ramas mobile y tablet).
- `OnlineGuard` para bloquear acciones que requieren red.
- Persistencia offline de Firestore activada (100 MB) en `main.dart`.
- El check-in **ya pinta optimista**: `_toggleHabit` hace `setState` antes del `await`.

**El gap real** es el `await` bloqueante de las escrituras Firestore. Offline, el `Future` de una escritura (`.add`/`.update`/`batch.commit`) **no se resuelve hasta reconectar**. En `_toggleHabit` (`habits_screen.dart:272-273`) el `await _habitRepo.addLog(...)` queda **colgado**, de modo que:

- El check optimista aparece ✅, pero **la racha no sube**, ni corren el bonus de cadena, los logros, ni analytics hasta que vuelve la red.
- Al reconectar, el `await` se libera y el flujo post-check corre tarde, con datos potencialmente desfasados.

**Outcome buscado**: que offline el check-in complete su lógica local al instante (racha, bonus, logros) sin esperar reconexión, y que cada hábito con un cambio aún sin sincronizar muestre un indicador sutil que desaparece cuando Firestore confirma la escritura en servidor.

**Decisiones acordadas con el usuario**:
- Alcance: **arreglar el flujo colgado + indicador de "pendiente de sincronizar"**.
- Racha offline: **reusar `_calculateStreak` leyendo desde la caché local de Firestore** (la escritura encolada ya está en caché, con `hasPendingWrites`).

---

## Enfoque

La clave: **dejar de esperar el ack del servidor**. Firestore aplica cada mutación a la caché local de forma síncrona en el momento de invocar `.add/.set/.update`, y la sincroniza sola al reconectar. Por tanto, el flujo de check-in debe disparar las escrituras **sin `await` bloqueante** y correr la lógica local de inmediato. El indicador de pendiente se deriva de `metadata.hasPendingWrites` del documento del hábito (la escritura de `updateStreak` marca ese doc como pendiente hasta sincronizar).

---

## Cambios

### 1. `lib/features/habits/data/habit_repository.dart`

**a) `addLog` — id síncrono, sin depender del ack.** Hoy usa `await _logsRef(habitId).add(...)`, cuyo `Future` cuelga offline y no devuelve el id. Cambiar a generar el `DocumentReference` localmente para obtener el id sin esperar al servidor:

```dart
Future<String> addLog(String habitId, HabitLogModel log) async {
  final docRef = _logsRef(habitId).doc(); // id generado en cliente, síncrono
  // No await el ack: offline se encola y aplica a la caché local al instante.
  unawaited(docRef.set(log.toJson()).catchError((_) {}));
  return docRef.id;
}
```
(añadir `import 'dart:async';` para `unawaited`).

**b) `watchTodayHabits()` — exponer estado de sincronización.** Hoy descarta la metadata. Emitir, por hábito, si tiene escrituras pendientes, usando `includeMetadataChanges: true` para que el stream re-emita al confirmarse la escritura:

```dart
Stream<List<HabitWithSync>> watchTodayHabits() {
  final today = DateTime.now().weekday;
  return _habitsRef
      .where('isActive', isEqualTo: true)
      .where('targetDays', arrayContains: today)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => snapshot.docs
          .map((doc) => HabitWithSync(
                habit: HabitModel.fromJson(doc.data(), doc.id),
                pendingSync: doc.metadata.hasPendingWrites,
              ))
          .toList());
}
```
Definir un record/clase ligera `HabitWithSync` (record de Dart 3: `typedef HabitWithSync = ({HabitModel habit, bool pendingSync});`) en el repo o en `domain/`. El modelo de dominio `HabitModel` **no** se toca (sigue puro, sin metadata de Firestore).

> Nota: `watchTodayHabitsByGroup` (usado en la pantalla de grupo) se deja igual por ahora; el indicador se prioriza en la lista principal. Si se quiere también en grupos, aplicar el mismo patrón.

### 2. `lib/features/habits/presentation/habits_screen.dart`

**a) Reescribir `_toggleHabit` para no bloquear en el ack** (`habits_screen.dart:265-348`). Disparar las mutaciones sin `await` bloqueante y correr la lógica local inmediatamente. El orden de invocación garantiza que el log ya está en la caché antes de que `updateStreak` lo lea:

```dart
Future<void> _toggleHabit(HabitModel habit) async {
  final wasCompleted = _completedToday[habit.id] ?? false;
  setState(() => _completedToday[habit.id] = !wasCompleted);

  // Disparar la mutación sin esperar al servidor: Firestore aplica a la caché
  // local de inmediato y sincroniza al reconectar. .catchError evita un
  // unhandled-future si la escritura falla de verdad (online, p.ej. permisos).
  if (!wasCompleted) {
    final log = HabitLogModel(id: '', date: DateTime.now(), completed: true);
    addLog(...) // sin await; updateStreak() a continuación lee el log de caché
    updateStreak(...) // sin await
    AnalyticsService.instance.logHabitCheckin(habit.id);
  } else {
    uncheckAndRecalculate(...) // sin await
  }

  // ...el resto del post-check (bonus de cadena, nudges, overlay, logros, sync
  //    de reto) corre exactamente igual que hoy, pero ya NO detrás de un await
  //    colgado, así que se ejecuta al instante también offline.
}
```
Detalles:
- Mantener el rollback de UI, pero adjuntarlo como `.catchError` no bloqueante sobre la escritura (offline el future nunca falla → no hay rollback espurio; solo revierte ante un error real online).
- El bloque de logros (`getHabit` + `checkAfterToggle`, líneas 324-336) lee de caché offline; dejarlo en su `try/catch` actual.

**b) Consumir el nuevo stream.** El `StreamBuilder<List<HabitModel>>` pasa a `StreamBuilder<List<HabitWithSync>>`. Derivar `allHabits` (`.map((e) => e.habit)`) y un `Set<String> _pendingSyncIds` con los `habit.id` cuyo `pendingSync == true`. Pasar ese set a `_GroupSection`/`_UngroupedSection` igual que se pasa hoy `_completedToday`.

### 3. `lib/features/habits/presentation/widgets/habit_card.dart`

Añadir un parámetro `final bool pendingSync;` (default `false`) al constructor de `HabitCard` (`habit_card.dart:13-45`). Cuando `pendingSync` sea `true`, mostrar un indicador **sutil** junto al título/racha: `Icon(Icons.cloud_off_rounded, size: 14, color: scheme.outline)` con `Tooltip('Se sincronizará al volver la conexión')`. Reusar el color `outline`/Slate del tema (no usar el rojo de error: no es un fallo, es estado transitorio). Propagarlo desde `_GroupSection`/`_UngroupedSection` a partir de `_pendingSyncIds.contains(habit.id)`.

---

## Verificación (end-to-end)

1. `flutter analyze` limpio (atención a `unawaited`/imports y al cambio de tipo del stream).
2. Emulador Android API 36: marcar un hábito **online** → check + racha suben; el icono de pendiente aparece ~instante y desaparece en <1s al confirmarse en servidor.
3. **Activar modo avión** en el emulador:
   - Marcar un hábito → el check aparece, **la racha sube al instante**, el bonus de cadena/overlay/logros se disparan, y aparece el icono `cloud_off`. El `OfflineBanner` superior se muestra.
   - Desmarcar otro hábito → la racha baja correctamente (lee de caché).
   - Cerrar y reabrir la app **sin red** → el estado marcado persiste (caché Firestore).
4. **Desactivar modo avión** → el banner desaparece, y los iconos `cloud_off` de los hábitos tocados desaparecen al sincronizarse (verifica que `includeMetadataChanges` re-emite). Confirmar en la consola de Firestore que los logs y `currentStreak` quedaron escritos.
5. Comprobar que no hay errores `Unhandled Future` en consola tras togglear varias veces offline y reconectar.

## Notas / riesgos

- `getTodayLog`, `_calculateStreak`, `getHabit`, `deleteTodayLog` ya usan `.get()`/`.snapshots()`, que offline caen a caché — no requieren cambios.
- El indicador se basa en el `hasPendingWrites` del **doc del hábito** (lo marca `updateStreak`). Check-in (log) y racha (hábito) se disparan juntos, así que sincronizan casi a la vez; es una aproximación fiel para el usuario.
- No se añade ninguna dependencia nueva: `connectivity_plus` ya está y Firestore ya persiste.
