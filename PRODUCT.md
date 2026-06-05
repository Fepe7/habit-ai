# PRODUCT.md — HabitAI

## Product Purpose
Mobile app for habit tracking with AI. Helps users build consistent habits, track mood, and understand patterns between emotional states and habit completion.

## Register
product

## Users
Primary: 18–35 year-olds who want to build better habits and develop self-awareness. Secondary: people interested in mood/emotion tracking and personal growth. They use the app daily, briefly (under 2 minutes per session), on mobile (Android first).

## Brand tone
Warm, encouraging, personal. Not clinical or corporate. Not gamified-aggressive. Feels like a thoughtful friend, not a productivity drill sergeant.

## Color palette
Real values shipped by the app theme (`lib/core/theme/app_theme.dart`). The full visual system, including tonal ladder, typography, and components, lives in DESIGN.md.
- Primary (Deep Harbor Teal): #00668A
- Primary container (Sky): #38BDF8
- Secondary (Signal Blue): #006591 / container #39B8FD
- Tertiary / Streak / Achievements (Amber): #F59E0B (deep #855300)
- Success gradient (emerald): #059669 → #34D399
- Error: #BA1A1A / container #FFDAD6
- Surface field: #F8F9FF
- Background / cards (surface-container-lowest): #FFFFFF
- Surface ladder (low → highest): #EFF4FF · #E5EEFF · #DCE9FF · #D3E4FE
- Dark surface: #0F1620
- Text primary (Ink): #0B1C30
- Text secondary (Slate): #3E484F

## Anti-references
- Don't feel like a corporate productivity tool (no Jira vibes)
- Don't feel clinical or cold (no Apple Health sterility)
- Don't feel gamified in an aggressive way (no Duolingo pressure-tactics)
- Don't feel like a diary app (no journal metaphors)

## Tech stack
Flutter 3.x, Material Design 3, flutter_animate, Firebase

## Strategic principles
1. Minimum friction — logging a habit or mood should take under 5 seconds
2. Delight in small moments — micro-interactions matter
3. Insight over data — show patterns, not just numbers
4. Privacy-first — user controls visibility of everything
