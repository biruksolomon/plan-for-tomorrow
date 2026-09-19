# Plan for Tomorrow

A small app I built for myself to fix one specific habit: I'd wake up and
decide what the day was for *while already in the middle of it*. This app
forces that decision to happen the night before, and then gets out of the way.

There's no account, no backend, nothing leaves the phone. It's a personal
tool, not a product — I'm sharing the source because the pattern (and the
architecture decision at its core) might be useful to someone else building
something similar.

## How it works

The whole app is one rule, enforced in the data layer, not just the UI:

- **Tonight, I write tomorrow's list.** Up to 10 tasks. I can edit it as much
  as I want until midnight.
- **At midnight, it locks.** The list I wrote is now today's list. I can't add
  to it, edit it, or delete from it — only tick items off.
- **Once the day ends, it's history.** Read-only, forever, feeding into the
  analytics.

No mid-day negotiating with myself about what "counts." The decision was made
when I had a clear head the night before, and today is just execution.

## Features

- **Plan Tomorrow** — write up to 10 tasks for the next day, edit freely until
  it locks
- **Today** — a tick-only list, locked from editing, with a live "X / 10 done"
  counter
- **History** — a monthly calendar heatmap; each day shades by how much of it
  got done, tap any day to see exactly what was on it
- **Analytics** — current streak, best streak, a 30-day completion trend
  chart, and a breakdown of completion rate by day of the week (so I can see,
  for example, that Fridays are where I consistently fall off)
- **CSV export** — one tap copies everything to the clipboard, since there's
  no cloud backup by design
- Fully offline. Opens instantly, works with no signal, nothing to configure

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter | Single codebase, and I wanted it on my phone, not just as a web page |
| Local database | `sqflite` (SQLite) | One table, no relations to speak of — SQL was already the right tool, no need for a heavier ODM |
| State management | `provider` | The whole app is basically one `ChangeNotifier`; anything more layered would be solving a problem I don't have |
| Charts | `fl_chart` | The 30-day trend line and weekday bars on the Analytics screen |
| Fonts | `google_fonts` (Anton + Inter) | Anton for the bold condensed headlines, Inter for everything else |
| Dates | `intl` | Formatting and parsing the `yyyy-MM-dd` day keys everything is built around |

No backend. No auth. No network permission requested. That's a deliberate
choice, not a missing feature — see [Data & privacy](#data--privacy) below.

## The architecture decision this app is built around

A day in this app can be in one of three phases — *planning* (future),
*active* (today), or *archived* (past) — and what phase it's in determines
whether you can edit it, tick it, or only read it.

The easy way to build that is a `status` column you update with a background
job at midnight. I didn't do that, because that job can fail to run — the
phone sleeps through midnight, the app isn't open, the timezone changes — and
then a day is stuck in the wrong phase until something notices.

Instead, the phase is **derived from the device's current date, every time
it's needed**, and it's enforced at the repository level:

```dart
DayPhase get phase {
  final diff = DayKey.daysBetween(DayKey.today(), dayKey);
  if (diff > 0) return DayPhase.planning;
  if (diff == 0) return DayPhase.active;
  return DayPhase.archived;
}
```

`savePlan()` throws if you try to plan anything but a future day. `toggleTask()`
throws if you try to tick anything but today. There's nothing to reconcile,
nothing to migrate, nothing that can drift — the invariant holds by
construction, on every read, with no maintenance.

## Folder structure

```
plan_tomorrow/
├── pubspec.yaml
├── README.md
│
├── lib/
│   ├── main.dart                    # Entry point
│   │
│   ├── core/                        # No dependency on data/ or screens/
│   │   ├── day_key.dart             # "yyyy-MM-dd" date helpers
│   │   └── theme.dart               # Colors + type styles
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── task.dart            # A single task
│   │   │   ├── day_plan.dart        # A day's tasks + derived DayPhase
│   │   │   └── stats.dart           # Streaks, rates, weekday breakdown
│   │   ├── db/
│   │   │   └── app_database.dart    # sqflite schema + migrations
│   │   └── repositories/
│   │       └── task_repository.dart # All SQL, all analytics, phase-guarded writes
│   │
│   ├── state/
│   │   └── app_state.dart           # ChangeNotifier the screens watch
│   │
│   ├── widgets/
│   │   └── common.dart              # Shared building blocks (masthead, tick row, buttons)
│   │
│   └── screens/
│       ├── home_shell.dart          # Bottom nav between the 4 tabs
│       ├── today_screen.dart
│       ├── plan_tomorrow_screen.dart
│       ├── history_screen.dart
│       ├── day_detail_screen.dart
│       ├── analytics_screen.dart
│       └── settings_screen.dart
│
├── test/
│   └── analytics_test.dart          # Streak edge cases against real in-memory SQLite
│
├── android/ ios/ linux/ macos/ windows/ web/   # Flutter platform scaffolding
```

The dependency direction only ever goes one way — `screens/` depends on
`state/`, `state/` depends on `data/`, and `data/` depends on nothing above
it. `task_repository.dart` never imports Flutter at all, which is what makes
it possible to test the streak logic against a real SQLite database with no
mocking.

## Data & privacy

Everything lives in a single SQLite file on the device. There is no account,
no analytics collection, no network request the app makes on its own. If I
uninstall it, the history goes with it — which is why the CSV export exists:
it's the manual backup path for a deliberately backend-less app.

## Getting started

```bash
git clone https://github.com/<your-username>/plan-for-tomorrow.git
cd plan-for-tomorrow
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

## Roadmap

Things I know are missing, in the order I'd tackle them:

- [ ] Evening reminder notification ("tomorrow isn't planned yet")
- [ ] Bundle fonts locally instead of fetching via `google_fonts` on first run
- [ ] Dark theme
- [ ] Optional cloud backup (still no account — probably just an encrypted
      file export to a location I pick, not a sync service)

## License

Personal project, shared as-is. Feel free to fork it for your own use.
