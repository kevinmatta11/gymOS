# UI Redesign Spec: gymOS iOS App — Whoop-Inspired
**Date:** 2026-06-03
**Status:** approved
**Scope:** iPhone companion app only (SwiftUI). Watch app UI unchanged.

---

## What We're Fixing

The current UI uses default SwiftUI List + Form styling — system grey backgrounds,
blue tint, no visual hierarchy. It looks like a settings screen, not a performance app.

Whoop works because:
- The data IS the design — numbers are enormous, labels are tiny
- Color encodes meaning (green = good, orange = warning), never decoration
- Pure black background makes every metric feel premium
- One idea per card — never cluttered
- Charts are ink, not chrome — no axis labels unless necessary

---

## Design System

### Colors

```swift
// Background
Color("BgBase")      // #0A0A0A  — page, ZStack base
Color("BgCard")      // #111111  — card surface
Color("BgElevated")  // #1C1C1E  — inputs, pickers (matches iOS dark)

// Borders
Color("Border")      // #2C2C2E  — card edges

// Text
Color("TextPrimary")   // #FFFFFF
Color("TextSecondary") // #A1A1AA  (zinc-400)
Color("TextMuted")     // #52525B  (zinc-600)

// Semantic
Color("AccentGreen")   // #22C55E  — PR, positive trend
Color("AccentOrange")  // #F97316  — approaching failure, auto-save warning
Color("AccentRed")     // #EF4444  — critical

// Muscle group chart colors
Color("ChartChest")     // #3B82F6  blue
Color("ChartLegs")      // #22C55E  green
Color("ChartBack")      // #F59E0B  amber
Color("ChartShoulders") // #A855F7  purple
```

### Typography

```swift
// Hero — the dominant number on each screen
.font(.system(size: 64, weight: .bold, design: .rounded))
.tracking(-2)

// Section number — cards with single metrics
.font(.system(size: 40, weight: .bold, design: .rounded))
.tracking(-1)

// Card label — always uppercase, small, secondary color
.font(.system(size: 11, weight: .semibold))
.tracking(1.5)
.textCase(.uppercase)
.foregroundStyle(Color("TextSecondary"))

// Body — set rows, descriptions
.font(.system(size: 14, weight: .regular))

// Mono — weights, reps (align columns)
.font(.system(size: 14, weight: .medium, design: .monospaced))
```

### Card Style
Every card:
- Background: `Color("BgCard")`
- Corner radius: `16`
- Border: `Color("Border")`, 0.5pt
- Padding: `20` horizontal, `16` vertical
- No shadows

```swift
// Shared modifier
struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color("BgCard"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("Border"), lineWidth: 0.5)
            )
    }
}
```

---

## Screen-by-Screen Redesign

---

### Screen 1: Sessions Tab (SessionListView)

**Current:** Plain SwiftUI List with default separators.

**New:**
```
╔══════════════════════════════╗
║  GYMOS              [+]      ║  ← nav, black bg
╠══════════════════════════════╣
║  TODAY                       ║  ← date section header, muted uppercase
║                              ║
║ ┌──────────────────────────┐ ║
║ │ Bench · OHP              │ ║  ← exercise names, primary text
║ │ 4,960 lbs                │ ║  ← volume, large
║ │ 4 sets · 54 min    →     │ ║  ← metadata, secondary
║ └──────────────────────────┘ ║
║                              ║
║  YESTERDAY                   ║
║ ┌──────────────────────────┐ ║
║ │ Row · Pull-up             │ ║
║ │ 3,840 lbs                │ ║
║ │ 7 sets · 48 min    →     │ ║
║ └──────────────────────────┘ ║
╚══════════════════════════════╝
```

**Changes:**
- `.listStyle(.plain)` → custom `LazyVStack` on black background
- Session row: volume as the dominant number (28pt bold rounded)
- Exercise names as subtitle (14pt secondary)
- No list separators — card spacing provides rhythm
- Date group headers: 11pt uppercase muted text

---

### Screen 2: Session Detail (SessionDetailView)

**Current:** Plain List with Section headers, basic HStack rows.

**New:**
```
╔══════════════════════════════╗
║  ← Sessions  Jun 3          ║
╠══════════════════════════════╣
║                              ║
║  TOTAL VOLUME                ║  ← card label (11pt uppercase)
║  4,960 lbs                   ║  ← 64pt hero number
║                              ║
╠══════════════════════════════╣
║  BENCH PRESS                 ║  ← exercise card header
║  3,100 lbs · 4 sets          ║  ← summary line
║  ─────────────────────────   ║
║   #  REPS   WEIGHT    VEL   ║  ← column headers (mono, muted)
║   1   8    155 lbs   2.0g   ║
║   2   8    155 lbs   1.8g   ║
║   3   6    155 lbs   1.5g   ║
║   4   6    155 lbs   1.1g ⚠ ║  ← orange dot if auto-saved
║  ─────────────────────────   ║
║  ████▇▆▄▂  Approaching      ║  ← velocity sparkline + label
║            failure ⚠        ║
╚══════════════════════════════╝
```

**Changes:**
- Total volume as hero number at top, not buried in a list
- Each exercise in its own card with column-aligned set table
- Velocity sparkline always shown per exercise (hidden when < 2 sets)
- "Approaching failure" label in orange below sparkline
- Auto-saved sets get a subtle orange left border on the row, not just an icon

