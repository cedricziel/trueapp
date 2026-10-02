import { withAlpha } from "../colors";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { StorageMetricWidget } from "./Metrics";
import { cardStyle, formatBytesCompact } from "./shared";

export interface Pool {
  name: string;
  /** ZFS status, e.g. "ONLINE", "DEGRADED". */
  status: string;
  healthy: boolean;
  /** e.g. "RAIDZ1 · 4 disks". */
  topologyDescription: string;
  allocatedBytes: number;
  freeBytes: number;
  totalBytes: number;
}

export interface PoolCardWidgetProps {
  pool: Pool;
  onClick?: () => void;
}

/**
 * A storage pool in the Pools list: health-tinted icon tile, name and
 * topology, a status chip, and Used / Available / Total metrics.
 */
export function PoolCardWidget({ pool, onClick }: PoolCardWidgetProps) {
  const tone = pool.healthy ? "systemGreen" : "systemRed";
  return (
    <div
      onClick={onClick}
      style={{ ...cardStyle(), cursor: onClick ? "pointer" : undefined }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <div
          style={{
            width: 44,
            height: 44,
            flexShrink: 0,
            borderRadius: 10,
            background: withAlpha(tone, 0.1),
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <CupertinoIcon
            icon="square_stack_3d_down_right"
            color={tone}
            size={22}
          />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{pool.name}</div>
          <div
            style={{
              marginTop: 2,
              fontSize: 13,
              color: "var(--cupertino-system-grey)",
            }}
          >
            {pool.topologyDescription}
          </div>
        </div>
        <span
          style={{
            padding: "4px 8px",
            borderRadius: 6,
            background: withAlpha(tone, 0.1),
            color: `var(--cupertino-system-${pool.healthy ? "green" : "red"})`,
            fontSize: 12,
            fontWeight: 500,
          }}
        >
          {pool.status}
        </span>
      </div>
      <div style={{ display: "flex", marginTop: 12 }}>
        <div style={{ flex: 1 }}>
          <StorageMetricWidget
            label="Used"
            value={formatBytesCompact(pool.allocatedBytes)}
            color="systemBlue"
          />
        </div>
        <div style={{ flex: 1 }}>
          <StorageMetricWidget
            label="Available"
            value={formatBytesCompact(pool.freeBytes)}
            color="systemGreen"
          />
        </div>
        <div style={{ flex: 1 }}>
          <StorageMetricWidget
            label="Total"
            value={formatBytesCompact(pool.totalBytes)}
            color="systemGrey"
          />
        </div>
      </div>
    </div>
  );
}
