import type { ReactNode } from "react";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";

export interface SectionCardProps {
  title: string;
  icon: CupertinoIconName;
  /** Defaults to `activeBlue`. */
  iconColor?: ColorValue;
  /** Usually `InfoRow`s. */
  children?: ReactNode;
}

/**
 * A titled, icon-led card grouping related label/value rows - the
 * property-inspector sections on the dataset, pool and user profile screens.
 * Pair with `InfoRow` for the rows inside it.
 */
export function SectionCard({
  title,
  icon,
  iconColor = "activeBlue",
  children,
}: SectionCardProps) {
  return (
    <div
      style={{
        padding: 16,
        background: "var(--cupertino-system-grey6)",
        borderRadius: 12,
        border: "0.5px solid var(--cupertino-separator)",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          marginBottom: 16,
        }}
      >
        <CupertinoIcon icon={icon} color={iconColor} size={20} />
        <div
          style={{
            flex: 1,
            minWidth: 0,
            fontSize: 16,
            fontWeight: 600,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {title}
        </div>
      </div>
      {children}
    </div>
  );
}

export interface InfoRowProps {
  label: string;
  value: string;
  /** Tints the value, e.g. `systemGreen` for "ONLINE". */
  valueColor?: ColorValue;
}

/**
 * A fixed-label-width (120px) label/value row for use inside a `SectionCard`,
 * so values across rows line up.
 */
export function InfoRow({ label, value, valueColor }: InfoRowProps) {
  return (
    <div
      style={{ display: "flex", alignItems: "flex-start", paddingBottom: 8 }}
    >
      <div
        style={{
          width: 120,
          flexShrink: 0,
          fontSize: 14,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {label}
      </div>
      <div
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: 14,
          fontWeight: 500,
          color: valueColor ? resolveColor(valueColor) : undefined,
        }}
      >
        {value}
      </div>
    </div>
  );
}

export interface StatusPillProps {
  label: string;
  color: ColorValue;
  icon?: CupertinoIconName;
}

/**
 * A small tinted status/badge pill: a 10%-alpha fill of `color`, an optional
 * leading icon, and solid-`color` text.
 */
export function StatusPill({ label, color, icon }: StatusPillProps) {
  const c = resolveColor(color);
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        padding: "6px 12px",
        borderRadius: 12,
        background: withAlpha(color, 0.1),
        color: c,
        fontSize: 12,
        fontWeight: 600,
        lineHeight: 1.2,
      }}
    >
      {icon && <CupertinoIcon icon={icon} size={14} color={color} />}
      {label}
    </span>
  );
}
