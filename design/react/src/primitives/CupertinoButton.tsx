import type { CSSProperties, ReactNode } from "react";
import { resolveColor, type ColorValue } from "../colors";

export type CupertinoButtonSize = "small" | "medium" | "large";

const PADDING: Record<CupertinoButtonSize, string> = {
  small: "6px 12px",
  medium: "10px 15px",
  large: "16px 20px",
};
const RADIUS: Record<CupertinoButtonSize, number> = {
  small: 40,
  medium: 40,
  large: 12,
};
const MIN_SIZE: Record<CupertinoButtonSize, number> = {
  small: 28,
  medium: 32,
  large: 44,
};
const FONT: Record<CupertinoButtonSize, number> = {
  small: 15,
  medium: 17,
  large: 17,
};

export interface CupertinoButtonProps {
  children: ReactNode;
  /** `filled` = `CupertinoButton.filled` (primary background, white label); `plain` = `CupertinoButton` (tinted label, no background). */
  variant?: "plain" | "filled";
  /** Flutter's `sizeStyle`. Defaults to `large`. */
  size?: CupertinoButtonSize;
  /** Background for `filled`, label color for `plain`. Defaults to the theme primary (systemBlue). */
  color?: ColorValue;
  /** CSS padding. Pass `0` for Flutter's `padding: EdgeInsets.zero` inline-text buttons. */
  padding?: string | number;
  /** Minimum width/height in px (Flutter's `minimumSize`). Pass `0` for `Size.zero`. */
  minSize?: number;
  disabled?: boolean;
  onClick?: () => void;
  style?: CSSProperties;
}

/**
 * Flutter's `CupertinoButton` / `CupertinoButton.filled`: an iOS text button
 * that dims on press. Children are usually a label string, or an icon plus label.
 */
export function CupertinoButton({
  children,
  variant = "plain",
  size = "large",
  color,
  padding,
  minSize,
  disabled = false,
  onClick,
  style,
}: CupertinoButtonProps) {
  const tint = resolveColor(color ?? "var(--cupertino-primary)");
  const filled = variant === "filled";
  const min = minSize ?? MIN_SIZE[size];
  return (
    <button
      type="button"
      className="cupertino-button"
      disabled={disabled}
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        minWidth: min,
        minHeight: min,
        padding: padding ?? PADDING[size],
        border: "none",
        borderRadius: RADIUS[size],
        background: filled
          ? disabled
            ? "var(--cupertino-system-grey5)"
            : tint
          : "transparent",
        color: disabled
          ? "var(--cupertino-tertiary-label)"
          : filled
            ? "var(--cupertino-white)"
            : tint,
        font: "inherit",
        fontSize: FONT[size],
        letterSpacing: size === "small" ? -0.23 : -0.41,
        lineHeight: 1.2,
        cursor: disabled ? "default" : "pointer",
        whiteSpace: "nowrap",
        ...style,
      }}
    >
      {children}
    </button>
  );
}
