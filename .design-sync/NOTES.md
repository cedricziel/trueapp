# design-sync notes

## Source

- The app is Flutter (Cupertino). Claude Design needs React, so the synced
  design system is a hand-written React port in `design/react/`
  (`@truenas-manager/ui`). The user chose this on the first sync
  (2026-10-02), knowing the ports are not the shipped code.
- Component names match the Flutter classes 1:1 (`PoolCardWidget`,
  `SectionCard`, `CupertinoButton`, ...), so a design maps back to the widget
  an engineer edits. Flutter model objects (`Pool`, `App`, `Job`) became
  plain data props; private sub-widgets that are useful on their own
  (`_CpuStatsCard` -> `CpuStatsCard`) are exported.
- Colors are Flutter's `CupertinoColors` light/dark values, copied from the
  Flutter SDK (`packages/flutter/lib/src/cupertino/colors.dart`), as CSS
  variables in `design/react/src/styles.css`. Button metrics come from
  `cupertino/constants.dart`; sidebar metrics come from the
  `cupertino_sidebar` package in `~/.pub-cache`.
- Icons: `CupertinoIcon` maps the `CupertinoIcons.*` names the app uses onto
  `lucide-react` line icons, plus hand-drawn SVGs for the `*_circle_fill` and
  triangle glyphs. They're close, not identical, to the SF-style glyphs.
  `memories` is drawn as a memory stick (the app uses it for RAM).
- Not ported (no visual output): `AppLifecycleReconnector`, `ServerRouteHost`.

## Requirements from the user

- Previews must cover **light and dark mode**, **portrait and landscape**, and
  **phone, tablet and desktop** layouts. Every component preview has light
  and dark cells; layout-sensitive components (navigation shell,
  `ResponsiveRow`, `SystemStatsWidget`, list rows and cards) also get
  phone / tablet / desktop cells in portrait and landscape, via `DeviceFrame`.
- The app's screens (`lib/screens/`) must be stories too (user request,
  2026-10-02). They're ported as screen components in
  `design/react/src/screens/`, built from the ported widgets with data
  props, and previewed inside `AdaptiveNavigationScaffold` + `DeviceFrame`
  across phone/tablet/desktop, portrait/landscape, light/dark.
- The app's layout switch: below 768px a bottom `CupertinoTabBar`; at 768px
  and up, and always on macOS, a collapsible `CupertinoSidebar`
  (`lib/navigation/navigation_layout.dart`). `AdaptiveNavigationScaffold`
  ports it.

- Font: SF Pro comes from the OS through `-apple-system` (Apple's license
  forbids bundling it). The user accepted this on 2026-10-02: designs show
  real SF Pro on Apple devices and fall back to Helvetica or Arial
  elsewhere. `runtimeFontPrefixes` silences `[FONT_MISSING]` for it.

## Preview learnings

- `MemorySegmentedBar` draws each segment's `NN%` label at any width, so a
  segment under ~5% clips its label to a sliver. Flutter does the same
  (`_Segment` always renders its Text), so the port keeps it. Previews use
  Free >= 8% to keep the card readable.
- `ResponsiveRow` items have flex-basis `breakpoint / n - spacing`. A nested
  row inside a half-width card stacks at the default 600px breakpoint, so
  pass a smaller `breakpoint` (e.g. 240) for nested tile rows.

- State widgets keep `\n` in messages (`white-space: pre-line`), like
  Flutter's `Text`. The app's real connection-error copy
  (`lib/models/connection_error.dart`) is multi-line bullet lists.
- Icon gaps: `lock_shield` renders as a shield with a checkmark (lucide has
  no shield-with-lock). `wifi_exclamationmark` is a hand-drawn Wi-Fi + "!"
  because lucide's `WifiLow` read as a single dot at 16px.

- Filled icons (`*_circle_fill`, `exclamationmark_triangle_fill`) cut their
  inner mark out with an SVG mask, as SF Symbols do. A hard-coded white mark
  vanished in dark mode when no `color` was set.
- Preview cells clip at about 880 CSS px in the default grid. Components
  that need full desktop width use `cardMode: "column"`
  (`AdaptiveNavigationScaffold`, `DeviceFrame`, `SystemStatsWidget`,
  `CupertinoNavigationBar`, and all screens).

- `CupertinoPageScaffold` and `AdaptiveNavigationScaffold` fill their
  parent's height (`height: 100%`). Outside a `DeviceFrame`, give the parent
  a fixed height or they collapse.