---

### Screen 3: Progress Tab (ProgressTabView)

**Current:** Two charts stacked, SwiftUI Charts default styling.

**New:**
```
╔══════════════════════════════╗
║  PROGRESS                    ║
║  [Volume]  [1RM]             ║  ← segmented control, custom dark style
╠══════════════════════════════╣
║                              ║
║  WEEKLY VOLUME               ║  ← card label
║  Trailing 8 weeks            ║  ← subtitle
║                              ║
║  ┌ stacked bar chart ──────┐ ║
║  │ 12k ┤             █████│ ║
║  │  8k ┤       ████ ██████│ ║
║  │  4k ┤ ████ █████ ██████│ ║
║  │     └────────────────── │ ║
║  │ May          Jun        │ ║
║  └─────────────────────────┘ ║
║                              ║
║  ■ Chest  ■ Legs  ■ Back     ║  ← legend row, compact
║  ■ Shoulders                 ║
╠══════════════════════════════╣
║  [on 1RM tab:]               ║
║                              ║
║  BENCH PRESS 1RM             ║
║  ~195 lbs  ↑ +7.5 vs last   ║  ← current estimate + delta
║                              ║
║  ┌ line chart + band ──────┐ ║
║  │     ·  ·                │ ║
║  │  · ╱───────╲            │ ║  ← shaded ±10% band
║  │ ╱─────────────·         │ ║
║  └─────────────────────────┘ ║
║  Epley estimate · ±10% band  ║  ← disclaimer, muted
╚══════════════════════════════╝
```

**Changes:**
- Tabs replaced with custom `Picker` styled as a pill segmented control
- Chart axes: dark grid lines (#2C2C2E), no border
- Chart labels: 11pt muted text, not default blue
- 1RM card shows current estimate + delta vs last week as headline
- Band rendered as semi-transparent fill, same blue as line
- Legend: compact horizontal pill badges, not SwiftUI default

---

### Screen 4: Settings (SettingsView)

**Current:** SwiftUI Form with grouped sections — system grey.

**New:**
```
╔══════════════════════════════╗
║  SETTINGS                    ║
╠══════════════════════════════╣
║                              ║
║  UNITS                       ║  ← card label
║  ┌──────────────────────────┐║
║  │ Weight Unit  [lbs] [kg]  │║  ← inline toggle
║  └──────────────────────────┘║
║                              ║
║  ABOUT                       ║
║  ┌──────────────────────────┐║
║  │ Version         1.0.0    │║
║  │ Storage    Local only    │║
║  └──────────────────────────┘║
╚══════════════════════════════╝
```

**Changes:**
- `.form` replaced with card-based layout on black background
- Picker styled as two-segment pill (not system segmented)
- All system grey gone

---

## Shared Components to Build

| Component | Description |
|-----------|-------------|
| `GymCard` | ViewModifier — dark bg, border, corner radius |
| `CardLabel` | 11pt uppercase secondary label for card titles |
| `HeroNumber` | Large bold number + small unit label below |
| `SetTableRow` | Monospaced columns: set# / reps / weight / velocity |
| `VelocitySparkline` | AreaChart, orange tint when approaching failure |
| `MuscleGroupLegend` | Horizontal colored dot + label row |
| `DeltaBadge` | ↑ / ↓ delta vs previous period, green/red |
| `FailureWarning` | Orange label + icon strip |

---

## Files to Change

| File | Change |
|------|--------|
| `SessionListView.swift` | Full rewrite — LazyVStack, custom session cards |
| `SessionDetailView.swift` | Full rewrite — hero number, set table, sparkline redesign |
| `ProgressTabView.swift` | Full rewrite — dark charts, segmented picker, 1RM delta |
| `SettingsView.swift` | Full rewrite — card layout replaces Form |
| `iPhoneContentView.swift` | TabView styling — dark tab bar, custom icons |
| *(new)* `DesignSystem.swift` | All shared modifiers, colors, typography helpers |
| *(new)* `Components/` | HeroNumber, SetTableRow, VelocitySparkline, etc. |

**Watch app:** zero changes.

---

## What Does NOT Change

- All data models, repository, calculations — untouched
- Epley formula, velocity normalization, failure threshold — untouched
- Watch app (SwiftUI + CoreMotion) — untouched
- Acceptance criteria from PRD — same requirements, new skin

---

## Acceptance Criteria (UI)

- [ ] All screens render on pure black background (#0A0A0A) in dark mode
- [ ] No default SwiftUI List or Form chrome visible anywhere in the app
- [ ] Session detail total volume renders as hero number (≥ 48pt)
- [ ] Velocity sparkline renders in orange when `isApproachingFailure == true`
- [ ] "Approaching failure" label appears in orange, not system red
- [ ] 1RM chart renders ±10% shaded band alongside line
- [ ] Weekly volume chart renders stacked bars with correct muscle group colors
- [ ] Auto-saved sets show orange left-border highlight in set table
- [ ] PRs (best set) show green highlight
- [ ] Tab bar is dark — no system grey background
- [ ] All text outside cards uses `Color("BgBase")` as background
- [ ] App looks correct on iPhone 14 (390pt) and iPhone SE (375pt)
