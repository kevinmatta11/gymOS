# UI Redesign Spec: gymOS Web Dashboard
**Date:** 2026-06-03
**Status:** approved
**Replaces:** iPhoneApp (native SwiftUI companion)

---

## Decision: Web App Companion

shadcn/ui is a React component library — it cannot run in a native SwiftUI app.
The Watch app stays native SwiftUI (required for CoreMotion).
The iPhone companion is replaced with a React web app using shadcn + Vite + Tailwind.

**Data bridge:** The Watch app exports session JSON via WatchConnectivity to a lightweight
native iOS shell app (`WKWebView` host), which writes sessions to a local JSON file the
web app reads. For MVP testing, sessions can be imported manually via a JSON upload button.

---

## Design Direction: Whoop-Inspired

### Why Whoop works
- Near-zero chrome — the data IS the UI
- Dark background makes numbers pop
- Single accent color per metric (strain = red, recovery = green, sleep = blue)
- Large primary number, small secondary label — hierarchy is instant
- Cards are containers for one idea, never cluttered
- No gradients, no shadows — flat and confident

### What we take from Whoop
- Pure black background `#0A0A0A`
- Tight typographic scale — one dominant number per card
- Color encodes meaning, not decoration
- Minimal navigation — everything visible in 2 taps
- Charts are ink, not widgets — no chart toolbars or legends cluttering the viz

### What we do differently (gymOS is strength, not cardio)
- Whoop is red/orange for strain — we use it for approaching-failure warnings
- Our primary accent is white — clean lifter aesthetic
- Volume and 1RM are the hero metrics, not HRV
- Session detail is more tabular (sets × reps × weight) than Whoop's timeline view

---

## Color System

```
Background layers:
  --bg-base:        #0A0A0A   page background
  --bg-card:        #111111   card surface
  --bg-elevated:    #1A1A1A   hover states, inputs

Borders:
  --border:         #222222   card edges
  --border-subtle:  #1A1A1A   dividers inside cards

Text:
  --text-primary:   #FFFFFF   headings, primary numbers
  --text-secondary: #A1A1AA   labels, secondary info  (zinc-400)
  --text-muted:     #52525B   timestamps, metadata    (zinc-600)

Accent:
  --accent-white:   #FFFFFF   primary interactive / highlight
  --accent-green:   #22C55E   positive trend, PR
  --accent-orange:  #F97316   approaching failure, warning
  --accent-red:     #EF4444   failure / critical

Chart colors:
  Chest:      #3B82F6   blue
  Legs:       #22C55E   green
  Back:       #F59E0B   amber
  Shoulders:  #A855F7   purple
```

---

## Typography

```
Font: Inter (via @fontsource/inter)

Scale:
  Hero number:    72px  font-weight: 700  tracking: -2px
  Section number: 40px  font-weight: 700  tracking: -1px
  Card title:     14px  font-weight: 600  tracking: +0.5px  uppercase
  Body:           14px  font-weight: 400
  Label:          12px  font-weight: 500  text-secondary
  Micro:          11px  font-weight: 400  text-muted
```

---

## App Structure

```
gymOS Web App
├── / (Dashboard)           — today's snapshot + recent sessions
├── /sessions               — session history list
├── /sessions/:id           — session detail
├── /progress               — trends: volume chart + 1RM chart
└── /settings               — weight unit, data import/export
```

Navigation: persistent left sidebar on desktop, bottom tab bar on mobile (375px breakpoint).

---

## Screen-by-Screen Plan

---

### Screen 1: Dashboard `/`

**Purpose:** At a glance — what happened in the last session and am I trending up?

**Layout (mobile):**
```
┌──────────────────────────────┐
│  gymOS              [import] │  ← header, 48px
├──────────────────────────────┤
│  LAST SESSION                │  ← card
│  Today · 54 min              │
│                              │
│  4,960        lbs volume     │  ← hero number
│  ████████░░   velocity trend │  ← 40px sparkline
├──────────────────────────────┤
│  BENCH 1RM ESTIMATE          │  ← card
│                              │
│  ~195 lbs  ±10%              │  ← number + badge
│  ↑ +7.5 lbs vs last week     │  ← trend delta, green
│  [────────────────── chart]  │  ← 80px mini sparkline
├──────────────────────────────┤
│  THIS WEEK                   │  ← card
│  Chest  ████░░  3,200 lbs   │
│  Legs   ██░░░░  1,800 lbs   │
│  Back   ███░░░  2,100 lbs   │
│  Shldrs █░░░░░    960 lbs   │
└──────────────────────────────┘
```

