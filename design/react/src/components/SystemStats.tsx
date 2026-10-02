import type { ReactNode } from "react";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { ResponsiveRow } from "./Layout";
import {
  MemorySegmentedBar,
  TrendSparkline,
  type MemoryStats,
} from "./Metrics";
import { cardStyle } from "./shared";

function Header({
  icon,
  color,
  title,
  trailing,
}: {
  icon: CupertinoIconName;
  color: ColorValue;
  title: string;
  trailing?: ReactNode;
}) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <CupertinoIcon icon={icon} color={color} size={20} />
      <span style={{ fontSize: 16, fontWeight: 600 }}>{title}</span>
      <span style={{ flex: 1 }} />
      {trailing}
    </div>
  );
}

function threshold(
  value: number,
  red: number,
  orange: number,
  base: ColorValue,
): ColorValue {
  return value > red ? "systemRed" : value > orange ? "systemOrange" : base;
}

export interface CpuStatsCardProps {
  /** Overall CPU percent. Green, orange above 60, red above 80. */
  cpuUsage: number;
  /** Recent samples for the sparkline. */
  cpuHistory: number[];
  /** Per-core percent, e.g. { cpu0: 12, cpu1: 40 }. The first 8 render as chips. */
  cores?: Record<string, number>;
}

/** The dashboard CPU card: speedometer header with live percent, sparkline, and per-core chips. */
export function CpuStatsCard({
  cpuUsage,
  cpuHistory,
  cores = {},
}: CpuStatsCardProps) {
  const color = threshold(cpuUsage, 80, 60, "systemGreen");
  const coreEntries = Object.entries(cores).slice(0, 8);
  return (
    <div style={cardStyle()}>
      <Header
        icon="speedometer"
        color="systemBlue"
        title="CPU"
        trailing={
          <span
            style={{
              fontSize: 16,
              fontWeight: 600,
              color: resolveColor(color),
            }}
          >
            {cpuUsage.toFixed(1)}%
          </span>
        }
      />
      <div style={{ marginTop: 12 }}>
        <TrendSparkline values={cpuHistory} color={color} />
      </div>
      {coreEntries.length > 0 && (
        <div style={{ marginTop: 12 }}>
          <div
            style={{
              fontSize: 14,
              fontWeight: 500,
              color: "var(--cupertino-system-grey)",
            }}
          >
            Cores
          </div>
          <div
            style={{
              marginTop: 6,
              display: "flex",
              flexWrap: "wrap",
              gap: "6px 8px",
            }}
          >
            {coreEntries.map(([name, usage]) => {
              const cc = threshold(usage, 80, 60, "systemGreen");
              return (
                <span
                  key={name}
                  style={{
                    padding: "2px 6px",
                    borderRadius: 4,
                    background: withAlpha(cc, 0.1),
                    color: resolveColor(cc),
                    fontSize: 11,
                    fontWeight: 500,
                  }}
                >
                  {name.replace("cpu", "")}: {usage.toFixed(0)}%
                </span>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export interface MemoryStatsCardProps {
  stats: MemoryStats;
  /** Physical memory in use, percent. Purple, orange above 75, red above 90. */
  memoryUsage: number;
  memoryHistory: number[];
  formatBytes?: (bytes: number) => string;
}

/** The dashboard Memory card: header with live percent, sparkline, and the Free / ARC / Apps segmented bar. */
export function MemoryStatsCard({
  stats,
  memoryUsage,
  memoryHistory,
  formatBytes,
}: MemoryStatsCardProps) {
  const color = threshold(memoryUsage, 90, 75, "systemPurple");
  return (
    <div style={cardStyle()}>
      <Header
        icon="memories"
        color="systemPurple"
        title="Memory"
        trailing={
          <span
            style={{
              fontSize: 16,
              fontWeight: 600,
              color: resolveColor(color),
            }}
          >
            {memoryUsage.toFixed(1)}%
          </span>
        }
      />
      <div style={{ marginTop: 12 }}>
        <TrendSparkline values={memoryHistory} color={color} />
      </div>
      <div style={{ marginTop: 14 }}>
        <MemorySegmentedBar stats={stats} formatBytes={formatBytes} />
      </div>
    </div>
  );
}

export interface DiskStats {
  /** Percent busy. */
  busy: number;
  /** Pre-formatted rates, e.g. "48.2 MB/s". */
  readRate: string;
  writeRate: string;
  readOps: number;
  writeOps: number;
}

function IOMetric({
  label,
  rate,
  ops,
  color,
}: {
  label: string;
  rate: string;
  ops: string;
  color: ColorValue;
}) {
  return (
    <div style={{ flex: 1 }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <span
          style={{
            width: 8,
            height: 8,
            borderRadius: "50%",
            background: resolveColor(color),
          }}
        />
        <span style={{ fontSize: 14, fontWeight: 500 }}>{label}</span>
      </div>
      <div
        style={{
          marginTop: 4,
          fontSize: 13,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {rate}
      </div>
      <div style={{ fontSize: 11, color: "var(--cupertino-system-grey2)" }}>
        {ops}
      </div>
    </div>
  );
}

/** The dashboard Disk I/O card: busy percent plus Read / Write throughput and ops/s. */
export function DiskStatsCard({ diskStats }: { diskStats: DiskStats }) {
  const color = threshold(diskStats.busy, 80, 60, "systemGreen");
  return (
    <div style={cardStyle()}>
      <Header
        icon="device_desktop"
        color="systemGreen"
        title="Disk I/O"
        trailing={
          <span
            style={{
              fontSize: 14,
              fontWeight: 500,
              color: resolveColor(color),
            }}
          >
            {diskStats.busy.toFixed(1)}% busy
          </span>
        }
      />
      <div style={{ marginTop: 12, display: "flex", gap: 16 }}>
        <IOMetric
          label="Read"
          rate={diskStats.readRate}
          ops={`${diskStats.readOps.toFixed(1)} ops/s`}
          color="systemBlue"
        />
        <IOMetric
          label="Write"
          rate={diskStats.writeRate}
          ops={`${diskStats.writeOps.toFixed(1)} ops/s`}
          color="systemOrange"
        />
      </div>
    </div>
  );
}

export interface NetworkInterfaceStats {
  name: string;
  /** Pre-formatted, e.g. "1.2 MB/s". */
  receivedRate: string;
  sentRate: string;
  isUp?: boolean;
}

/** The dashboard Network card: one row per up interface with down/up rates and an UP chip. */
export function NetworkStatsCard({
  interfaces,
}: {
  interfaces: NetworkInterfaceStats[];
}) {
  const active = interfaces.filter((i) => i.isUp !== false);
  if (active.length === 0) return null;
  const rate = { fontSize: 12, color: "var(--cupertino-system-grey)" };
  return (
    <div style={cardStyle()}>
      <Header icon="wifi" color="systemTeal" title="Network" />
      <div style={{ marginTop: 12 }}>
        {active.map((iface) => (
          <div
            key={iface.name}
            style={{ display: "flex", alignItems: "center", paddingBottom: 8 }}
          >
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 500 }}>{iface.name}</div>
              <div
                style={{
                  marginTop: 2,
                  display: "flex",
                  alignItems: "center",
                  gap: 4,
                }}
              >
                <CupertinoIcon icon="arrow_down" size={12} color="systemBlue" />
                <span style={rate}>{iface.receivedRate}</span>
                <span style={{ width: 8 }} />
                <CupertinoIcon icon="arrow_up" size={12} color="systemOrange" />
                <span style={rate}>{iface.sentRate}</span>
              </div>
            </div>
            <span
              style={{
                padding: "2px 6px",
                borderRadius: 4,
                background: withAlpha("systemGreen", 0.1),
                color: "var(--cupertino-system-green)",
                fontSize: 10,
                fontWeight: 600,
              }}
            >
              UP
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

export interface SystemStatsWidgetProps {
  /** Loading with no data yet shows a spinner. */
  isLoading?: boolean;
  /** Error with no data shows a red banner. */
  error?: string;
  cpu?: CpuStatsCardProps;
  memory?: MemoryStatsCardProps;
  disk?: DiskStats;
  network?: NetworkInterfaceStats[];
}

/**
 * The server dashboard's live stats block: CPU and Memory side by side
 * (stacked on phones), then Disk I/O and Network. Also renders its loading,
 * error and empty states.
 */
export function SystemStatsWidget({
  isLoading,
  error,
  cpu,
  memory,
  disk,
  network = [],
}: SystemStatsWidgetProps) {
  const hasData = cpu || memory || disk;
  if (isLoading && !hasData) {
    return (
      <div style={{ display: "flex", justifyContent: "center", padding: 32 }}>
        <CupertinoActivityIndicator />
      </div>
    );
  }
  if (error && !hasData) {
    return (
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          padding: 16,
          borderRadius: 12,
          background: withAlpha("systemRed", 0.1),
          border: `1px solid ${withAlpha("systemRed", 0.3)}`,
        }}
      >
        <CupertinoIcon
          icon="exclamationmark_triangle"
          size={20}
          color="systemRed"
        />
        <span style={{ fontSize: 14, color: "var(--cupertino-system-red)" }}>
          Failed to load system stats: {error}
        </span>
      </div>
    );
  }
  if (!hasData) {
    return (
      <div
        style={{
          ...cardStyle(false),
          padding: 24,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        <CupertinoIcon icon="chart_bar" size={32} color="systemGrey" />
        <span
          style={{
            marginTop: 8,
            fontSize: 16,
            color: "var(--cupertino-system-grey)",
          }}
        >
          No system stats available
        </span>
      </div>
    );
  }
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <ResponsiveRow>
        {cpu && <CpuStatsCard {...cpu} />}
        {memory && <MemoryStatsCard {...memory} />}
      </ResponsiveRow>
      {disk && <DiskStatsCard diskStats={disk} />}
      {network.length > 0 && <NetworkStatsCard interfaces={network} />}
    </div>
  );
}
