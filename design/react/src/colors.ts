/**
 * Flutter's `CupertinoColors`, as CSS custom-property references. Each value
 * resolves to its light or dark variant at render time, like
 * `CupertinoDynamicColor.resolveFrom(context)` does in the app.
 */
export const CupertinoColors = {
  systemBlue: "var(--cupertino-system-blue)",
  systemGreen: "var(--cupertino-system-green)",
  systemIndigo: "var(--cupertino-system-indigo)",
  systemOrange: "var(--cupertino-system-orange)",
  systemPink: "var(--cupertino-system-pink)",
  systemPurple: "var(--cupertino-system-purple)",
  systemRed: "var(--cupertino-system-red)",
  systemTeal: "var(--cupertino-system-teal)",
  systemYellow: "var(--cupertino-system-yellow)",
  systemGrey: "var(--cupertino-system-grey)",
  systemGrey2: "var(--cupertino-system-grey2)",
  systemGrey3: "var(--cupertino-system-grey3)",
  systemGrey4: "var(--cupertino-system-grey4)",
  systemGrey5: "var(--cupertino-system-grey5)",
  systemGrey6: "var(--cupertino-system-grey6)",
  activeBlue: "var(--cupertino-system-blue)",
  activeGreen: "var(--cupertino-system-green)",
  destructiveRed: "var(--cupertino-system-red)",
  label: "var(--cupertino-label)",
  secondaryLabel: "var(--cupertino-secondary-label)",
  tertiaryLabel: "var(--cupertino-tertiary-label)",
  systemBackground: "var(--cupertino-system-background)",
  secondarySystemBackground: "var(--cupertino-secondary-system-background)",
  systemGroupedBackground: "var(--cupertino-system-grouped-background)",
  secondarySystemGroupedBackground:
    "var(--cupertino-secondary-system-grouped-background)",
  separator: "var(--cupertino-separator)",
  opaqueSeparator: "var(--cupertino-opaque-separator)",
  white: "var(--cupertino-white)",
  black: "var(--cupertino-black)",
} as const;

export type CupertinoColorName = keyof typeof CupertinoColors;

/** A `CupertinoColors` name, or any CSS color string. */
export type ColorValue = CupertinoColorName | (string & {});

/** Resolves a `CupertinoColors` name to its CSS value; passes CSS colors through. */
export function resolveColor(color: ColorValue): string {
  return color in CupertinoColors
    ? CupertinoColors[color as CupertinoColorName]
    : color;
}

/** Flutter's `color.withValues(alpha: a)`. */
export function withAlpha(color: ColorValue, alpha: number): string {
  return `color-mix(in srgb, ${resolveColor(color)} ${Math.round(alpha * 100)}%, transparent)`;
}
