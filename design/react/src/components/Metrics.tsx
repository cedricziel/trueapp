import { useId } from "react";
import { resolveColor, type ColorValue } from "../colors";

export interface UsageBarProps {
  /** Percentage, 0-100 (clamped). */
  usage: number;
  color: ColorValue;
  /** Bar height in px. Defaults to 8. */
  height?: number;
  /** Corner radius in px. Defaults to 4. */
  borderRadius?: number;
}

/** A horizontal progress bar on a `systemGrey5` track, for usage percentages. */
export function UsageBar({
  usage,
  color,
  height = 8,
  borderRadius = 4,
}: UsageBarProps) {
  const pct = Math.min(Math.max(usage, 0), 100);
  return (
    <div
      role="meter"
      aria-valuenow={pct}
      aria-valuemin={0}
      aria-valuemax={100}
      style={{
        height,
        borderRadius,
        background: "var(--cupertino-system-grey5)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          width: `${pct}%`,
          height: "100%",
          borderRadius,
          background: resolveColor(color),
        }}
      />
    </div>
  );
}

export interface StorageMetricWidgetProps {
  label: string;
  /** Pre-formatted value, e.g. "1.2TB". */
  value: string;
  color: ColorValue;
}

/** A centered colored value over a small grey label - the Used / Available / Total trio on pool cards. */
export function StorageMetricWidget({
  label,
  value,
  color,
}: StorageMetricWidgetProps) {
  return (
    <div
      style={{ display: "flex", flexDirection: "column", alignItems: "center" }}
    >
      <span
        style={{ fontSize: 14, fontWeight: 600, color: resolveColor(color) }}
      >
        {value}
      </span>
      <span
        style={{
          marginTop: 2,
          fontSize: 12,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {label}
      </span>
    </div>
  );
}

export interface TrendSparklineProps {
  /** Recent samples, oldest first. Fewer than two draws a flat placeholder baseline. */
  values: number[];
  color: ColorValue;
  /** Height in px. Defaults to 32. Width fills the parent. */
  height?: number;
}

/**
 * A minimal line-and-area sparkline of a metric's recent history (CPU, memory).
 * Auto-scales to its own min/max so short-term variation stays visible.
 */
export function TrendSparkline({
  values,
  color,
  height = 32,
}: TrendSparklineProps) {
  const id = useId();
  const c = resolveColor(color);
  const W = 100;
  if (values.length < 2) {
    return (
      <svg
        width="100%"
        height={height}
        viewBox={`0 0 ${W} ${height}`}
        preserveAspectRatio="none"
        style={{ display: "block" }}
      >
        <line
          x1="0"
          x2={W}
          y1={height * 0.7}
          y2={height * 0.7}
          stroke={c}
          strokeOpacity={0.3}
          strokeWidth={2}
          vectorEffect="non-scaling-stroke"
        />
      </svg>
    );
  }
  const max = Math.max(...values);
  const min = Math.min(...values);
  const range = Math.abs(max - min) < 1e-6 ? 1 : max - min;
  const dx = W / (values.length - 1);
  const pts = values.map((v, i) => [
    dx * i,
    height - ((v - min) / range) * (height - 4) - 2,
  ]);
  const line = pts
    .map(([x, y], i) => `${i ? "L" : "M"}${x.toFixed(2)},${y.toFixed(2)}`)
    .join(" ");
  const area = `M0,${height} L${pts.map(([x, y]) => `${x.toFixed(2)},${y.toFixed(2)}`).join(" L")} L${W},${height} Z`;
  return (
    <svg
      width="100%"
      height={height}
      viewBox={`0 0 ${W} ${height}`}
      preserveAspectRatio="none"
      style={{ display: "block" }}
      aria-labelledby={id}
    >
      <title id={id}>Trend</title>
      <path d={area} fill={c} fillOpacity={0.08} />
      <path
        d={line}
        fill="none"
        stroke={c}
        strokeWidth={2}
        strokeLinecap="round"
        strokeLinejoin="round"
        vectorEffect="non-scaling-stroke"
      />
    </svg>
  );
}

export interface MemoryStats {
  /** Bytes not in use, excluding the ZFS ARC cache. */
  freeMemory: number;
  /** ZFS ARC cache size in bytes. */
  arcSize: number;
  /** Bytes used by apps and services. */
  appsMemory: number;
}

export interface MemorySegmentedBarProps {
  stats: MemoryStats;
  /** Byte formatter for the legend. Defaults to "12.3 GiB" style. */
  formatBytes?: (bytes: number) => string;
}

function defaultFormat(bytes: number) {
  return `${(bytes / 1024 ** 3).toFixed(1)} GiB`;
}

/**
 * 100% of physical memory in one bar split into Free / ZFS ARC / Apps &
 * Services, with a legend of exact values and a footnote.
 */
export function MemorySegmentedBar({
  stats,
  formatBytes = defaultFormat,
}: MemorySegmentedBarProps) {
  const total = stats.freeMemory + stats.arcSize + stats.appsMemory || 1;
  const segments = [
    {
      label: "Free",
      bytes: stats.freeMemory,
      color: "var(--cupertino-system-grey3)",
      text: "var(--cupertino-label)",
    },
    {
      label: "ZFS ARC",
      bytes: stats.arcSize,
      color: "var(--cupertino-system-blue)",
      text: "var(--cupertino-white)",
    },
    {
      label: "Apps & Services",
      bytes: stats.appsMemory,
      color: "var(--cupertino-system-purple)",
      text: "var(--cupertino-white)",
    },
  ].map((s) => ({ ...s, pct: (s.bytes / total) * 100 }));

  return (
    <div>
      <div
        style={{
          display: "flex",
          gap: 1.5,
          height: 26,
          borderRadius: 8,
          overflow: "hidden",
        }}
      >
        {segments.map((s) => (
          <div
            key={s.label}
            style={{
              flex: `${Math.min(Math.max(Math.round(s.pct), 1), 100)} 1 0`,
              background: s.color,
              color: s.text,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 11,
              fontWeight: 700,
              overflow: "hidden",
            }}
          >
            {Math.round(s.pct)}%
          </div>
        ))}
      </div>
      <div
        style={{
          marginTop: 14,
          paddingTop: 2,
          borderTop: "0.5px solid var(--cupertino-separator)",
        }}
      >
        {segments.map((s, i) => (
          <div
            key={s.label}
            style={{
              display: "flex",
              alignItems: "center",
              marginTop: i ? 10 : 0,
            }}
          >
            <span
              style={{
                width: 9,
                height: 9,
                borderRadius: "50%",
                background: s.color,
                flexShrink: 0,
              }}
            />
            <span style={{ marginLeft: 10, flex: 1, fontSize: 13 }}>
              {s.label}
            </span>
            <span style={{ fontSize: 13, fontWeight: 600 }}>
              {formatBytes(s.bytes)}
            </span>
            <span
              style={{
                width: 40,
                textAlign: "right",
                fontSize: 12,
                color: "var(--cupertino-system-grey)",
              }}
            >
              {Math.round(s.pct)}%
            </span>
          </div>
        ))}
      </div>
      <div
        style={{
          marginTop: 10,
          fontSize: 11,
          color: "var(--cupertino-tertiary-label)",
        }}
      >
        Free excludes the ZFS ARC cache, so Free + ZFS ARC + Apps adds up to
        100% of physical memory.
      </div>
    </div>
  );
}
