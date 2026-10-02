import type { ReactNode } from "react";

export interface CupertinoNavigationBarProps {
  /** Centered title (Flutter's `middle`). */
  middle?: ReactNode;
  /** Leading slot, e.g. a back button. */
  leading?: ReactNode;
  /** Trailing slot, e.g. `JobsBellButton` or `ConnectionStatusTitleWidget`. */
  trailing?: ReactNode;
  /** Large title shown under the bar, like `CupertinoSliverNavigationBar`. */
  largeTitle?: ReactNode;
}

/**
 * Flutter's `CupertinoNavigationBar`: the translucent 44px top bar with a
 * centered title and leading/trailing slots, plus an optional large title.
 */
export function CupertinoNavigationBar({
  middle,
  leading,
  trailing,
  largeTitle,
}: CupertinoNavigationBarProps) {
  return (
    <div
      style={{
        background:
          "color-mix(in srgb, var(--cupertino-system-background) 85%, transparent)",
        backdropFilter: "blur(20px)",
        borderBottom: "0.5px solid var(--cupertino-separator)",
      }}
    >
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr auto 1fr",
          alignItems: "center",
          height: 44,
          padding: "0 16px",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "flex-start",
            color: "var(--cupertino-primary)",
          }}
        >
          {leading}
        </div>
        <div style={{ fontSize: 17, fontWeight: 600, letterSpacing: -0.41 }}>
          {middle}
        </div>
        <div
          style={{
            display: "flex",
            justifyContent: "flex-end",
            gap: 8,
            alignItems: "center",
          }}
        >
          {trailing}
        </div>
      </div>
      {largeTitle != null && (
        <div
          style={{
            padding: "2px 16px 8px",
            fontFamily: "var(--cupertino-font-display)",
            fontSize: 34,
            fontWeight: 700,
            letterSpacing: 0.38,
          }}
        >
          {largeTitle}
        </div>
      )}
    </div>
  );
}
