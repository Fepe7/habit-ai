---
target: la pantalla de perfil y sus ajustes
total_score: 35
p0_count: 0
p1_count: 0
timestamp: 2026-06-05T09-57-45Z
slug: lib-features-profile-and-settings
---
# Re-crítica: Perfil y Ajustes (tras 6 pases)

Target: profile_screen, edit_profile_screen, settings_screen, privacy_settings_screen

## Design Health Score
| # | Heurística | Score | Nota |
|---|-----------|-------|------|
| 1 | Visibilidad del estado | 4 | Username confirma éxito; skeletons en carga |
| 2 | Mundo real | 3 | menu_rounded para abrir Ajustes (falta engranaje) |
| 3 | Control y libertad | 3 | Guardado de username comunicado, sigue inmediato |
| 4 | Consistencia | 3 | Bordes/pill/inputs/radios resueltos; quedan header custom vs AppBar y fondos distintos |
| 5 | Prevención de errores | 3 | Campo Nombre acepta vacío al guardar |
| 6 | Reconocer vs recordar | 4 | Privacidad ahora primer nivel |
| 7 | Flexibilidad | 3 | Sin cambios |
| 8 | Estético/minimalista | 4 | Badge fuera, gradiente reservado, labels legibles |
| 9 | Recuperación de errores | 4 | Errores localizados + estados de éxito |
| 10 | Ayuda | 4 | Hint del username añadido |
| Total | | 35/40 | Sólido, pulido menor pendiente |

## Anti-Patterns Verdict
Menos "IA" que antes. Tells resueltos: sin bordes 1px duros, sin sopa de radios, gradiente reservado a un momento por pantalla, badge autorreferencial HabitAI eliminado. Consistencia con DESIGN.md restaurada (3 campos de editar perfil unificados, botones pill, tarjetas por superficie, radios en escala 8/20/24/32). IA de ajustes coherente con privacy-first. Detector ausente (detect.mjs not found; markup web, no Dart). Assessment independence: degraded. Sin navegador.

## What's Working
1. Coherencia de componentes entre las 4 pantallas (inputs, botones, tarjetas, radios).
2. Privacidad de primera clase: a un tap del perfil, no a tres bajo Información.
3. Estados de carga con skeleton en privacidad e Hábitos visibles.

## Priority Issues
[P2] Campo Nombre acepta vacío al guardar: _save ejecuta updateProfile(displayName:'') aunque omita updateDisplayName. Puede dejar el perfil sin nombre. Fix: deshabilitar Guardar si nombre vacío o mantener previo + error inline. Comando: harden.

[P3] menu_rounded abre Ajustes en cabecera de perfil: dos affordances de menú (DrawerMenuButton + menu_rounded), una abre drawer y otra ajustes. Fix: icono settings_outlined. Comando: clarify.

[P3] Inconsistencias de superficie y cabecera: settings usa surfaceContainerLow, profile usa surface; perfil/ajustes cabecera custom, editar/privacidad AppBar. Fix: unificar fondo y patrón de cabecera tab vs detalle. Comando: polish.

## Persona Red Flags
Jordan (primerizo): perfil limpio, Privacidad visible al abrir Ajustes; único tropiezo el icono hamburguesa que lleva a Ajustes.
Maya (privacidad): encuentra el control de inmediato, carga con skeletons. Sin fricción.
Alex (power user): hint le avisa del guardado inmediato del username; pero borra el nombre y guarda en blanco sin guardia.

## Minor Observations
- Badge check sobre avatar se lee como verificado-por-plataforma; considerar glifo public/visibility.
- _initials duplicado en profile y settings; AvatarCircle.fromName ya cubre.
- profile_screen arrastra avisos linter S.of(context)! (patrón global inofensivo).

## Questions to Consider
- ¿Guardar deshabilitado hasta nombre válido?
- ¿Declarar dos patrones de cabecera explícitos (tab vs detalle)?
