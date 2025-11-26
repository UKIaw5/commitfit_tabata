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

3. **Core Features (MVP)**

1. **Configurable Tabata Timer**
   - Default protocol: 20s work / 10s rest × 8 rounds
   - User-configurable parameters:
     - Work duration (seconds)
     - Rest duration (seconds)
     - Number of rounds
   - Simple UI to edit these values (sliders or number pickers)
   - Settings are persisted locally and used every time the user starts a session from Home

2. **Daily Workout Commit**
   - After finishing a full Tabata session (based on current settings), the app records a “commit” for today
   - Multiple sessions per day are counted and affect intensity on the contribution graph

3. **Contribution Graph (GitHub-like)**
   - Heatmap calendar view:
     - Rows = weeks
     - Columns = days
   - Color intensity based on number of sessions per day:
     - Example (default):
       - 0 sessions → level 0 (empty)
       - 1 session  → level 1 (light)
       - 2–3 sessions → level 2 (medium)
       - 4+ sessions → level 3 (dark)
   - Intensity thresholds are configurable (see Graph customization)

4. **Streaks & Basic Stats**
   - Current streak (consecutive days with ≥1 session)
   - Best streak
   - Total number of committed days

5. **Local-only Data**
   - No login, no cloud sync
   - All workout history and settings stored locally on device

6. **Graph Customization (MVP-level, but simple)**

   - User can adjust:
     - How many weeks/months are displayed (e.g., last 12 weeks vs last 12 months)
     - Intensity thresholds for contribution levels:
       - Example configurable fields:
         - Level 1 threshold (min sessions per day)
         - Level 2 threshold
         - Level 3 threshold
     - (Optional later) color theme (light/dark/green variants)

   - A simple "Graph Settings" screen or section:
     - Sliders or number fields:
       - “Level 1: from X sessions”
       - “Level 2: from Y sessions”
       - “Level 3: from Z sessions”

---

## 4. Nice-to-have Features (Not in first MVP, but good to keep in mind)

- Multiple "programs" (e.g., Pushups Tabata, Squats Tabata, HIIT)
- Different presets (e.g., 30/15, 40/20)
- Export data as CSV
- Dark themes / color themes inspired by GitHub themes
- Simple reminders (daily notification)

---

5. **Screen Structure (MVP)**

1. **Home Screen**
   - Instant start and current preset display

2. **Timer Screen**
   - Shows current interval:
     - “Work” / “Rest”
     - Remaining seconds
     - Current round: e.g., “Round 3 of 8”
   - On completion of all rounds:
     - Records a session for today
     - Shows a confirmation message:
       - “Session committed! Your graph has been updated.”

3. **Contribution Graph Screen**
   - GitHub-like heatmap
   - Legend explaining levels (0–3)
   - Button/link:
     - [Graph & Timer settings] or [Customize settings]

4. **Settings Screen**
   - Sections:

     **Timer Settings**
     - Work duration (seconds)
     - Rest duration (seconds)
     - Number of rounds
     - [Save] button

     **Graph Settings**
     - Time range (e.g., “Show last 12 weeks” vs “Show last 12 months”)
     - Intensity thresholds:
       - Level 1: from X sessions/day
       - Level 2: from Y sessions/day
       - Level 3: from Z sessions/day
     - [Save] button

---

## 6. Data Model (Local)

### Entities

**WorkoutDay**
- `date` (string, YYYY-MM-DD)
- `sessions` (int, number of full Tabata sessions completed that day)

**TimerConfig**
- `workSeconds` (int, e.g., 20)
- `restSeconds` (int, e.g., 10)
- `rounds` (int, e.g., 8)

**GraphConfig**
- `rangeType` (string, e.g., "12_weeks" or "12_months")
- `level1Threshold` (int, min sessions for level 1)
- `level2Threshold` (int, min sessions for level 2)
- `level3Threshold` (int, min sessions for level 3)

### Storage

- All of the above are stored locally using `shared_preferences`:
  - `workout_days` → JSON array of WorkoutDay
  - `timer_config` → JSON object
  - `graph_config` → JSON object

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
