# CommitFit – Tabata for Developers

## 1. Product Overview

**Concept**  
CommitFit is a Tabata workout tracker for software developers.  
Each day you complete your Tabata session, you "commit" a workout and grow a contribution graph similar to GitHub’s green squares.

**Goal**  
Help developers build and maintain a simple workout habit by visualizing their consistency in a familiar, GitHub-like way.

**Platform (MVP)**  
- Android only  
- English UI only (for global devs)

---

## 2. Target Users

- Software developers using GitHub daily
- People doing (or wanting to start) short, high-intensity workouts like Tabata
- Indie hackers / tech workers who love streaks and contribution graphs

User mindset:
- Already familiar with GitHub "contribution graph" (green squares)
- Motivated by streaks and visual progress
- Prefer simple, frictionless apps

---

## 3. Core Features (MVP)

1. **Tabata Timer**
   - Default protocol: 20s work / 10s rest × 8 rounds
   - Simple controls: Start, Pause, Stop
   - Optional: sound or vibration between intervals

2. **Daily Workout Commit**
   - After finishing a full Tabata session, the app records a "commit" for today
   - One square per day (completed or not)
   - If multiple sessions are done in one day, treat it as "strong" day (darker color) or keep it simple as just completed

3. **Contribution Graph (GitHub-like)**
   - Heatmap calendar view:
     - Rows = weeks
     - Columns = days
   - Color intensity based on:
     - 0 = no workout (empty or light)
     - 1+ sessions = light → medium → dark
   - Shows at least the last 12 months

4. **Streaks & Stats (Basic)**
   - Current streak (consecutive days with workout)
   - Best streak
   - Total number of committed days

5. **Local-only Data (MVP)**
   - No login, no cloud sync
   - Data stored locally on device

---

## 4. Nice-to-have Features (Not in first MVP, but good to keep in mind)

- Multiple "programs" (e.g., Pushups Tabata, Squats Tabata, HIIT)
- Different presets (e.g., 30/15, 40/20)
- Export data as CSV
- Dark themes / color themes inspired by GitHub themes
- Simple reminders (daily notification)

---

## 5. Screen Structure (MVP)

1. **Home Screen**
   - Header: app name + simple tagline  
     > "Commit your daily Tabata, keep your body green."
   - Today status:
     - "Today’s status: ✅ Committed" or "❌ Not committed yet"
   - Button: [Start Tabata]
   - Summary: streak, total committed days

2. **Timer Screen**
   - Big countdown timer
   - Label: "Work" / "Rest"
   - Round indicator: e.g., `Round 3 of 8`
   - Progress bar or circles for rounds
   - On complete:
     - Show a simple "Workout committed" dialog
     - Update today’s status and contribution graph

3. **Contribution Graph Screen**
   - GitHub-like heatmap
   - Simple legend:  
     - No workout / Light / Medium / Heavy
   - Basic stats at bottom:
     - Current streak
     - Best streak
     - Total committed days

4. **Settings Screen (Very simple for MVP)**
   - Change timer preset? (optional, maybe later)
   - Toggle sound/vibration
   - Optional: “Reset all data” (danger zone)

---

## 6. Data Model (Local)

### Entities

**WorkoutDay**
- `date` (YYYY-MM-DD)
- `sessions` (int, number of full Tabata sessions done that day)

Optional derived value:
- `intensityLevel` (0–3) based on `sessions` count

### Storage
- Simple local storage (for MVP):
  - Option A: `shared_preferences` with JSON string
  - Option B: small local DB (e.g., `hive`) if structure grows later

---

## 7. Tech Stack

- Framework: Flutter
- Platform: Android
- Language: Dart
- Local storage: `shared_preferences` (MVP)
- State management: `setState` or simple provider (keep it minimal)
- Target SDK: same as HABIT TODAY setup
- Monetization (later):
  - Banner ad on Contribution Graph screen
  - Optional rewarded ad to unlock themes

---

## 8. Monetization (Idea)

MVP: No ads or monetization, focus on UX and retention.

Later:
- Banner ad at bottom of Contribution Graph screen
- Optional: “Pro” upgrade
  - Remove ads
  - Unlock extra stats and export
  - Extra themes

---

## 9. Non-goals (for MVP)

- No user accounts or cloud sync
- No iOS version yet
- No complex workout programs
- No social features (sharing, friends, etc.)
