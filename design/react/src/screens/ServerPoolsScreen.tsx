import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { StatusPill } from "../components/SectionCard";
import {
  ConnectionErrorWidget,
  EmptyStateWidget,
  LoadingStateWidget,
  type ConnectionError,
} from "../components/States";
import { JobsBellButton, type JobsBellButtonProps } from "../components/Status";

export type VdevDiskStatus =
  | "online"
  | "degraded"
  | "faulted"
  | "offline"
  | "removed"
  | "unavail"
  | "unknown";

export interface VdevDisk {
  /** Device name, e.g. "sda". */
  name: string;
  status: VdevDiskStatus;
}

export interface PoolListItem {
  name: string;
  /** ZFS status, e.g. "ONLINE", "DEGRADED". */
  status: string;
  healthy: boolean;
  /** e.g. "Mirror (2 drives)" or "2 × RAIDZ1 (4 drives)". */
  topologyDescription: string;
  /** Every disk across the pool's data vdevs, in topology order. */
  disks: VdevDisk[];
}

export interface ServerPoolsScreenProps {
  serverName: string;
  pools?: PoolListItem[];
  /** Shows the "Loading pools..." state; wins over every other state. */
  loading?: boolean;
  /** Shows the connection error state instead of the list. */
  connectionError?: ConnectionError;
  jobsBell?: JobsBellButtonProps;
  onBack?: () => void;
  onRetry?: () => void;
  /** The error's settings action; the app pops back to the server. */
  onSettings?: () => void;
  onPoolClick?: (pool: PoolListItem) => void;
}

/**
 * The server's storage pools list: one tile per pool with health, topology
 * and a per-drive status strip that names any drive needing attention.
 * Pushed from the server dashboard; tapping a pool opens `PoolDetailScreen`.
 */
export function ServerPoolsScreen({
  serverName,
  pools = [],
  loading = false,
  connectionError,
  jobsBell,
  onBack,
  onRetry,
  onSettings,
  onPoolClick,
}: ServerPoolsScreenProps) {
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={`${serverName} - Pools`}
          leading={
            <CupertinoButton padding={0} minSize={0} onClick={onBack}>
              Back
            </CupertinoButton>
          }
          trailing={<JobsBellButton {...jobsBell} />}
        />
      }
    >
      {loading ? (
        <LoadingStateWidget message="Loading pools..." />
      ) : connectionError ? (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            minHeight: "100%",
          }}
        >
          <ConnectionErrorWidget
            error={connectionError}
            onRetry={onRetry}
            onSettings={onSettings}
          />
        </div>
      ) : pools.length === 0 ? (
        <EmptyStateWidget
          icon="square_stack_3d_down_right"
          title="No pools found"
          message="Storage pools configured on this server will appear here."
        />
      ) : (
        <div style={{ padding: 16 }}>
          {pools.map((pool) => (
            <PoolTile
              key={pool.name}
              pool={pool}
              onClick={onPoolClick && (() => onPoolClick(pool))}
            />
          ))}
        </div>
      )}
    </CupertinoPageScaffold>
  );
}

function PoolTile({
  pool,
  onClick,
}: {
  pool: PoolListItem;
  onClick?: () => void;
}) {
  const tone = pool.healthy ? "systemGreen" : "systemRed";
  const unhealthy = pool.disks.filter((d) => !isHealthy(d.status));
  return (
    <div
      className="cupertino-button"
      onClick={onClick}
      style={{
        marginBottom: 12,
        padding: 16,
        background: "var(--cupertino-system-background)",
        borderRadius: 12,
        border:
          unhealthy.length === 0
            ? "0.5px solid var(--cupertino-separator)"
            : `0.5px solid ${withAlpha("systemRed", 0.35)}`,
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        <div
          style={{
            width: 48,
            height: 48,
            flexShrink: 0,
            borderRadius: 12,
            background: withAlpha(tone, 0.1),
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <CupertinoIcon
            icon="square_stack_3d_down_right"
            color={tone}
            size={24}
          />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{pool.name}</div>
          <div
            style={{
              marginTop: 4,
              fontSize: 14,
              color: "var(--cupertino-system-grey)",
            }}
          >
            {pool.topologyDescription}
          </div>
        </div>
        <StatusPill label={pool.status} color={tone} />
      </div>
      {pool.disks.length > 0 && (
        <div
          style={{ display: "flex", flexWrap: "wrap", gap: 6, marginTop: 12 }}
        >
          {pool.disks.map((disk) => (
            <DriveBadge key={disk.name} disk={disk} />
          ))}
        </div>
      )}
      {unhealthy.length > 0 && (
        <div
          style={{
            marginTop: 8,
            fontSize: 12,
            fontWeight: 500,
            color: "var(--cupertino-system-red)",
          }}
        >
          {`${unhealthy.map((d) => d.name).join(", ")} ${unhealthy.length === 1 ? "needs" : "need"} attention`}
        </div>
      )}
    </div>
  );
}

function isHealthy(status: VdevDiskStatus): boolean {
  return status === "online";
}

const DRIVE_BADGE: Record<
  VdevDiskStatus,
  { icon: CupertinoIconName; color: ColorValue }
> = {
  online: { icon: "checkmark", color: "systemGreen" },
  degraded: { icon: "exclamationmark", color: "systemYellow" },
  unknown: { icon: "minus", color: "systemGrey" },
  faulted: { icon: "xmark", color: "systemRed" },
  offline: { icon: "xmark", color: "systemRed" },
  removed: { icon: "xmark", color: "systemRed" },
  unavail: { icon: "xmark", color: "systemRed" },
};

/** A small per-disk status chip saying which drive, if any, needs attention. */
function DriveBadge({ disk }: { disk: VdevDisk }) {
  const { icon, color } = DRIVE_BADGE[disk.status];
  return (
    <div
      title={disk.name}
      style={{
        width: 26,
        height: 34,
        borderRadius: 4,
        background: resolveColor(color),
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <CupertinoIcon icon={icon} size={14} color="white" />
    </div>
  );
}
