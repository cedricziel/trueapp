import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoIcon } from "../primitives/CupertinoIcon";

export interface NasServer {
  name: string;
  /** e.g. "https://nas.local". */
  baseUrl: string;
  /** Whether this is the currently selected server. */
  isActive?: boolean;
}

export type FleetServerConnectivity =
  "loading" | "unknown" | "online" | "offline";

export interface FleetServerStatus {
  connectivity: FleetServerConnectivity;
  /** Percent; omit when the server didn't report it (renders "–"). */
  cpuUsage?: number;
  storageUsage?: number;
  activeAlertCount?: number;
  /** Tints the row red and turns the icon red. */
  needsAttention?: boolean;
}

export interface ServerListTileProps {
  server: NasServer;
  /** Fleet health snapshot; adds a status line with CPU/Storage mini bars. */
  status?: FleetServerStatus;
  onClick?: () => void;
}

function MiniMetric({ label, value }: { label: string; value?: number }) {
  const pct = value == null ? undefined : Math.min(Math.max(value, 0), 100);
  const color: ColorValue =
    pct == null
      ? "systemGrey4"
      : pct > 85
        ? "systemRed"
        : pct > 65
          ? "systemOrange"
          : "activeGreen";
  return (
    <div
      style={{ flex: 1, display: "flex", alignItems: "center", minWidth: 0 }}
    >
      <span style={{ fontSize: 11, color: "var(--cupertino-system-grey)" }}>
        {label}&nbsp;
      </span>
      <div
        style={{
          flex: 1,
          height: 4,
          borderRadius: 2,
          background: "var(--cupertino-system-grey5)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            width: `${pct ?? 0}%`,
            height: "100%",
            borderRadius: 2,
            background: resolveColor(color),
          }}
        />
      </div>
      <span
        style={{
          marginLeft: 4,
          fontSize: 10,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {pct == null ? "–" : `${pct.toFixed(0)}%`}
      </span>
    </div>
  );
}

/**
 * A server row on the home screen: desktop icon tinted by health, name and
 * URL, a chevron, and (with a fleet `status`) a line of CPU/Storage mini bars
 * or "Checking…" / "Offline". Rows needing attention get a faint red wash.
 */
export function ServerListTile({
  server,
  status,
  onClick,
}: ServerListTileProps) {
  const conn = status?.connectivity;
  const color: ColorValue =
    conn === "online"
      ? status?.needsAttention
        ? "systemRed"
        : "activeGreen"
      : conn === "offline"
        ? "systemRed"
        : server.isActive
          ? "activeGreen"
          : "systemGrey";

  return (
    <div
      onClick={onClick}
      style={{
        padding: "12px 16px",
        background: status?.needsAttention
          ? withAlpha("systemRed", 0.05)
          : undefined,
        borderBottom: "0.5px solid var(--cupertino-separator)",
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <div style={{ display: "flex", alignItems: "center" }}>
        <div
          style={{
            width: 40,
            height: 40,
            flexShrink: 0,
            borderRadius: 8,
            background: withAlpha(color, 0.1),
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <CupertinoIcon icon="desktopcomputer" color={color} size={24} />
        </div>
        <div style={{ flex: 1, minWidth: 0, marginLeft: 12 }}>
          <div style={{ fontSize: 16, fontWeight: 500 }}>{server.name}</div>
          <div
            style={{
              marginTop: 2,
              fontSize: 14,
              color: "var(--cupertino-system-grey)",
            }}
          >
            {server.baseUrl}
          </div>
        </div>
        <CupertinoIcon icon="chevron_right" color="tertiaryLabel" size={20} />
      </div>
      {status && (
        <div
          style={{
            marginTop: 10,
            paddingLeft: 52,
            paddingRight: conn === "online" ? 8 : 0,
          }}
        >
          {conn === "online" ? (
            <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
              <MiniMetric label="CPU" value={status.cpuUsage} />
              <MiniMetric label="Storage" value={status.storageUsage} />
              {(status.activeAlertCount ?? 0) > 0 && (
                <CupertinoIcon
                  icon="exclamationmark_triangle_fill"
                  size={12}
                  color="systemRed"
                  style={{ marginLeft: -8 }}
                />
              )}
            </div>
          ) : conn === "offline" ? (
            <span
              style={{
                fontSize: 12,
                fontWeight: 500,
                color: "var(--cupertino-system-red)",
              }}
            >
              Offline
            </span>
          ) : (
            <span
              style={{ fontSize: 12, color: "var(--cupertino-tertiary-label)" }}
            >
              Checking…
            </span>
          )}
        </div>
      )}
    </div>
  );
}
