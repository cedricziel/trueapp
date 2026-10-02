import type { ReactNode } from "react";

export interface CupertinoSegmentedControlProps<T extends string> {
  segments: { value: T; label: ReactNode }[];
  groupValue: T;
  onValueChanged?: (value: T) => void;
}

/**
 * Stand-in for Flutter's `CupertinoSegmentedControl` (not yet in the
 * primitives): equal-width segments in a 1px primary-blue outline with
 * 3px corners; the selected segment is filled blue with a white label.
 */
export function CupertinoSegmentedControl<T extends string>({
  segments,
  groupValue,
  onValueChanged,
}: CupertinoSegmentedControlProps<T>) {
  const tint = "var(--cupertino-primary)";
  return (
    <div
      role="tablist"
      style={{
        display: "flex",
        width: "100%",
        minHeight: 28,
        boxSizing: "border-box",
        border: `1px solid ${tint}`,
        borderRadius: 3,
        overflow: "hidden",
      }}
    >
      {segments.map(({ value, label }, i) => {
        const selected = value === groupValue;
        return (
          <button
            key={value}
            type="button"
            role="tab"
            aria-selected={selected}
            onClick={() => onValueChanged?.(value)}
            style={{
              flex: "1 1 0",
              minWidth: 0,
              padding: "4px 4px",
              border: "none",
              borderLeft: i > 0 ? `1px solid ${tint}` : undefined,
              background: selected
                ? tint
                : "var(--cupertino-system-background)",
              color: selected ? "var(--cupertino-white)" : tint,
              font: "inherit",
              fontSize: 13,
              letterSpacing: -0.08,
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
              cursor: "pointer",
            }}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
