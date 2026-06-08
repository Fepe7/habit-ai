# Guía de uso — Skill `impeccable`

Guía práctica para usar el plugin/skill **impeccable** en HabitAI.
Ubicación de la skill: `.claude/skills/impeccable/` (documento fuente: `SKILL.md`,
modos detallados en `reference/*.md`).

---

## Qué es

Skill para **diseñar e iterar interfaces frontend con código real** (no mockups).
Trabaja sobre el código Flutter del proyecto, con criterio de diseño profesional.
Se invoca escribiendo `/impeccable` o pidiéndole a Claude que la use.

---

## Cómo se usa: comando + objetivo

```
/impeccable <comando> <objetivo>
```

- **`<comando>`** = qué quieres hacer (`critique`, `polish`, `bolder`…).
- **`<objetivo>`** = sobre qué (una pantalla, un componente, una ruta o archivo).

Si la invocas **sin argumentos** (`/impeccable` a secas), muestra el menú de
comandos agrupados por categoría y pregunta qué quieres hacer.

---

## Los 2 archivos de contexto

Antes de cualquier trabajo de diseño, impeccable carga dos archivos del proyecto
(búsqueda en la raíz y, si no, en `.agents/context/` y `docs/`):

| Archivo | Estado | Para qué sirve |
|---|---|---|
| **PRODUCT.md** | requerido | Usuarios, marca, tono, anti-referencias, principios estratégicos |
| **DESIGN.md** | opcional (muy recomendado) | Colores, tipografía, elevación, componentes |

- HabitAI **ya tiene `DESIGN.md`** (ver CLAUDE.md → sistema visual).
- Si **falta `PRODUCT.md`** (o está vacío/placeholder), impeccable ejecuta primero
  `/impeccable teach` para crearlo mediante preguntas, y luego retoma la tarea.
- Sin este contexto, el resultado sería genérico ("AI slop").

Override de carpeta de contexto: variable `IMPECCABLE_CONTEXT_DIR=ruta`.

---

## Comandos disponibles

### Construir (Build)
| Comando | Descripción |
|---|---|
| `craft [feature]` | Planifica **y** construye una feature de punta a punta |
| `shape [feature]` | Planifica UX/UI antes de escribir código |
| `teach` | Crea/configura `PRODUCT.md` y `DESIGN.md` |
| `document` | Genera `DESIGN.md` a partir del código existente |
| `extract [target]` | Extrae tokens y componentes reutilizables al design system |

### Evaluar (no tocan código, solo analizan)
| Comando | Descripción |
|---|---|
| `critique [target]` | Review de UX con puntuación heurística |
| `audit [target]` | Chequeos técnicos: accesibilidad, rendimiento, responsive |

### Refinar
| Comando | Descripción |
|---|---|
| `polish [target]` | Pase final de calidad antes de publicar |
| `bolder [target]` | Amplifica diseños sosos o conservadores |
| `quieter [target]` | Calma diseños demasiado agresivos |
| `distill [target]` | Reduce a la esencia, quita complejidad |
| `harden [target]` | Producción: errores, i18n, casos límite |
| `onboard [target]` | Flujos de primer uso, estados vacíos, activación |

### Mejorar (Enhance)
| Comando | Descripción |
|---|---|
| `animate [target]` | Añade animaciones y movimiento con propósito |
| `colorize [target]` | Añade color estratégico a UIs monocromas |
| `typeset [target]` | Mejora jerarquía tipográfica y fuentes |
| `layout [target]` | Arregla espaciado, ritmo y jerarquía visual |
| `delight [target]` | Añade personalidad y detalles memorables |
| `overdrive [target]` | Empuja más allá de los límites convencionales |

### Arreglar (Fix)
| Comando | Descripción |
|---|---|
| `clarify [target]` | Mejora textos UX, labels y mensajes de error |
| `adapt [target]` | Adapta a distintos dispositivos y tamaños |
| `optimize [target]` | Diagnostica y corrige rendimiento de UI |

### Iterar
| Comando | Descripción |
|---|---|
| `live` | Modo variantes: eliges elementos en el navegador y genera alternativas (pensado para web; en Flutter aplica parcialmente) |

---

## Reglas de enrutado (cómo interpreta tu entrada)

1. **Sin argumento** → muestra el menú y pregunta.
2. **Primera palabra = un comando** → carga su `reference/<comando>.md` y sigue sus
   instrucciones. Todo lo que va después del comando es el objetivo.
3. **Primera palabra ≠ comando** → invocación general de diseño, usando todo el
   argumento como contexto.

---

## Ejemplos para HabitAI

```
# Evaluar la pantalla de ajustes con puntuación
/impeccable critique lib/features/settings/presentation/settings_screen.dart

# Pulido final del perfil propio y el público
/impeccable polish el perfil propio y el perfil público

# Revisión técnica de accesibilidad/contraste/touch targets
/impeccable audit la pantalla de ajustes

# Planificar antes de construir una feature nueva
/impeccable shape pantalla de estadísticas semanales
```

---

## Atajos: `pin` / `unpin`

Crea un acceso directo para no escribir `impeccable` cada vez:

```bash
node .claude/skills/impeccable/scripts/pin.mjs pin critique
```

A partir de entonces `/critique <target>` equivale a `/impeccable critique <target>`.
Se elimina con:

```bash
node .claude/skills/impeccable/scripts/pin.mjs unpin critique
```

---

## Principios de diseño que aplica (resumen)

- **Color** en OKLCH; nunca `#000`/`#fff` puros; elegir estrategia de color
  (restrained / committed / full palette / drenched) antes que colores.
- **Tema** claro vs oscuro nunca por defecto: se justifica con una "escena física".
- **Tipografía**: line length 65–75ch; jerarquía por escala y peso (ratio ≥1.25).
- **Layout**: variar espaciado; las cards son el recurso fácil (evitar abuso y
  nunca anidarlas); no envolver todo en contenedores.
- **Motion**: no animar propiedades de layout; ease-out exponencial, sin bounce.
- **Prohibiciones**: bordes laterales de color como acento, texto con gradiente,
  glassmorphism decorativo por defecto, plantilla "hero-metric", rejillas de cards
  idénticas, modal como primera opción.
- **Copy**: cada palabra cuenta; **sin guiones largos (em dash)**.
- **Test anti-slop**: si alguien podría decir "esto lo hizo una IA" sin dudar, falla.

---

## Notas del proyecto

- Ya hubo un uso previo de impeccable sobre perfil/ajustes: rama
  `design/profile-settings-impeccable` y carpeta `.impeccable/` con `design.json`
  y `critique/` (críticas v1/v2).
- Documento fuente completo: `.claude/skills/impeccable/SKILL.md`.
- Referencias por comando: `.claude/skills/impeccable/reference/<comando>.md`.