## Where the screen ports differ from the Dart

- AddServerScreen colors the connection-test result by `success`. In the
  Flutter app every Add-screen result shows red: its messages start with
  ✅/❌, so the `startsWith("Connection successful")` check never matches.
  That's an app bug, not a port choice. EditServerScreen matches Dart.
- ServerDetailScreen quick-action tiles wrap 2x2 on phones (Dart keeps one
  row of 4, which overflows at 320px). Favourite apps come from
  `isFavorite` on each app; "Updates" counts apps with `upgradeVersion`.
- Modal popups (`showCupertinoModalPopup`) are a local fixed-position
  backdrop + `CupertinoActionSheet`. `DeviceFrame` always sets a transform,
  so fixed overlays stay inside the frame.
- ServerAppsScreen expects `apps` already filtered/sorted; ServerFilesScreen
  filters and sorts itself (folders first), like FileProvider.
- A shared non-exported `CupertinoSegmentedControl` stand-in lives in
  `design/react/src/screens/internal/` (13px labels so 4 segments fit at
  320px; Flutter default is 17px).
- ServerDetailScreen is taller than one viewport, so device cells only show
  System Stats. Extra cells pass `systemStats={{ isLoading: true }}` to
  bring pools, apps and quick tiles into view.
- ServerHealthScreen disk tiles look tall and sparse on wide screens. That
  is faithful: Flutter uses a fixed 2-column GridView, aspect 2.4.
- Error/retry widgets only render their buttons when the callback is passed;
  previews pass no-op handlers (`onRetry`, `onRefresh`) to show them.
- Phone landscape (844px) is above the 768px breakpoint, so it correctly
  shows the sidebar shell, not the tab bar.
- Add/Edit server: the CONNECTION TEST rows sit below the fold on phones;
  those preview cells scroll the screen's scroller to the bottom with a
  callback ref.
- `photo_fill` / `film_fill` use outline lucide glyphs: filling lucide's
  Image/Film outlines produced solid squares.
- AppConfigurationScreen has an `onBack` + ShellBackButton (Flutter adds the
  back chevron on pushed routes automatically).
- Review sheets for screens are very tall; crop them into ~1100px chunks
  when grading.
- Input behaviour (keyboard types, autofill, autocorrect) and non-visual
  logic (Home auto-navigation, tap guards) are not ported.

## Build

- `buildCmd`: `cd design/react && npm ci && npm run build` (esbuild bundle +
  tsc declarations; `lucide-react` stays external in `dist/` and gets
  bundled by the converter).
- npm on this machine blocks install scripts (`allow-scripts`); esbuild still
  works, because its binary ships as an optional dependency.

## Known render warns

- `[GRID_OVERFLOW]` "positions content outside cells (fixed/portal)" on
  screen stories with a dialog, sheet or modal open (AddServer, EditServer,
  Settings, ServerDetail, AppDetail, AppConfiguration). False positive: the
  overlays are `position: fixed`, but DeviceFrame's transform contains them,
  and the column card shows them inside the phone frame. Keep
  `cardMode: "column"`; `single` would hide every other device cell.

## Re-sync risks

- **The ports drift.** Nothing ties `design/react/src` to `lib/`. When a
  Flutter widget or screen changes, its React port and preview must be
  updated by hand, or Claude Design keeps designing against the old look.
  Diff `lib/widgets/`, `lib/screens/` and `lib/navigation/` since the last
  sync before re-running.
- **New widgets/screens are not picked up automatically**: port them, export
  from `design/react/src/index.ts`, add a `docsMap` group stub entry and a
  preview.
- Colors and metrics were copied from Flutter 3.32.4's Cupertino sources
  and `cupertino_sidebar` 1.0.1. A Flutter upgrade can change them.
- `.design-sync/overrides/dts.mjs` is a fork of the converter's
  `lib/dts.mjs`; on re-sync, diff it against the bundled version and merge
  upstream changes.
- Icons are lucide approximations of SF-style Cupertino glyphs (see icon
  gaps above). A new `CupertinoIcons.*` name in the app needs a mapping in
  `CupertinoIcon.tsx`, or the port fails to typecheck.
- Previews use fixed `now` dates (2026-10-02) for relative times; keep them
  fixed or grades churn.
- Build assumptions: Node 24, npm, TypeScript 7, esbuild 0.28, playwright
  1.63 with chromium-headless-shell 1243 (cached under
  `~/Library/Caches/ms-playwright`).
