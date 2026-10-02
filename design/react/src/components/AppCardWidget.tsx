import type { ReactNode } from "react";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { cardStyle, formatBytes } from "./shared";

export interface AppPort {
  containerPort: number;
  protocol: string;
  hostPort?: number;
}

export interface AppResourceUsage {
  /** Percent. */
  cpuUsage: number;
  /** Bytes. */
  memoryUsage: number;
  /** Limit in MiB; 0 for none. */
  memoryLimit?: number;
  networkRxBytes?: number;
  networkTxBytes?: number;
  /** e.g. "5s ago". */
  lastUpdatedLabel?: string;
}

export interface TrueNASApp {
  /** Display name, e.g. "Jellyfin". */
  name: string;
  description: string;
  installed: boolean;
  /** Only meaningful when installed; unhealthy apps turn their icon red. */
  healthy?: boolean;
  iconUrl?: string;
  categories?: string[];
  latestAppVersion?: string;
  isFavorite?: boolean;
  resourceUsage?: AppResourceUsage;
  /** Set when an upgrade is available. */
  upgradeVersion?: string;
  customUrl?: string;
  usedPorts?: AppPort[];
  /** Portal name -> URL, e.g. { "Web UI": "http://nas.local:8096" }. */
  portals?: Record<string, string>;
  healthyError?: string;
}

export interface AppIconProps {
  app: Pick<TrueNASApp, "installed" | "healthy" | "iconUrl">;
  /** Edge length in px. Defaults to 44. */
  size?: number;
}

/**
 * An app's icon in a 20%-radius rounded square. Without an `iconUrl` it shows
 * a status glyph: green check (healthy), red alert (unhealthy), blue app
 * square (not installed).
 */
export function AppIcon({ app, size = 44 }: AppIconProps) {
  const tone: ColorValue = app.installed
    ? app.healthy !== false
      ? "systemGreen"
      : "systemRed"
    : "systemBlue";
  const glyph: CupertinoIconName = app.installed
    ? app.healthy !== false
      ? "checkmark_circle"
      : "exclamationmark_circle"
    : "app";
  return (
    <div
      style={{
        width: size,
        height: size,
        flexShrink: 0,
        borderRadius: size * 0.2,
        overflow: "hidden",
        background: withAlpha(tone, 0.1),
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {app.iconUrl ? (
        <img
          src={app.iconUrl}
          width={size}
          height={size}
          alt=""
          style={{ objectFit: "cover", display: "block" }}
        />
      ) : (
        <CupertinoIcon icon={glyph} color={tone} size={size * 0.5} />
      )}
    </div>
  );
}

function Panel({ tint, children }: { tint: ColorValue; children: ReactNode }) {
  return (
    <div
      style={{
        marginTop: 8,
        padding: 8,
        borderRadius: 8,
        background: withAlpha(tint, 0.1),
      }}
    >
      {children}
    </div>
  );
}

function Line({
  icon,
  color,
  children,
}: {
  icon: CupertinoIconName;
  color: ColorValue;
  children: ReactNode;
}) {
  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        minWidth: 0,
        fontSize: 12,
      }}
    >
      <CupertinoIcon icon={icon} size={14} color={color} />
      <span
        style={{
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
        }}
      >
        {children}
      </span>
    </span>
  );
}

export interface AppCardWidgetProps {
  app: TrueNASApp;
  onClick?: () => void;
  onToggleFavorite?: () => void;
  onUpgrade?: () => void;
}

/**
 * An app in the Apps list: icon, name, two-line description, favorite heart
 * and Installed/Available chip; then categories and version, and for
 * installed apps live CPU/memory/network, an upgrade banner, ports & portal
 * links, and any health error.
 */
