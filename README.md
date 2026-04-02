# HabitAI

Aplicacion de gestion de habitos con inteligencia artificial. Describes tus metas y la IA te genera un plan de habitos personalizado.

Proyecto desarrollado como **Trabajo Final de Grado** de 2 de DAM.

## Que hace la app

- Registro e inicio de sesion con email y contraseña (Firebase Auth)
- La IA analiza tus metas y genera habitos adaptados a tu rutina
- Seguimiento diario de habitos con sistema de rachas
- Logros desbloqueables al cumplir objetivos
- Dashboard con estadisticas de progreso

## Stack

| Capa | Tecnologia |
|------|------------|
| Frontend | Flutter + Dart |
| Diseño | Material Design 3 |
| Navegacion | go_router |
| Auth | Firebase Authentication |
| Base de datos | Cloud Firestore |
| IA | Gemini (Google) via Cloud Functions |

## Estructura del proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── app.dart                  # MaterialApp + AuthProvider
├── core/
│   └── router/
│       └── app_router.dart   # Rutas y auth guard
└── features/
    ├── auth/                 # Login, registro, modelo de usuario
    ├── habits/               # CRUD de habitos, logs, rachas
    ├── achievements/         # Sistema de logros
    └── ai/                   # Conversaciones con IA, plan de habitos
```

Cada feature sigue el patron **data / domain / presentation**:
- `domain/` — Modelos de datos (sin dependencias externas)
- `data/` — Repositorios (acceso a Firebase)
- `presentation/` — Pantallas y widgets

## Requisitos

- Flutter 3.41.6+
- Dart 3.x
- Proyecto de Firebase configurado (Auth + Firestore)
- Android SDK / emulador para desarrollo

## Instalacion

```bash
# Clonar el repo
git clone https://github.com/Fepe7/habit-ai.git
cd habit-ai

# Instalar dependencias
flutter pub get

# Ejecutar en emulador/dispositivo
flutter run
```

> Necesitas tener configurado tu propio proyecto de Firebase y generar el archivo `firebase_options.dart` con FlutterFire CLI.

## Autor

**Andrei Felipe Staicu** — 2 DAM
