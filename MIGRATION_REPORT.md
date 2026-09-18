# M4 Family — UI Theme Migration Report

**Target:** Migrate the m4-family Flutter app UI from the old black/white theme to the
Figma **deep‑green / cream / gold glassmorphism** design — **without changing any business
logic, APIs, navigation, or state management**. Fonts: **Georgia (primary)** + **Garamond
(secondary)**.

**Project migrated:** `C:\m4family_app\m4family_app` (the real, git‑tracked project).
> ⚠️ There is a stale duplicate at `C:\m4family_app\m4family_app\m4family_app` (its own old
> `.git`, last touched 23 Jul). It is **still black/white**. Always run from the ROOT.

---

## 1. Design System (centralized in `lib/core/theme/app_theme.dart` → `M4Theme`)

### Colour palette
| Token | Value | Use |
|---|---|---|
| `deepGreen` | `#0F2A20` | Dark theme background |
| `forestGreen` | `#163A2C` | Dark surfaces / cards |
| `midGreen` | `#1C4535` | Secondary green surface / active accents |
| `cream` | `#F4EFE3` | Dark‑theme text |
| `lightBackground` | `#F3EDE0` | Light theme background |
| `lightForeground` | `#15271E` | Light‑theme text (dark green) |
| `lightCard` | `#FBF7EF` | Light surfaces / cards |
| `gold` | `#C5A35B` | Accent (logo, focus, small labels) |
| `coral` | `#C65B46` | Destructive / EXIT APP |

**Theme mapping:** Dark mode = **green**, Light mode = **cream** (existing THEME MODE toggle preserved).

### Typography
- **Primary (headings / display) = Georgia → `GoogleFonts.gelasio`** (metrically identical, license‑safe).
- **Secondary (body / labels) = Garamond → `GoogleFonts.ebGaramond`.**
- (Georgia & Garamond are proprietary/system fonts — cannot be bundled into a mobile app — so their faithful Google equivalents are used.)

---

## 2. What was changed (UI / theme only)

1. **Centralized `M4Theme`** — light + dark `ThemeData` now define: `colorScheme`, `textTheme`
   (Gelasio/EB Garamond), `appBarTheme`, `elevatedButtonTheme`, **`outlinedButtonTheme`,
   `textButtonTheme`, `cardTheme`, `inputDecorationTheme`, `dialogTheme`, `bottomSheetTheme`,
   `snackBarTheme`, `dividerTheme`** (rounded corners, gold focus, premium shadows).
2. **Fonts swept app‑wide** — every `GoogleFonts.montserrat / inter` → `ebGaramond`;
   `dmSerifDisplay / lora / playfairDisplay` → `gelasio` (128 files).
3. **Colours swept app‑wide** — off‑brand hex + named colours (blue/purple/teal/amber/etc.)
   → **gold**; reds → **coral**; near‑black surfaces → **green**; near‑white → **cream**.
   Palette is now consistent (only brand colours, neutral greys, and image‑overlay blacks remain).
4. **Bottom navigation → glassmorphism** (guest, customer, CP, investor) — frosted translucent
   bar (green glass on dark / white glass on cream), crisp icons, active = green circle (cream)
   / white circle (green).
5. **Menu sidebar → glassmorphism** (all 4 sidebars) — frosted translucent panel, content blurs
   behind it, **green text in light mode**, active item = left accent bar + lifted icon box,
   coral EXIT APP.
6. **"Living the M4 Life" wordmark** — two‑stage colour filter removes the PNG's baked
   transparency‑checker and recolours it to the theme.
7. **Content‑screen backgrounds** — screens that hardcoded `black/white` backgrounds now follow
   the theme (green/cream).

---

## 3. What was NOT changed (guaranteed)

- ❌ Business logic, API calls (`api_client`, providers' fetch logic)
- ❌ Navigation routes / `go_router` config
- ❌ Riverpod state management / providers' behaviour
- ❌ Widget trees' structure / functionality
- ✅ Only colours, fonts, and decorative styling were modified.

---

## 4. Modified files (by area)

| Area | Files |
|---|---|
| `core/theme` (design system) | 1 (`app_theme.dart`) |
| Reusable widgets (navs, sidebars, shells, pills) | 15 |
| CP portal screens | 39 |
| Investor portal screens | 27 |
| Profile screens | 11 |
| Support screens | 10 |
| Booking screens | 6 |
| Projects / Communities / Careers / Custom Views | 14 |
| Auth screens | 5 |
| Home / About / Content / misc screens | ~9 |
| Providers (font/colour refs only, no logic) | 11 |
| **Total lib files touched** | **~130** |

(Full list: `git status` from the project root.)

---

## 5. How to run (IMPORTANT)

```bash
cd C:\m4family_app\m4family_app
flutter run
```

Do **NOT** run from `C:\m4family_app\m4family_app\m4family_app` (stale black/white copy).

Verified on Android emulator (light + dark): home, communities, about, contact, menu, bottom nav — all match the Figma. `flutter analyze` → **0 errors**.
