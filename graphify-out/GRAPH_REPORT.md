# Graph Report - .  (2026-06-04)

## Corpus Check
- 162 files · ~166,090 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2238 nodes · 2849 edges · 57 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 35 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 85 edges
2. `../../../l10n/app_localizations.dart` - 62 edges
3. `package:cloud_firestore/cloud_firestore.dart` - 54 edges
4. `../../../core/theme/app_theme.dart` - 42 edges
5. `package:flutter_animate/flutter_animate.dart` - 40 edges
6. `package:firebase_auth/firebase_auth.dart` - 35 edges
7. `package:go_router/go_router.dart` - 24 edges
8. `HabitAI` - 24 edges
9. `package:flutter_test/flutter_test.dart` - 22 edges
10. `../../../core/widgets/ux/app_snackbar.dart` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Haptic Feedback (item 44)` --semantically_similar_to--> `core/services/feedback_service.dart`  [INFERRED] [semantically similar]
  ROADMAP.md → CLAUDE.md
- `generateWeeklyReview (callable)` --semantically_similar_to--> `Cloud Function onCall auth`  [INFERRED] [semantically similar]
  paso-21-revision-semanal.md → explicacion_auth.md
- `flutter_animate` --semantically_similar_to--> `Convenciones de animación`  [INFERRED] [semantically similar]
  README.md → implementar_planes_mios/ux-migration.md
- `Detección de patrones con IA` --semantically_similar_to--> `Correlación ánimo-hábitos`  [INFERRED] [semantically similar]
  ROADMAP.md → README.md
- `Escudos de racha / modo enfermedad` --shares_data_with--> `Cloud Firestore`  [INFERRED]
  ROADMAP.md → CLAUDE.md

## Hyperedges (group relationships)
- **Pipeline IA: Flutter → Cloud Function → Gemini** — tech_flutter, tech_cloud_functions, tech_gemini, rationale_ai_proxy [EXTRACTED 0.90]
- **Jobs IA programados (Scheduler + Function + Gemini)** — tech_cloud_scheduler, tech_cloud_functions, tech_gemini, concept_weekly_review, concept_butterfly [EXTRACTED 0.85]
- **Modelo de visibilidad social** — concept_social_graph, concept_follow_repository, concept_habit_visibility, concept_public_profiles [EXTRACTED 0.85]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.01
Nodes (152): ../../../auth/data/avatar_storage_repository.dart, ../../../../core/services/feedback_service.dart, ../../../core/widgets/ux/app_snackbar.dart, dart:io, dart:math, ../../data/mood_repository.dart, ../../domain/mood_entry_model.dart, build (+144 more)

### Community 1 - "Community 1"
Cohesion: 0.02
Nodes (132): ../../achievements/presentation/achievement_l10n.dart, ../../challenges/domain/challenge_model.dart, ../../challenges/presentation/widgets/create_challenge_sheet.dart, ../../community/data/community_template_repository.dart, ../../community/domain/community_template_model.dart, ../../../core/widgets/avatar_circle.dart, dart:async, ../../data/public_profile_repository.dart (+124 more)

### Community 2 - "Community 2"
Cohesion: 0.02
Nodes (129): ../../ai/data/ai_repository.dart, ../../ai/domain/renegotiation_model.dart, ../../challenges/data/challenge_repository.dart, ../domain/habit_log_model.dart, ../../domain/habit_model.dart, addToStack, deleteTodayLog, HabitRepository (+121 more)

### Community 3 - "Community 3"
Cohesion: 0.02
Nodes (89): AchievementCatalog, AchievementInfo, AchievementModel, getInfo, ButterflyKeyMoment, ButterflyProjectionModel, ButterflyStats, Color (+81 more)

### Community 4 - "Community 4"
Cohesion: 0.02
Nodes (112): ../../../../core/widgets/app_bottom_sheet.dart, ../../../../core/widgets/gradient_button.dart, ../../data/habit_group_repository.dart, ../../data/habit_repository.dart, ../../domain/habit_group_model.dart, ../../../features/achievements/data/achievement_checker.dart, ../../../features/achievements/presentation/achievement_overlay.dart, ../../../features/community/data/community_template_repository.dart (+104 more)

### Community 5 - "Community 5"
Cohesion: 0.02
Nodes (107): ../../../app.dart, ../../../core/l10n/locale_provider.dart, core/router/app_router.dart, ../../../core/services/connectivity_service.dart, core/services/update_service.dart, ../../../core/theme/theme_provider.dart, ../../../core/widgets/ux/error_state_view.dart, core/widgets/ux/update_dialog.dart (+99 more)

### Community 6 - "Community 6"
Cohesion: 0.02
Nodes (108): ../../achievements/data/achievement_checker.dart, ../../achievements/presentation/achievement_overlay.dart, archivement_repository.dart, ../../auth/data/user_repository.dart, ../../auth/domain/user_model.dart, ../domain/template_habit_snapshot.dart, ../../habits/data/habit_group_repository.dart, ../../../habits/data/habit_repository.dart (+100 more)

### Community 7 - "Community 7"
Cohesion: 0.02
Nodes (95): achievement_l10n.dart, ../../../core/theme/app_theme.dart, ../../../core/widgets/ux/skeletons.dart, ../data/archivement_repository.dart, ../data/stats_repository.dart, ../domain/achivement_model.dart, ../../domain/chat_message.dart, ../../../l10n/app_localizations.dart (+87 more)

### Community 8 - "Community 8"
Cohesion: 0.02
Nodes (98): ../../achievements/data/archivement_repository.dart, ../../achievements/domain/achivement_model.dart, ../../ai/domain/butterfly_projection_model.dart, ../../ai/domain/pattern_insight_model.dart, ../../ai/domain/weekly_review_model.dart, ../category_l10n.dart, ../../../core/router/main_shell.dart, ../../../core/widgets/ux/empty_state_view.dart (+90 more)

### Community 9 - "Community 9"
Cohesion: 0.02
Nodes (85): app_snackbar.dart, FeedbackService, AppTheme, _buildTheme, categoryBg, categoryFg, categoryIcon, categoryLabel (+77 more)

### Community 10 - "Community 10"
Cohesion: 0.02
Nodes (93): app_localizations_en.dart, app_localizations_es.dart, achievementsUnlocked, aiHabitsAdded, allHabitsBulkDeleted, allHabitsBulkDeleteGroupsTitle, allHabitsBulkDeleteTitle, allHabitsGroupsDeleted (+85 more)

### Community 11 - "Community 11"
Cohesion: 0.03
Nodes (94): achievements Firestore Collection, ai_conversations Firestore Collection, AI Integration Flow (Flutter→CloudFunction→Gemini), AIScreen, core/router/app_router.dart, core/theme/app_theme.dart, butterfly_projections Firestore Collection, Cloud Functions (europe-west1) (+86 more)

### Community 12 - "Community 12"
Cohesion: 0.02
Nodes (83): achievementsUnlocked, aiHabitsAdded, allHabitsBulkDeleted, allHabitsBulkDeleteGroupsTitle, allHabitsBulkDeleteTitle, allHabitsGroupsDeleted, allHabitsHardDeleteContent, allHabitsHardDeleted (+75 more)

### Community 13 - "Community 13"
Cohesion: 0.02
Nodes (83): app_localizations.dart, achievementsUnlocked, aiHabitsAdded, allHabitsBulkDeleted, allHabitsBulkDeleteGroupsTitle, allHabitsBulkDeleteTitle, allHabitsGroupsDeleted, allHabitsHardDeleteContent (+75 more)

### Community 14 - "Community 14"
Cohesion: 0.03
Nodes (60): ../../../core/services/analytics_service.dart, ../../../core/widgets/app_drawer.dart, ../../../core/widgets/spark_check_logo.dart, ../data/community_template_repository.dart, ../../domain/community_template_model.dart, build, dispose, GestureDetector (+52 more)

### Community 15 - "Community 15"
Cohesion: 0.03
Nodes (62): ../../features/achievements/presentation/achievements_screen.dart, ../../features/ai/presentation/ai_screen.dart, ../../features/ai/presentation/butterfly_projection_screen.dart, ../../features/ai/presentation/pattern_insights_screen.dart, ../../features/ai/presentation/weekly_review_screen.dart, ../../features/auth/presentation/login_screen.dart, ../../features/auth/presentation/register_screen.dart, ../../features/challenges/presentation/challenge_detail_screen.dart (+54 more)

### Community 16 - "Community 16"
Cohesion: 0.03
Nodes (58): ../../../features/achievements/data/archivement_repository.dart, ../../../features/achievements/domain/achivement_model.dart, ../../features/ai/data/ai_repository.dart, ../../../features/ai/domain/butterfly_projection_model.dart, ../../../features/ai/domain/renegotiation_model.dart, ../../../features/ai/domain/weekly_review_model.dart, ../../features/auth/data/user_repository.dart, ../../features/auth/domain/user_model.dart (+50 more)

### Community 17 - "Community 17"
Cohesion: 0.04
Nodes (55): ../../../core/widgets/ux/gradient_fab.dart, ../../data/challenge_repository.dart, ../../domain/challenge_model.dart, ../../domain/challenge_participant_model.dart, ../domain/challenge_progress_model.dart, ChallengeRepository, Exception, updateMyProgress (+47 more)

### Community 18 - "Community 18"
Cohesion: 0.04
Nodes (51): ../../../dashboard/data/stats_repository.dart, ../../domain/mood_math.dart, build, _CategoryChip, Center, _ConfidenceBadge, Container, _CorrelationTile (+43 more)

### Community 19 - "Community 19"
Cohesion: 0.04
Nodes (44): dart:ui, ../features/habits/domain/habit_model.dart, build, _deviceCode, dispose, ListenableBuilder, _LocaleInherited, LocaleProvider (+36 more)

### Community 20 - "Community 20"
Cohesion: 0.05
Nodes (40): Sistema de logros, Flujo IA proxy seguro, Simulador del Efecto Mariposa, Chat con Gemini 2.5 Pro, Check-in diario con rachas, Firebase Cloud Functions (europe-west1), Cloud Scheduler + Pub/Sub, Plantillas de la comunidad (+32 more)

### Community 21 - "Community 21"
Cohesion: 0.05
Nodes (35): ../data/follow_repository.dart, ../data/user_directory_repository.dart, ../domain/follow_model.dart, ../domain/follow_request_model.dart, ../domain/privacy_level.dart, ../domain/user_directory_entry.dart, _followersRef, _followingRef (+27 more)

### Community 22 - "Community 22"
Cohesion: 0.05
Nodes (36): ../../../core/services/review_service.dart, AlertDialog, build, _buildInitialsAvatar, _buildSettingsAvatar, Column, _ConfirmDeleteDialog, _ConfirmDeleteDialogState (+28 more)

### Community 23 - "Community 23"
Cohesion: 0.09
Nodes (30): AI Integration, Anti-pattern: Aggressive Gamification (no Duolingo pressure), Anti-pattern: Clinical/Cold (no Apple Health sterility), Anti-pattern: Corporate Productivity (no Jira vibes), Anti-pattern: Diary App (no journal metaphors), Anti-References (Design Exclusions), Brand Tone (Warm, Encouraging), Error Color #EF4444 (+22 more)

### Community 24 - "Community 24"
Cohesion: 0.1
Nodes (21): Cloud Function onCall auth, Firebase Authentication, Firestore Security Rules, ID Token JWT (RSA256), JWT Auth Flow, AIRepository weekly review methods, Cloud Scheduler Architecture, Cron 0 8 * * 1 (+13 more)

### Community 25 - "Community 25"
Cohesion: 0.25
Nodes (16): buildMonthlyContext(), buildPatternContext(), buildRenegotiationContext(), buildWeeklyContext(), extractJson(), getCurrentMonthRange(), getCurrentWeekRange(), getIsoWeekId() (+8 more)

### Community 26 - "Community 26"
Cohesion: 0.19
Nodes (14): IA como coach (Gemini), Simulador del Efecto Mariposa, Correlación ánimo-hábitos, mood_math.dart (lógica pura), Tracking de energía/ánimo, Onboarding con IA, Detección de patrones con IA, Renegociación inteligente (+6 more)

### Community 27 - "Community 27"
Cohesion: 0.15
Nodes (12): AspectRatio, _Bone, build, ChartSkeleton, Container, GridTileSkeleton, HabitCardSkeleton, Padding (+4 more)

### Community 28 - "Community 28"
Cohesion: 0.15
Nodes (13): Sistema de logros con niveles, Plantillas de la comunidad, FollowRepository, Habit Stacking (Atomic Habits), Visibilidad granular de hábitos, Perfiles públicos, Retos compartidos (21 días), Red social tipo Instagram (+5 more)

### Community 29 - "Community 29"
Cohesion: 0.3
Nodes (10): baseRating(), blockRating(), blocksForDay(), blockTimestamp(), daysAgo(), generateEntries(), labelsFor(), maybeNote() (+2 more)

### Community 30 - "Community 30"
Cohesion: 0.2
Nodes (11): preparacion-proyecto.md RA mapping, Gap: Firebase technical document annex missing, Gap: Missing EFICIENCIA/SOSTENIBILIDAD code comments, RA Servicios y Procesos / Async (StreamBuilder, Cloud Functions, Pub/Sub), RA Acceso a Datos / Persistencia (Firestore CRUD, fromJson/toJson), RA Entornos de Desarrollo (Git, analysis_options, hooks), RA Desarrollo Móvil (Flutter, Material 3, 4 tabs), RA Computación Nube (Firebase BaaS, Cloud Functions, Scheduler, secrets) (+3 more)

### Community 31 - "Community 31"
Cohesion: 0.52
Nodes (5): adminTimestamp(), buildLogs(), dartWeekday(), daysAgo(), seedData()

### Community 32 - "Community 32"
Cohesion: 0.5
Nodes (3): ChatMessage, HabitPlanData, HabitSuggestion

### Community 33 - "Community 33"
Cohesion: 0.83
Nodes (3): run(), upsertAuthUser(), writeFirestoreDocs()

### Community 34 - "Community 34"
Cohesion: 1.0
Nodes (4): App Icon (SparkCheck Logo), HabitAI Brand Identity, SparkCheck Logo Design Concept, Splash Screen Icon (SparkCheck Logo)

### Community 35 - "Community 35"
Cohesion: 0.5
Nodes (4): Arquitectura feature-first (3 capas), HabitAI README, Flutter 3.41.6 / Dart, go_router (auth guard + ShellRoute)

### Community 36 - "Community 36"
Cohesion: 0.67
Nodes (2): moodConfidenceLevel, moodDiffLabel

### Community 37 - "Community 37"
Cohesion: 0.67
Nodes (2): CategoryLevel, LevelsProfile

### Community 38 - "Community 38"
Cohesion: 0.67
Nodes (2): AnalyticsService, package:firebase_analytics/firebase_analytics.dart

### Community 39 - "Community 39"
Cohesion: 0.67
Nodes (3): Badge en BottomNav para solicitudes pendientes, Rationale: _knownPendingCount not wired to UI, Social Gaps — Pending Implementation Doc

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (1): PublicHabitModel

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (1): TemplateHabitSnapshot

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (1): fromString

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (2): CLAUDE.md Instrucciones de Proyecto, HabitAI Roadmap y Backlog

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (2): FeedbackService (háptico), Preparación lanzamiento público (Fase G)

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (0): 

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (0): 

### Community 47 - "Community 47"
Cohesion: 1.0
Nodes (1): Feature 22 — Renegociación Inteligente

### Community 48 - "Community 48"
Cohesion: 1.0
Nodes (1): Firestore: users/{uid}/renegotiations/{habitId}

### Community 49 - "Community 49"
Cohesion: 1.0
Nodes (1): Rationale: scheduler + callable (re-engagement proactivo)

### Community 50 - "Community 50"
Cohesion: 1.0
Nodes (1): Rationale: modelo dedicado RenegotiationModel (SRP)

### Community 51 - "Community 51"
Cohesion: 1.0
Nodes (1): Rationale: reglas restrictivas affectedKeys (integridad IA)

### Community 52 - "Community 52"
Cohesion: 1.0
Nodes (1): Paleta de colores HabitAI

### Community 53 - "Community 53"
Cohesion: 1.0
Nodes (1): fl_chart Charts

### Community 54 - "Community 54"
Cohesion: 1.0
Nodes (1): Firebase Storage + image_picker

### Community 55 - "Community 55"
Cohesion: 1.0
Nodes (1): Habit Visibility Rules

### Community 56 - "Community 56"
Cohesion: 1.0
Nodes (1): Rationale: watchPublicHabits missing visibility filter

## Knowledge Gaps
- **1802 isolated node(s):** `AuthProvider`, `HabitAIApp`, `_HabitAIAppState`, `of`, `updateShouldNotify` (+1797 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 40`** (2 nodes): `public_habit_model.dart`, `PublicHabitModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (2 nodes): `template_habit_snapshot.dart`, `TemplateHabitSnapshot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (2 nodes): `privacy_level.dart`, `fromString`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `CLAUDE.md Instrucciones de Proyecto`, `HabitAI Roadmap y Backlog`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `FeedbackService (háptico)`, `Preparación lanzamiento público (Fase G)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (1 nodes): `es.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (1 nodes): `en.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `Feature 22 — Renegociación Inteligente`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (1 nodes): `Firestore: users/{uid}/renegotiations/{habitId}`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `Rationale: scheduler + callable (re-engagement proactivo)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `Rationale: modelo dedicado RenegotiationModel (SRP)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (1 nodes): `Rationale: reglas restrictivas affectedKeys (integridad IA)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (1 nodes): `Paleta de colores HabitAI`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (1 nodes): `fl_chart Charts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 54`** (1 nodes): `Firebase Storage + image_picker`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 55`** (1 nodes): `Habit Visibility Rules`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 56`** (1 nodes): `Rationale: watchPublicHabits missing visibility filter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 9` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 21`, `Community 22`, `Community 27`?**
  _High betweenness centrality (0.239) - this node is a cross-community bridge._
- **Why does `dart:async` connect `Community 1` to `Community 2`, `Community 5`, `Community 10`, `Community 14`, `Community 15`, `Community 17`, `Community 21`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **Why does `package:intl/intl.dart` connect `Community 12` to `Community 10`, `Community 13`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **What connects `AuthProvider`, `HabitAIApp`, `_HabitAIAppState` to the rest of the system?**
  _1802 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.01 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._