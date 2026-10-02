import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { ShellBackButton } from "../components/Navigation";
import { SectionCard } from "../components/SectionCard";
import { ErrorStateWidget } from "../components/States";
import { JobsBellButton } from "../components/Status";

export type AlertLevel = "critical" | "error" | "warning" | "info" | "unknown";

export interface HealthAlert {
  message: string;
  level: AlertLevel;
  occurredAt?: Date;
}

export interface HealthDisk {
  /** e.g. "sda". */
  name: string;
  /** SMART result as reported, e.g. "PASSED", "FAILED", "UNKNOWN". */
  health: string;
  /** Celsius; 0 hides the temperature line. */
  temperature: number;
}

export interface HealthService {
  displayName: string;
  isRunning: boolean;
}

export interface ServerHealthScreenProps {
  /** Shown as the back button's caption. */
  serverName: string;
  isLoading?: boolean;
  /** Replaces the page with a retryable error state. */
  error?: string;
  /** Non-dismissed alerts; empty renders "All Systems Operational". */
  activeAlerts?: HealthAlert[];
  disks?: HealthDisk[];
  services?: HealthService[];
  /** Reference time for the alerts' "5m ago" labels. Defaults to now. */
  now?: Date;
  jobsRunningCount?: number;
  jobsNeedAttention?: boolean;
  onBack?: () => void;
  onJobs?: () => void;
  /** The nav-bar refresh button, and Retry on the error state. */
  onRefresh?: () => void;
}

const ALERT_COLOR: Record<AlertLevel, ColorValue> = {
  critical: "systemRed",
  error: "systemOrange",
  warning: "systemYellow",
  info: "systemBlue",
  unknown: "systemBlue",
};

const card = {
  background: "var(--cupertino-system-grey6)",
  borderRadius: 12,
} as const;

/**
 * The server Health screen, pushed from the dashboard's alert banner or Health
 * tile: a summary banner, active alerts, a 2-column disk SMART grid and the
 * running/stopped state of system services.
 */
export function ServerHealthScreen({
  serverName,
  isLoading = false,
  error,
  activeAlerts = [],
  disks = [],
  services = [],
  now,
  jobsRunningCount,
  jobsNeedAttention,
  onBack,
  onJobs,
  onRefresh,
}: ServerHealthScreenProps) {
  let body;
  if (isLoading) {
    body = (
      <div
        style={{
          height: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <CupertinoActivityIndicator />
      </div>
    );
  } else if (error != null) {
    body = (
      <ErrorStateWidget
        title="Could Not Load Health"
        message={error}
        onRetry={onRefresh}
      />
    );
  } else {
    body = (
      <div style={{ padding: 16 }}>
        <SummaryBanner activeAlerts={activeAlerts} />
        {activeAlerts.length > 0 && (
          <>
            <SectionTitle title="Active Alerts" />
            {activeAlerts.map((alert, i) => (
              <div key={i} style={{ marginBottom: 10 }}>
                <AlertCard alert={alert} now={now ?? new Date()} />
              </div>
            ))}
          </>
        )}
        {disks.length > 0 && (
          <>
            <SectionTitle title="Disks" />
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
                gap: 10,
              }}
            >
              {disks.map((disk) => (
                <DiskCard key={disk.name} disk={disk} />
              ))}
            </div>
          </>
        )}
        {services.length > 0 && (
          <div style={{ marginTop: 20 }}>
            <SectionCard title="Services" icon="gear_alt">
              {services.map((service) => (
                <ServiceRow key={service.displayName} service={service} />
              ))}
            </SectionCard>
          </div>
        )}
      </div>
    );
  }

  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          leading={
            <ShellBackButton previousPageTitle={serverName} onClick={onBack} />
          }
          middle="Health"
          trailing={
            <>
              <JobsBellButton
                runningCount={jobsRunningCount}
                needsAttention={jobsNeedAttention}
                onClick={onJobs}
              />
              <CupertinoButton padding={0} minSize={0} onClick={onRefresh}>
                <CupertinoIcon icon="refresh" />
              </CupertinoButton>
            </>
          }
        />
      }
    >
      {body}
    </CupertinoPageScaffold>
  );
}