**shadcn components:** `Card`, `CardHeader`, `CardContent`, `Badge`, `Progress`

---

### Screen 2: Sessions `/sessions`

**Purpose:** Reverse-chronological session log.

**Layout:**
```
┌──────────────────────────────┐
│  Sessions                    │
├──────────────────────────────┤
│  Today                       │  ← date group separator
│  ┌────────────────────────┐  │
│  │ Bench · OHP            │  │  ← session row
│  │ 4,960 lbs · 4 exercises│  │
│  │ 54 min                 │  │
│  └────────────────────────┘  │
│  Yesterday                   │
│  ┌────────────────────────┐  │
│  │ Row · Pull-up           │  │
│  │ 3,840 lbs · 7 sets     │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

**shadcn components:** `Card`, `Separator`, `Badge`

---

### Screen 3: Session Detail `/sessions/:id`

**Purpose:** Full breakdown of a single session — every set, volume per exercise, velocity.

**Layout:**
```
┌──────────────────────────────┐
│  ← Sessions                  │
│  Jun 3, 2026 · 54 min        │
├──────────────────────────────┤
│  TOTAL VOLUME                │
│  4,960 lbs                   │  ← hero number
├──────────────────────────────┤
│  BENCH PRESS                 │  ← exercise section
│  Volume: 3,100 lbs  Sets: 4  │
│                              │
│  Set 1  8 × 155 lbs   2.0g  │  ← set row, velocity badge
│  Set 2  8 × 155 lbs   1.8g  │
│  Set 3  6 × 155 lbs   1.5g  │
│  Set 4  6 × 155 lbs   1.1g  ⚠│  ← orange warning if auto-saved
│                              │
│  BAR VELOCITY                │
│  ████▇▅▃▁  Approaching fail │  ← sparkline + label
├──────────────────────────────┤
│  OVERHEAD PRESS              │
│  Volume: 1,860 lbs  Sets: 3  │
│  ...                         │
└──────────────────────────────┘
```

**shadcn components:** `Card`, `Table`, `TableRow`, `Badge`, `Separator`
**Charts:** Recharts `AreaChart` for velocity sparkline

---

### Screen 4: Progress `/progress`

**Purpose:** Trends over time — the reason to use the app.

**Layout:**
```
┌──────────────────────────────┐
│  Progress                    │
│  [Volume] [1RM]              │  ← Tabs
├──────────────────────────────┤
│  WEEKLY VOLUME               │
│  by muscle group · 8 weeks   │
│                              │
│  lbs                         │
│  12k ┤                  ██   │
│  8k  ┤            ██   ████  │
│  4k  ┤      ████ ████ █████  │
│      └──────────────────────  │
│  Chest ■  Legs ■  Back ■  Shldrs ■│
├──────────────────────────────┤
│  BENCH PRESS 1RM             │
│  Epley estimate · ±10% band  │
│                              │
│  lbs                         │
│  210 ┤                  •    │
│  195 ┤           •  •  ╱─   │  ← shaded band
│  180 ┤     •  • ╱─────      │
│      └──────────────────────  │
└──────────────────────────────┘
```

**shadcn components:** `Tabs`, `TabsList`, `TabsTrigger`, `TabsContent`, `Card`
**Charts:** Recharts `BarChart` (stacked) + `AreaChart` with dual areas for band

---

### Screen 5: Settings `/settings`

**Layout:**
```
┌──────────────────────────────┐
│  Settings                    │
├──────────────────────────────┤
│  UNITS                       │
│  Weight    [lbs] [kg]        │  ← ToggleGroup
├──────────────────────────────┤
│  DATA                        │
│  [Import session JSON]       │  ← Button, file picker
│  [Export all data]           │
├──────────────────────────────┤
│  ABOUT                       │
│  Version   1.0.0             │
│  Storage   Local only        │
└──────────────────────────────┘
```

---

## Component Architecture

```
src/
├── components/
│   ├── ui/                    ← shadcn primitives (auto-generated, don't edit)
│   ├── layout/
│   │   ├── Sidebar.tsx        ← desktop nav
│   │   └── BottomNav.tsx      ← mobile nav
│   ├── dashboard/
│   │   ├── LastSessionCard.tsx
│   │   ├── OneRMCard.tsx
│   │   └── WeeklyVolumeCard.tsx
│   ├── sessions/
│   │   ├── SessionList.tsx
│   │   ├── SessionRow.tsx
│   │   └── SessionDetail.tsx
│   ├── progress/
│   │   ├── VolumeChart.tsx
│   │   └── OneRMChart.tsx
│   └── shared/
│       ├── HeroNumber.tsx     ← large number + label
│       ├── VelocitySparkline.tsx
│       └── MetricBadge.tsx    ← colored badge for PRs, warnings
├── lib/
│   ├── data.ts                ← parse session JSON, compute metrics
│   ├── calculations.ts        ← Epley, volume, velocity normalization
│   └── store.ts               ← Zustand store, localStorage persistence
├── types/
│   └── workout.ts             ← WorkoutSession, WorkoutSet, Exercise types
└── app/
    ├── routes.tsx
    └── main.tsx
```

---

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | React 18 + Vite | Fast dev, no SSR needed |
| UI components | shadcn/ui | Unstyled primitives, full control |
| Styling | Tailwind CSS v4 | Co-located, no CSS files |
| Charts | Recharts | Works with shadcn chart primitives |
| State | Zustand | Simple, no boilerplate |
| Data | localStorage + JSON import | No backend, matches privacy promise |
| Routing | React Router v6 | Simple SPA routing |
| Types | TypeScript strict | Match Swift model contracts exactly |

---

## Data Flow (No Backend)

```
Apple Watch
    ↓ CoreMotion + SwiftData
Watch App (Swift)
    ↓ WatchConnectivity
iOS Shell / WKWebView host (future)
    ↓ window.postMessage or file write
Web App (React)
    ↓ localStorage / JSON

For MVP testing (no iOS shell yet):
  → Manual JSON import via file picker in Settings
  → SeedData.json generated from Swift seed data
```

---

## What Changes vs Current iPhone App

| Current (SwiftUI) | New (React + shadcn) |
|-------------------|----------------------|
| Native iOS only | Works in any browser + iOS Safari |
| System UI components | Whoop-style dark design system |
| Charts via Swift Charts | Recharts with custom dark theme |
| SwiftData persistence | localStorage + JSON import |
| WatchConnectivity direct | Manual import for now; native bridge later |

---

## What Does NOT Change

- Watch App — stays SwiftUI, CoreMotion, unchanged
- Data contracts — `WorkoutSession`, `WorkoutSet` types mirror Swift models exactly
- Calculations — Epley formula, velocity normalization, failure threshold identical
- Privacy — local only, no network

---

## Build Order

1. `npm create vite@latest` + shadcn init + Tailwind config
2. Types + data layer (`workout.ts`, `calculations.ts`, `store.ts`)
3. Layout shell (Sidebar + BottomNav + routing)
4. Dashboard screen (3 cards)
5. Sessions list + detail
6. Progress charts
7. Settings + JSON import/export
8. Polish: transitions, empty states, mobile responsive

---

## Acceptance Criteria

- [ ] All screens render in dark mode only (no light mode toggle)
- [ ] Mobile (375px) and desktop (1280px) layouts both work
- [ ] Import a session JSON file → all screens update correctly
- [ ] Epley 1RM chart renders ±10% band, never a single value
- [ ] Velocity sparkline shows approaching-failure warning in orange
- [ ] Weekly volume stacked bar chart renders for 8 weeks of data
- [ ] PR (personal record) best set is highlighted in green
- [ ] Auto-saved sets show orange warning indicator
- [ ] No data leaves the browser (verified: no network requests)
- [ ] Empty states render for all screens (no data yet)
