import { Children, type ReactNode } from "react";

export interface SectionHeaderProps {
  title: string;
  /** Optional trailing widget, e.g. a "View All" `CupertinoButton`. */
  action?: ReactNode;
}

/**
 * A 20px semibold section title with an optional trailing action. The title
 * ellipsizes instead of pushing the action off narrow screens.
 */
export function SectionHeader({ title, action }: SectionHeaderProps) {
  return (
    <div style={{ display: "flex", alignItems: "center" }}>
      <div
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: 20,
          fontWeight: 600,
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }}
      >
        {title}
      </div>
      {action}
    </div>
  );
}

export interface FormRowLabelProps {
  /** The row's title, e.g. "Clear Database". */
  title: string;
  /** A lighter, smaller line of explanatory text under the title. */
  subtitle: string;
}

/**
 * A settings-row prefix: a 17px title over a 13px grey subtitle. Shrinks so a
 * trailing control (switch, button) keeps its space.
 */
export function FormRowLabel({ title, subtitle }: FormRowLabelProps) {
  return (
    <div
      style={{
        flex: "0 1 auto",
        minWidth: 0,
        display: "flex",
        flexDirection: "column",
      }}
    >
      <span>{title}</span>
      <span style={{ fontSize: 13, color: "var(--cupertino-system-grey)" }}>
        {subtitle}
      </span>
    </div>
  );
}

export interface ResponsiveRowProps {
  children: ReactNode;
  /** Container width (px) below which children stack. Defaults to 600. */
  breakpoint?: number;
  /** Gap in px. Defaults to 12. */
  spacing?: number;
  /** Always stack vertically. */
  forceColumn?: boolean;
}

/**
 * Lays children out as equal-width columns on wide screens and stacks them
 * full-width below `breakpoint` - e.g. the CPU and Memory cards on the
 * server dashboard.
 */
export function ResponsiveRow({
  children,
  breakpoint = 600,
  spacing = 12,
  forceColumn = false,
}: ResponsiveRowProps) {
  const items = Children.toArray(children);
  return (
    <div
      style={{
        display: "flex",
        flexDirection: forceColumn ? "column" : "row",
        flexWrap: "wrap",
        alignItems: forceColumn ? "stretch" : "flex-start",
        gap: spacing,
      }}
    >
      {items.map((child, i) => (
        <div
          key={i}
          style={{
            flex: forceColumn
              ? "none"
              : `1 1 ${breakpoint / items.length - spacing}px`,
            minWidth: 0,
          }}
        >
          {child}
        </div>
      ))}
    </div>
  );
}
