# HabitAI

> Gestor de hábitos con IA generativa. Describes tus metas, Gemini diseña un plan personalizado y la app te acompaña día a día.

Proyecto desarrollado como **Trabajo Final de Grado** del ciclo 2º DAM (Desarrollo de Aplicaciones Multiplataforma).

---

## ✨ Características

### Core
- **Autenticación** con email/contraseña y Google Sign-In (Firebase Auth).
- **Onboarding con IA**: describes tus metas y Gemini genera un grupo de hábitos adaptado a tu rutina.
- **Gestión de hábitos**: CRUD, frecuencia personalizable por días, horario de recordatorio, categorías (Salud, Productividad, Bienestar, Social, Aprendizaje, Finanzas).
- **Grupos de hábitos**: los planes generados por la IA se agrupan con título y emoji, editables desde la app.
- **Check-in diario** con cálculo real de rachas (actuales y mejores) y haptic feedback.
- **Detalle de hábito** con grid de actividad estilo GitHub de los últimos 30 días.

### IA como coach
- **Chat con Gemini 2.5 Pro** vía Cloud Functions como proxy seguro (rate limiting, API key en servidor).
- **Revisión semanal automática** cada lunes: Cloud Scheduler → Pub/Sub → Cloud Function analiza la semana anterior y genera wins, struggles, recomendaciones accionables y foco semanal.
- **Simulador del Efecto Mariposa**: cada inicio de mes, la IA proyecta dos futuros a 3 años (manteniendo vs. abandonando los hábitos) en forma de narrativa inmersiva.

### Gamificación y social
- **Sistema de logros** con 11 tipos, banner animado al desbloquear.
- **Niveles por categoría** con radar chart hexagonal del perfil de hábitos.
- **Escudos de racha** para congelar rachas en días libres o de enfermedad.
- **Plantillas de la comunidad**: marketplace global para publicar grupos propios e importar los de otros con un tap.
- **Perfiles públicos** con lista de hábitos activos (opt-in).

### Dashboard
- Gráfica semanal con `fl_chart`, stats agregadas, distribución por categoría (pie chart) y rachas activas.
- Vistas de detalle: 30 días, desglose por categoría, todas las rachas.

---

## 🛠️ Stack técnico

| Capa | Tecnología |
|------|------------|
| Frontend | Flutter 3.41.6 · Dart 3.x |
| Diseño | Material Design 3 + `google_fonts` |
| Navegación | `go_router` con auth guard y ShellRoute |
| Animaciones | `flutter_animate` |
| Auth | Firebase Authentication (email + Google) |
| Base de datos | Cloud Firestore (región Europa) |
| IA | Gemini 2.5 Pro vía `firebase_ai` |
| Proxy IA | Firebase Cloud Functions (Node.js 20, `europe-west1`) |
| Jobs programados | Cloud Scheduler + Pub/Sub |
| Gráficas | `fl_chart` |

---

## 🏗️ Arquitectura

Estructura **feature-first** con separación en tres capas por feature:

```
lib/
├── main.dart                     # Init Firebase + runApp
├── app.dart                      # MaterialApp + AuthProvider
├── core/
│   ├── router/app_router.dart    # go_router + auth guard + ShellRoute
│   ├── theme/                    # Material 3, paleta, tipografía
│   └── widgets/                  # Reutilizables (drawer, snackbars, skeletons, empty states)
└── features/
    ├── auth/                     # Login, registro, Google Sign-In
    ├── onboarding/               # Wizard con IA
    ├── habits/                   # CRUD, logs, rachas, grupos
    ├── dashboard/                # Stats, gráficas, weekly review, butterfly
    ├── ai/                       # Chat Gemini, plan generado
    ├── achievements/             # Logros + overlay
    ├── levels/                   # Niveles por categoría
    ├── community/                # Plantillas públicas
    ├── profile/                  # Perfiles públicos
    └── settings/
```

Cada feature respeta:
- **domain/** — Modelos puros (sin dependencias de Firebase).
- **data/** — Repositorios que encapsulan Firebase/Cloud Functions.
- **presentation/** — Screens y widgets. Solo hablan con el repositorio.

### Flujo de IA (proxy seguro)

```
Flutter  →  Cloud Function (callable)  →  Gemini (Firebase AI Logic)
              │
              ├── verifica auth token
              ├── rate limit 10 req/hora
              ├── prompt engineering en servidor
              └── parseo JSON
```

### Modelo de datos (Firestore)

```
users/{uid}
  ├── habits/{habitId}
  │     └── logs/{logId}
  ├── achievements/{achievementId}
  ├── ai_conversations/{conversationId}
  ├── weekly_reviews/{weekId}        # 2026-W15
  └── butterfly_projections/{monthId} # 2026-04

community_templates/{templateId}
  └── habits/{habitSnapshotId}
```

Reglas Firestore deny-by-default; cada doc valida `request.auth.uid == userId`.

---

## 🚀 Instalación

### Requisitos
- Flutter 3.41.6+
- Dart 3.x
- Cuenta de Firebase (plan **Blaze** requerido para Cloud Functions)
- Android SDK / emulador o dispositivo iOS
- Node.js 20+ (para desplegar Cloud Functions)

### Pasos

```bash
# 1. Clonar
git clone https://github.com/Fepe7/habit-ai.git
cd habit-ai

# 2. Configurar Firebase con tu propio proyecto
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Dependencias
flutter pub get

# 4. Ejecutar
flutter run
```

### Cloud Functions

```bash
cd functions
npm install
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

Tras el primer deploy, Cloud Scheduler crea automáticamente los jobs `weeklyReviewJob` (lunes 08:00 Europe/Madrid) y `butterflyProjectionJob` (día 1 del mes 09:00).

### Reglas de seguridad mínimas

```javascript
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
  match /{sub}/{doc} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
}
```

---

## 🎨 Paleta

| Rol | Hex |
|-----|-----|
| Primary (azul cielo) | `#38BDF8` |
| Secondary | `#0EA5E9` |
| Success | `#10B981` |
| Streak / logros | `#F59E0B` |
| Error | `#EF4444` |

Cada categoría de hábito tiene su par fondo/texto propio (ver `core/theme/app_theme.dart`).

---

## 👤 Autor

**Andrei Felipe Staicu** — 2º DAM
[github.com/Fepe7](https://github.com/Fepe7)