function SectionTitle({ title }: { title: string }) {
  return (
    <div
      style={{ marginTop: 20, marginBottom: 12, fontSize: 20, fontWeight: 600 }}
    >
      {title}
    </div>
  );
}

function SummaryBanner({ activeAlerts }: { activeAlerts: HealthAlert[] }) {
  const hasAlerts = activeAlerts.length > 0;
  const color: ColorValue = hasAlerts ? "systemRed" : "systemGreen";
  return (
    <div
      style={{
        ...card,
        padding: 16,
        border: `0.5px solid ${withAlpha(color, 0.35)}`,
        display: "flex",
        alignItems: "center",
        gap: 14,
      }}
    >
      <CupertinoIcon
        icon={
          hasAlerts ? "exclamationmark_triangle_fill" : "checkmark_shield_fill"
        }
        color={color}
        size={32}
      />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div
          style={{
            fontSize: 17,
            fontWeight: 600,
            color: resolveColor(color),
          }}
        >
          {hasAlerts
            ? `${activeAlerts.length} active ${activeAlerts.length === 1 ? "alert" : "alerts"}`
            : "All Systems Operational"}
        </div>
        {hasAlerts && (
          <div
            style={{
              marginTop: 2,
              fontSize: 13,
              color: "var(--cupertino-secondary-label)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {activeAlerts[0].message}
          </div>
        )}
      </div>
    </div>
  );
}

function formatRelativeTime(date: Date, now: Date): string {
  const minutes = Math.floor((now.getTime() - date.getTime()) / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

function AlertCard({ alert, now }: { alert: HealthAlert; now: Date }) {
  return (
    <div
      style={{
        ...card,
        border: "0.5px solid var(--cupertino-separator)",
        overflow: "hidden",
        display: "flex",
      }}
    >
      <div
        style={{
          width: 4,
          flexShrink: 0,
          background: resolveColor(ALERT_COLOR[alert.level]),
        }}
      />
      <div style={{ flex: 1, minWidth: 0, padding: 12 }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{alert.message}</div>
        {alert.occurredAt && (
          <div
            style={{
              marginTop: 6,
              fontSize: 11,
              color: "var(--cupertino-tertiary-label)",
            }}
          >
            {formatRelativeTime(alert.occurredAt, now)}
          </div>
        )}
      </div>
    </div>
  );
}

function diskHealthColor(health: string): ColorValue {
  const normalized = health.toUpperCase();
  if (normalized.includes("FAIL")) return "systemRed";
  if (["PASSED", "HEALTHY", "OK"].includes(normalized)) return "systemGreen";
  return "systemGrey";
}

function DiskCard({ disk }: { disk: HealthDisk }) {
  const color = diskHealthColor(disk.health);
  const solid = resolveColor(color);
  return (
    <div
      style={{
        ...card,
        aspectRatio: "2.4",
        boxSizing: "border-box",
        padding: 12,
        border: `0.5px solid ${withAlpha(color, 0.35)}`,
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
        <span
          style={{
            width: 7,
            height: 7,
            flexShrink: 0,
            borderRadius: "50%",
            background: solid,
          }}
        />
        <span
          style={{
            flex: 1,
            minWidth: 0,
            fontSize: 13,
            fontWeight: 600,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {disk.name}
        </span>
      </div>
      <div style={{ marginTop: 4, fontSize: 11, color: solid }}>
        {disk.health}
      </div>
      {disk.temperature > 0 && (
        <div
          style={{
            marginTop: 2,
            fontSize: 11,
            color: "var(--cupertino-tertiary-label)",
          }}
        >
          {disk.temperature}°C
        </div>
      )}
    </div>
  );
}

function ServiceRow({ service }: { service: HealthService }) {
  const color = service.isRunning
    ? "var(--cupertino-system-green)"
    : "var(--cupertino-system-grey)";
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 10,
        paddingBottom: 8,
      }}
    >
      <span
        style={{
          width: 7,
          height: 7,
          flexShrink: 0,
          borderRadius: "50%",
          background: color,
        }}
      />
      <span style={{ flex: 1, minWidth: 0, fontSize: 14 }}>
        {service.displayName}
      </span>
      <span style={{ fontSize: 12, fontWeight: 500, color }}>
        {service.isRunning ? "Running" : "Stopped"}
      </span>
    </div>
  );
}
