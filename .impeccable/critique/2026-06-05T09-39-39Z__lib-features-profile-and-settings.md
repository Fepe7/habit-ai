---
target: la pantalla de perfil y sus ajustes
total_score: 27
p0_count: 0
p1_count: 2
timestamp: 2026-06-05T09-39-39Z
slug: lib-features-profile-and-settings
---
# Crítica de diseño: Perfil y Ajustes

Target: profile_screen, edit_profile_screen, settings_screen, privacy_settings_screen

## Design Health Score
| # | Heurística | Score | Problema clave |
|---|-----------|-------|----------------|
| 1 | Visibilidad del estado | 3 | Username se guarda en silencio, sin confirmación |
| 2 | Mundo real | 3 | Icono menu_rounded para abrir Ajustes (debería ser engranaje) |
| 3 | Control y libertad | 2 | Username se guarda al instante; nombre/bio esperan a Guardar |
| 4 | Consistencia | 2 | Radios fuera de escala, bordes 1px duros, botón tonal-14 vs DESIGN.md |
| 5 | Prevención de errores | 3 | Borrado doble-confirm (excelente); nombre puede quedar vacío |
| 6 | Reconocer vs recordar | 3 | Privacidad enterrada bajo Información; dos menús en cabecera |
| 7 | Flexibilidad | 3 | Tap en toda la tarjeta, contadores tapeables |
| 8 | Estético/minimalista | 2 | Gradiente sobre identidad + badge autorreferencial HabitAI |
| 9 | Recuperación de errores | 3 | Snackbars y guía re-login; strings de error sin localizar |
| 10 | Ayuda | 3 | Tooltip escudos, diálogo modo enfermedad, descripciones privacidad |
| Total | | 27/40 | Funcional con brechas notables de consistencia |

## Anti-Patterns Verdict
No es slop flagrante; construido a mano con personalidad. Tells: gradiente hero como decoración de identidad (viola Color-As-Reward Rule), badge "HabitAI" autorreferencial duplicado en perfil y ajustes, tres tratamientos distintos del "yo". Detector no disponible (detect.mjs ausente; orientado a markup web, no Dart). Assessment independence: degraded. Sin navegador para app Flutter.

## What's Working
1. Flujo de borrado de cuenta: doble confirmación + escribir ELIMINAR + guía re-login. Peak-end correcto.
2. Pantalla de privacidad: divulgación progresiva real (hasUsername gate, label dinámico público/seguidores, selector 3 niveles por hábito).
3. SegmentedButton para tema/idioma: patrón estándar, sin reinventar.

## Priority Issues
[P1] Consistencia rompe el propio DESIGN.md: radios fuera de escala (10/12/14/18/20/28 vs 8/24/32/36/full), bordes 1px duros en _StatTile y _ProfileHabitCard (violan Ghost-Border + Surface-Shift-First), botón Editar perfil es tonal radio-14 en vez de pill universal, TextField con decoración propia en vez de inputDecorationTheme global. Fix: SurfaceCard, eliminar Border.all duros, pill global, heredar tema de inputs. Comando: polish + layout.

[P1] Privacy-first enterrado: master switch público/privado bajo Ajustes>Información entre Acerca de y Valorar app; Protección de racha debajo de Legal. Contradice principio estratégico 4. Fix: subir Privacidad a sección de primer nivel; mover Protección de racha sobre Info/Legal. Comando: layout.

[P2] Modelo de guardado mixto en editar perfil: nombre/bio via botón Guardar, username persiste inmediato e independiente. Sin señal. Fix: unificar o marcar que username se guarda al instante. Comando: clarify.

[P2] Gradiente y badge autorreferencial sobre identidad: gradiente en header, tarjeta ajustes y anillo avatar; badge HabitAI duplicado. Viola Color-As-Reward. Fix: gradiente para una sola acción por pantalla; eliminar badge HabitAI del perfil propio. Comando: quieter.

[P3] Legibilidad/estados/i18n: labels a fontSize 9-10 (sub-legible), spinners en vez de skeletons, strings de error hardcodeados en español en privacy_settings, SwitchListTile con TextStyle literal. Fix: labels min 11px, skeletons, localizar errores, usar textTheme. Comando: harden.

## Persona Red Flags
Jordan (primerizo): perfil nuevo con anillo vacío, badge HabitAI confuso, dos iconos de menú en cabecera, privacidad a 3 taps. Abandona antes de descubrir la red social.
Maya (privacidad, 18-35 autoconsciente): quiere control de visibilidad antes de registrar; existe y es bueno pero escondido bajo Información. Reaseguro llega tarde.
Alex (power user): cambia username, da atrás, ya se guardó. Sin undo ni aviso.

## Minor Observations
- settings usa surfaceContainerLow de fondo, profile usa surface. Hermanas con base distinta.
- Badge check sobre avatar (perfil público) se lee como "cuenta verificada por plataforma".
- _initials duplicado en profile y settings; AvatarCircle.fromName ya existe.

## Questions to Consider
- ¿Qué gana el usuario viendo el nombre de la app sobre su propio perfil vs un dato real?
- Si privacy-first es pilar, ¿no debería estar a un tap del perfil?
- ¿Una versión segura de editar perfil guardaría el username con el resto?