export function AppCardWidget({
  app,
  onClick,
  onToggleFavorite,
  onUpgrade,
}: AppCardWidgetProps) {
  const usage = app.installed ? app.resourceUsage : undefined;
  const ports = app.usedPorts ?? [];
  const portals = Object.entries(app.portals ?? {});
  const categories = app.categories ?? [];
  return (
    <div
      onClick={onClick}
      style={{ ...cardStyle(), cursor: onClick ? "pointer" : undefined }}
    >
      <div style={{ display: "flex", alignItems: "center" }}>
        <AppIcon app={app} size={50} />
        <div style={{ flex: 1, minWidth: 0, marginLeft: 16 }}>
          <div style={{ fontSize: 18, fontWeight: 600 }}>{app.name}</div>
          <div
            style={{
              marginTop: 4,
              fontSize: 14,
              color: "var(--cupertino-system-grey)",
              display: "-webkit-box",
              WebkitLineClamp: 2,
              WebkitBoxOrient: "vertical",
              overflow: "hidden",
            }}
          >
            {app.description}
          </div>
        </div>
        {app.installed && (
          <button
            type="button"
            aria-label={
              app.isFavorite ? "Remove from favorites" : "Add to favorites"
            }
            onClick={(e) => {
              e.stopPropagation();
              onToggleFavorite?.();
            }}
            style={{
              marginRight: 8,
              padding: 0,
              border: "none",
              background: "transparent",
              cursor: "pointer",
            }}
          >
            <CupertinoIcon
              icon={app.isFavorite ? "heart_fill" : "heart"}
              size={20}
              color={app.isFavorite ? "systemRed" : "systemGrey"}
            />
          </button>
        )}
        <span
          style={{
            padding: "6px 12px",
            borderRadius: 8,
            background: withAlpha(
              app.installed ? "systemGreen" : "systemBlue",
              0.1,
            ),
            color: resolveColor(app.installed ? "systemGreen" : "systemBlue"),
            fontSize: 12,
            fontWeight: 500,
            flexShrink: 0,
          }}
        >
          {app.installed ? "Installed" : "Available"}
        </span>
      </div>

      {(categories.length > 0 || app.latestAppVersion) && (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            marginTop: 12,
            fontSize: 12,
            color: "var(--cupertino-system-grey2)",
          }}
        >
          {categories.length > 0 && (
            <Line icon="tag" color="systemGrey2">
              {categories.slice(0, 2).join(", ")}
            </Line>
          )}
          <span style={{ flex: 1 }} />
          {app.latestAppVersion && (
            <span style={{ fontWeight: 500 }}>v{app.latestAppVersion}</span>
          )}
        </div>
      )}

      {usage && (
        <div
          style={{
            marginTop: 12,
            padding: 8,
            borderRadius: 8,
            background:
              "color-mix(in srgb, var(--cupertino-system-grey6) 50%, transparent)",
          }}
        >
          <div style={{ display: "flex", gap: 16 }}>
            <Line icon="speedometer" color="systemBlue">
              CPU: {usage.cpuUsage.toFixed(1)}%
            </Line>
            <Line icon="memories" color="systemGreen">
              Memory: {formatBytes(usage.memoryUsage)}
              {usage.memoryLimit
                ? ` / ${formatBytes(usage.memoryLimit * 1024 * 1024)}`
                : ""}
            </Line>
          </div>
          {(usage.networkRxBytes || usage.networkTxBytes) && (
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 16,
                marginTop: 4,
              }}
            >
              <Line icon="arrow_down_circle" color="systemOrange">
                RX: {formatBytes(usage.networkRxBytes ?? 0)}
              </Line>
              <Line icon="arrow_up_circle" color="systemOrange">
                TX: {formatBytes(usage.networkTxBytes ?? 0)}
              </Line>
              <span style={{ flex: 1 }} />
              {usage.lastUpdatedLabel && (
                <span
                  style={{
                    fontSize: 10,
                    color: "var(--cupertino-system-grey)",
                  }}
                >
                  {usage.lastUpdatedLabel}
                </span>
              )}
            </div>
          )}
        </div>
      )}

      {app.installed && app.upgradeVersion && (
        <Panel tint="systemYellow">
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <CupertinoIcon
              icon="arrow_up_circle_fill"
              size={14}
              color="systemYellow"
            />
            <span style={{ flex: 1, fontSize: 12 }}>
              Update available: {app.upgradeVersion}
            </span>
            {onUpgrade && (
              <CupertinoButton
                padding="4px 8px"
                minSize={0}
                color="systemYellow"
                style={{ fontSize: 12 }}
                onClick={onUpgrade}
              >
                Upgrade
              </CupertinoButton>
            )}
          </div>
        </Panel>
      )}

      {app.installed && (app.customUrl || ports.length > 0) && (
        <Panel tint="systemBlue">
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              fontSize: 12,
              fontWeight: 600,
            }}
          >
            <CupertinoIcon icon="globe" size={14} color="systemBlue" />
            Ports &amp; Access
          </div>
          <div style={{ marginTop: 4, fontSize: 11 }}>
            {app.customUrl && (
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  padding: 8,
                  marginBottom: 4,
                  borderRadius: 6,
                  background: withAlpha("systemGreen", 0.1),
                  color: "var(--cupertino-system-green)",
                }}
              >
                <CupertinoIcon icon="star_fill" size={12} color="systemGreen" />
                <span style={{ fontWeight: 600 }}>Custom URL:</span>
                <span
                  style={{
                    textDecoration: "underline",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {app.customUrl}
                </span>
              </div>
            )}
            {ports.map((port) => (
              <div
                key={`${port.containerPort}/${port.protocol}`}
                style={{
                  display: "flex",
                  paddingLeft: 22,
                  color: "var(--cupertino-secondary-label)",
                }}
              >
                <span style={{ flex: 1 }}>
                  Port {port.containerPort} ({port.protocol.toUpperCase()})
                </span>
                {port.hostPort != null && <span>Host: {port.hostPort}</span>}
              </div>
            ))}
            {portals.length > 0 && (
              <>
                <div
                  style={{
                    height: 1,
                    margin: "8px 0 4px",
                    background: "var(--cupertino-separator)",
                  }}
                />
                {portals.map(([label, url]) => (
                  <div
                    key={label}
                    style={{
                      paddingLeft: 22,
                      color: "var(--cupertino-system-blue)",
                      textDecoration: "underline",
                    }}
                  >
                    {label}: {url}
                  </div>
                ))}
              </>
            )}
          </div>
        </Panel>
      )}

      {app.installed && app.healthy === false && app.healthyError && (
        <Panel tint="systemRed">
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              fontSize: 12,
              color: "var(--cupertino-system-red)",
            }}
          >
            <CupertinoIcon
              icon="exclamationmark_triangle_fill"
              size={14}
              color="systemRed"
            />
            {app.healthyError}
          </div>
        </Panel>
      )}
    </div>
  );
}
