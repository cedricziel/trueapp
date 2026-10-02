# TrueNAS Manager — building with this library

These are React ports of the TrueNAS Manager Flutter app (iOS, iPadOS and macOS, Cupertino only). Component names match the Flutter classes, so `PoolCardWidget` here is `PoolCardWidget` in the app. Never use Material-style UI: no floating action buttons, ripples, elevation shadows or outlined text inputs.

## Setup

Wrap every design in `CupertinoApp`. It sets the system font (SF Pro via `-apple-system`), the label color and the page background, and its `brightness` prop (`"light"` | `"dark"`) switches the whole palette. Without it, text renders in the browser default and dark mode never applies. Use `background="systemGroupedBackground"` for settings and form screens.

For a full screen, nest three layers:

- `DeviceFrame` (`device="phone" | "tablet" | "desktop"`, `orientation`, `brightness`, `scale`) gives a real viewport.
- `AdaptiveNavigationScaffold` adds the app shell. It shows a bottom `CupertinoTabBar` below 768px and a `CupertinoSidebar` from 768px up (always on macOS). `selectedIndex` is 0 for Servers and 1 for Settings.
- `CupertinoPageScaffold` with `navigationBar={<CupertinoNavigationBar largeTitle=… trailing=… />}` holds the screen itself.

Both scaffolds fill their parent's height, so outside a `DeviceFrame` give the parent a fixed height.

Prefer the finished screens (`HomeScreen`, `ServerDetailScreen`, `ServerPoolsScreen`, `ServerAppsScreen`, `ServerJobsScreen`, `SettingsScreen`, `AddServerScreen`, …) when a design starts from an existing screen. Every state is a prop: `loading`, `error`, empty lists, dialogs.

## Styling idiom

There are no utility classes. Components take data props and color props. Style your own layout glue with inline styles and CSS variables:

- **Colors:** pass a `CupertinoColors` name (`"systemBlue"`, `"systemGreen"`, `"systemRed"`, `"systemOrange"`, `"systemPurple"`, `"systemTeal"`, `"systemGrey"`, `"label"`, `"secondaryLabel"`, `"tertiaryLabel"`) to any `color` prop. In CSS, use `var(--cupertino-system-blue)`, `var(--cupertino-label)`, `var(--cupertino-secondary-label)`, `var(--cupertino-separator)`, `var(--cupertino-system-grey6)`, `var(--cupertino-system-background)` and `var(--cupertino-system-grouped-background)`. Every variable has light and dark values, so never hard-code hex.
- **Tints:** status backgrounds are the status color at 10% alpha: `withAlpha("systemGreen", 0.1)`, or `color-mix(in srgb, var(--cupertino-system-green) 10%, transparent)`. Green means healthy or online, orange means warning or connecting, red means error, failed or degraded, and blue is neutral or primary.
- **Cards:** `background: var(--cupertino-system-grey6)`, `border-radius: 12px`, `border: 0.5px solid var(--cupertino-separator)`, `padding: 16px`, with 12px gaps between cards. Icon tiles are 44px with a 10px radius on a 10% tint.
- **Type scale:** 34/700 large title, 20/600 section header (`SectionHeader`), 17 body, 16/600 card title, 14 secondary text in `systemGrey`, 13 captions, 12/600 chips (`StatusPill`), 11 metadata.
- **Icons:** `<CupertinoIcon icon="…" />` takes the app's `CupertinoIcons` names (`"bell"`, `"square_stack_3d_down_right"`, `"checkmark_circle_fill"`, …). The full union is in `CupertinoIcon.d.ts`.
- **Buttons:** `CupertinoButton variant="filled"` for the primary action, plain for secondary. Use `padding={0} minSize={0}` for inline text buttons.

## Where the truth lives

Read `styles.css` for every token and its dark value. Each component's `.d.ts` defines its props and data types (`Pool`, `TrueNASApp`, `Job`, `NasServer`), and its `.prompt.md` has examples.

## Example

```jsx
<CupertinoApp brightness="dark" style={{ padding: 16 }}>
  <SectionHeader
    title="Storage Pools"
    action={
      <CupertinoButton padding={0} minSize={0}>
        View All
      </CupertinoButton>
    }
  />
  <div
    style={{ display: "flex", flexDirection: "column", gap: 12, marginTop: 12 }}
  >
    <PoolCardWidget
      pool={{
        name: "tank",
        status: "ONLINE",
        healthy: true,
        topologyDescription: "RAIDZ1 · 4 disks",
        allocatedBytes: 6.2e12,
        freeBytes: 4.7e12,
        totalBytes: 10.9e12,
      }}
    />
    <SectionCard title="General" icon="square_stack_3d_down_right">
      <InfoRow label="Status" value="ONLINE" valueColor="systemGreen" />
      <InfoRow label="Scrub" value="Finished 2 days ago, 0 errors" />
    </SectionCard>
  </div>
</CupertinoApp>
```
