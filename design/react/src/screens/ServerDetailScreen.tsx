import type { ReactNode } from "react";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import {
  CupertinoActionSheet,
  CupertinoActionSheetAction,
  CupertinoPageScaffold,
} from "../primitives/Forms";
import { AppCardWidget, type TrueNASApp } from "../components/AppCardWidget";
import { SectionHeader } from "../components/Layout";
import { ShellBackButton } from "../components/Navigation";
import { PoolCardWidget, type Pool } from "../components/PoolCardWidget";
import { cardStyle } from "../components/shared";
import {
  AuthenticationStateWidget,
  EmptyStateWidget,
  ErrorStateWidget,
  LoadingStateWidget,
  type AuthenticationState,
} from "../components/States";
import {
  ConnectionStatusTitleWidget,
  JobsBellButton,
  type TrueNASConnectionState,
} from "../components/Status";
import {
  SystemStatsWidget,
  type SystemStatsWidgetProps,
} from "../components/SystemStats";
import type { HealthAlert } from "./ServerHealthScreen";

export interface ServerDetailScreenProps {
  serverName: string;
  connectionState?: TrueNASConnectionState;
  connectionHealthy?: boolean;
  /** Anything but `authenticated` (the default) replaces the dashboard with the lock/spinner screen. */
  authState?: AuthenticationState;
  authError?: string;

  /** Non-empty shows the red banner at the top and flags the Health tile. */
  activeAlerts?: HealthAlert[];

  /** Data for the System Stats block, including its loading/error/empty states. */
  systemStats?: SystemStatsWidgetProps;
  /** Live stats streaming: the header shows pause while subscribed, play otherwise. */
  statsSubscribed?: boolean;

  pools?: Pool[];
  poolsLoading?: boolean;
  poolsError?: string;

  /** Catalog and installed apps; `installed`, `upgradeVersion` and `isFavorite` drive the overview counts and favorites list. */
  apps?: TrueNASApp[];
  appsLoading?: boolean;
  appsError?: string;
  /** Second line under `appsError`. */
  appsErrorDetails?: string;

  jobsRunningCount?: number;
  /** A recent job failed: red dot on the bell and red Jobs tile subtitle. */
  jobsNeedAttention?: boolean;

  /** Shows the ellipsis menu's action sheet (Edit Server / Cancel). */
  showServerMenu?: boolean;

  onBack?: () => void;
  onConnectionStatus?: () => void;
  onProfile?: () => void;
  onJobs?: () => void;
  onServerMenu?: () => void;
  onEditServer?: () => void;
  onDismissServerMenu?: () => void;
  onAuthenticate?: () => void;
  onToggleStats?: () => void;
  onPools?: () => void;
  onPoolClick?: (pool: Pool) => void;
  onApps?: () => void;
  onAppClick?: (app: TrueNASApp) => void;
  onToggleFavorite?: (app: TrueNASApp) => void;
  onFiles?: () => void;
  onHealth?: () => void;
}

/**
 * The server dashboard, shown after picking a server from the Servers list:
 * an active-alerts banner, live system stats, storage pools, an apps
 * overview with favorites, and quick-action tiles for Pools, Files, Health
 * and Jobs.
 */
export function ServerDetailScreen({
  serverName,
  connectionState = "connected",
  connectionHealthy = true,
  authState = "authenticated",
  authError,
  activeAlerts = [],
  systemStats = {},
  statsSubscribed = true,
  pools = [],
  poolsLoading = false,
  poolsError,
  apps = [],
  appsLoading = false,
  appsError,
  appsErrorDetails,
  jobsRunningCount = 0,
  jobsNeedAttention = false,
  showServerMenu = false,
  onBack,
  onConnectionStatus,
  onProfile,
  onJobs,
  onServerMenu,
  onEditServer,
  onDismissServerMenu,
  onAuthenticate,
  onToggleStats,
  onPools,
  onPoolClick,
  onApps,
  onAppClick,
  onToggleFavorite,
  onFiles,
  onHealth,
}: ServerDetailScreenProps) {
  const viewAll = (onClick?: () => void) => (
    <CupertinoButton padding={0} minSize={0} onClick={onClick}>
      View All
    </CupertinoButton>
  );

  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          leading={
            <ShellBackButton previousPageTitle="Servers" onClick={onBack} />
          }
          middle={
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                minWidth: 0,
                maxWidth: 260,
              }}
            >
              <ConnectionStatusTitleWidget
                state={connectionState}
                isHealthy={connectionHealthy}
                onClick={onConnectionStatus}
              />
              <CupertinoButton padding={0} minSize={0} onClick={onProfile}>
                <CupertinoIcon icon="person_circle" size={20} />
              </CupertinoButton>
              <span
                style={{
                  flex: 1,
                  minWidth: 0,
                  textAlign: "center",
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                }}
              >
                {serverName}
              </span>
            </div>
          }
          trailing={
            <>
              <JobsBellButton
                runningCount={jobsRunningCount}
                needsAttention={jobsNeedAttention}
                onClick={onJobs}
              />
              <CupertinoButton padding={0} minSize={0} onClick={onServerMenu}>
                <CupertinoIcon icon="ellipsis" />
              </CupertinoButton>
            </>
          }
        />
      }
    >
      <AuthenticationStateWidget
        state={authState}
        error={authError}
        serverName={serverName}
        onAuthenticate={onAuthenticate}
      >
        <div style={{ paddingTop: 20 }}>
          {activeAlerts.length > 0 && (
            <AlertBanner activeAlerts={activeAlerts} onClick={onHealth} />
          )}

          <Section>
            <SectionHeader
              title="System Stats"
              action={
                <CupertinoButton
                  padding={0}
                  minSize={0}
                  onClick={onToggleStats}
                >
                  <CupertinoIcon
                    icon={statsSubscribed ? "pause_circle" : "play_circle"}
                  />
                </CupertinoButton>
              }
            />
            <div style={{ height: 12 }} />
            <SystemStatsWidget {...systemStats} />
          </Section>

          <div style={{ height: 20 }} />
          <Section>
            <SectionHeader title="Storage Pools" action={viewAll(onPools)} />
            <div style={{ height: 12 }} />
            {poolsLoading ? (
              <LoadingStateWidget message="Loading pools..." />
            ) : poolsError != null ? (
              <ErrorStateWidget
                title="Pool Error"
                message={`Failed to load pools: ${poolsError}`}
              />
            ) : pools.length === 0 ? (
              <EmptyStateWidget
                icon="square_stack_3d_down_right"
                title="No Pools"
                message="No storage pools found"
              />
            ) : (
              pools.map((pool) => (
                <div key={pool.name} style={{ marginBottom: 12 }}>
                  <PoolCardWidget
                    pool={pool}
                    onClick={onPoolClick && (() => onPoolClick(pool))}
                  />
                </div>
              ))
            )}
          </Section>

          <div style={{ height: 20 }} />
          <Section>
            <SectionHeader title="Apps" action={viewAll(onApps)} />
            <div style={{ height: 12 }} />
            {appsLoading ? (
              <LoadingStateWidget message="Loading apps..." />
            ) : appsError != null ? (
              <div style={{ whiteSpace: "pre-line" }}>
                <ErrorStateWidget
                  title="App Error"
                  message={
                    appsErrorDetails == null
                      ? `Failed to load apps: ${appsError}`
                      : `Failed to load apps: ${appsError}\n${appsErrorDetails}`
                  }
                />
              </div>
            ) : apps.length === 0 ? (
              <EmptyStateWidget
                icon="app"
                title="No Apps"
                message="No apps found"
              />
            ) : (
              <>
                <AppsSummaryCard apps={apps} onClick={onApps} />
                <div style={{ height: 16 }} />
                <FavoriteApps
                  apps={apps}
                  onAppClick={onAppClick}
                  onToggleFavorite={onToggleFavorite}
                />
              </>
            )}
          </Section>

          <div style={{ height: 30 }} />
          <div
            style={{
              padding: "0 16px",
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(120px, 1fr))",
              gap: 12,
            }}
          >
            <QuickActionTile
              icon="square_stack_3d_down_right"
              title="Pools"
              subtitle={pools.length === 1 ? "1 pool" : `${pools.length} pools`}
              onClick={onPools}
            />
            <QuickActionTile
              icon="folder"
              title="Files"
              subtitle="Browse"
              onClick={onFiles}
            />
            <QuickActionTile
              icon="heart"
              title="Health"
              subtitle={
                activeAlerts.length === 0
                  ? "All clear"
                  : `${activeAlerts.length} active`
              }
              subtitleColor={
                activeAlerts.length === 0 ? "systemGreen" : "systemRed"
              }
              showAlertDot={activeAlerts.length > 0}
              onClick={onHealth}
            />
            <QuickActionTile
              icon="bell"
              title="Jobs"
              subtitle={
                jobsRunningCount === 0
                  ? "None running"
                  : `${jobsRunningCount} running`
              }
              subtitleColor={jobsNeedAttention ? "systemRed" : undefined}
              showAlertDot={jobsNeedAttention}
              onClick={onJobs}
            />
          </div>
        </div>
      </AuthenticationStateWidget>

      {showServerMenu && (
        <ModalPopup onDismiss={onDismissServerMenu}>
          <CupertinoActionSheet
            actions={[
              <CupertinoActionSheetAction key="edit" onClick={onEditServer}>
                Edit Server
              </CupertinoActionSheetAction>,
            ]}
            cancelButton={
              <CupertinoActionSheetAction
                isDefaultAction
                onClick={onDismissServerMenu}
              >
                Cancel
              </CupertinoActionSheetAction>
            }
          />
        </ModalPopup>
      )}
    </CupertinoPageScaffold>
  );
}

function Section({ children }: { children: ReactNode }) {
  return <div style={{ margin: "0 16px" }}>{children}</div>;
}

/** `showCupertinoModalPopup`'s dimmed barrier with the popup pinned to the bottom. */
function ModalPopup({
  children,
  onDismiss,
}: {
  children: ReactNode;
  onDismiss?: () => void;
}) {
  return (
    <div
      onClick={onDismiss}
      style={{
        position: "fixed",
        inset: 0,
        display: "flex",
        flexDirection: "column",
        justifyContent: "flex-end",
        background: "rgba(0,0,0,0.2)",
        zIndex: 1000,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ width: "100%", maxWidth: 520, margin: "0 auto" }}
      >
        {children}
      </div>
    </div>
  );
}

function AlertBanner({
  activeAlerts,
  onClick,
}: {
  activeAlerts: HealthAlert[];
  onClick?: () => void;
}) {
  return (
    <div style={{ padding: "0 16px 20px" }}>
      <div
        onClick={onClick}
        style={{
          padding: 14,
          borderRadius: 12,
          background: withAlpha("systemRed", 0.08),
          display: "flex",
          alignItems: "center",
          gap: 12,
          cursor: onClick ? "pointer" : undefined,
        }}
      >
        <CupertinoIcon
          icon="exclamationmark_triangle_fill"
          color="systemRed"
          size={22}
        />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div
            style={{
              fontSize: 14,
              fontWeight: 600,
              color: "var(--cupertino-system-red)",
            }}
          >
            {activeAlerts.length} active{" "}
            {activeAlerts.length === 1 ? "alert" : "alerts"}
          </div>
          <div
            style={{
              marginTop: 1,
              fontSize: 12,
              color: "var(--cupertino-secondary-label)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {activeAlerts[0].message}
          </div>
        </div>
        <CupertinoIcon icon="chevron_right" color="tertiaryLabel" size={16} />
      </div>
    </div>
  );
}

function AppsSummaryCard({
  apps,
  onClick,
}: {
  apps: TrueNASApp[];
  onClick?: () => void;
}) {
  const installed = apps.filter((app) => app.installed);
  const available = apps.length - installed.length;
  const updates = installed.filter((app) => app.upgradeVersion != null).length;
  return (
    <div
      onClick={onClick}
      style={{ ...cardStyle(), cursor: onClick ? "pointer" : undefined }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <CupertinoIcon icon="app_badge" color="systemBlue" size={24} />
        <div style={{ flex: 1, minWidth: 0, fontSize: 18, fontWeight: 600 }}>
          Apps Overview
        </div>
        <CupertinoIcon icon="chevron_right" color="systemGrey" size={16} />
      </div>
      <div style={{ display: "flex", gap: 16, marginTop: 16 }}>
        <AppStat
          icon="checkmark_circle_fill"
          color="systemGreen"
          count={installed.length}
          label="Installed"
        />
        <AppStat
          icon="arrow_up_circle_fill"
          color={updates > 0 ? "systemYellow" : "systemGrey"}
          count={updates}
          label="Updates"
        />
        <AppStat
          icon="square_grid_2x2"
          color="systemBlue"
          count={available}
          label="Available"
        />
      </div>
      {updates > 0 && (
        <div
          style={{
            marginTop: 12,
            padding: 8,
            borderRadius: 6,
            background: withAlpha("systemYellow", 0.1),
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          <CupertinoIcon
            icon="exclamationmark_triangle"
            color="systemYellow"
            size={14}
          />
          <span
            style={{
              flex: 1,
              minWidth: 0,
              fontSize: 12,
              color: "var(--cupertino-label)",
            }}
          >
            {updates} app{updates === 1 ? "" : "s"}{" "}
            {updates === 1 ? "has" : "have"} updates available
          </span>
        </div>
      )}
    </div>
  );
}

function AppStat({
  icon,
  color,
  count,
  label,
}: {
  icon: CupertinoIconName;
  color: ColorValue;
  count: number;
  label: string;
}) {
  return (
    <div
      style={{
        flex: 1,
        minWidth: 0,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
      }}
    >
      <CupertinoIcon icon={icon} color={color} size={20} />
      <div style={{ marginTop: 4, fontSize: 18, fontWeight: 600 }}>{count}</div>
      <div
        style={{
          marginTop: 2,
          fontSize: 12,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {label}
      </div>
    </div>
  );
}

function FavoriteApps({
  apps,
  onAppClick,
  onToggleFavorite,
}: {
  apps: TrueNASApp[];
  onAppClick?: (app: TrueNASApp) => void;
  onToggleFavorite?: (app: TrueNASApp) => void;
}) {
  const favorites = apps.filter((app) => app.isFavorite).slice(0, 3);
  if (favorites.length === 0) return null;
  return (
    <>
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 4,
          paddingBottom: 8,
        }}
      >
        <CupertinoIcon icon="heart_fill" color="systemRed" size={16} />
        <span
          style={{
            fontSize: 16,
            fontWeight: 500,
            color: "var(--cupertino-system-grey)",
          }}
        >
          Favorite Apps
        </span>
      </div>
      {favorites.map((app) => (
        <div key={app.name} style={{ marginBottom: 12 }}>
          <AppCardWidget
            app={app}
            onClick={onAppClick && (() => onAppClick(app))}
            onToggleFavorite={onToggleFavorite && (() => onToggleFavorite(app))}
          />
        </div>
      ))}
    </>
  );
}

/**
 * A compact, icon-led quick-action card; four sit side by side on wide
 * screens and wrap two-up on phones.
 */
function QuickActionTile({
  icon,
  title,
  subtitle,
  subtitleColor,
  showAlertDot = false,
  onClick,
}: {
  icon: CupertinoIconName;
  title: string;
  subtitle: string;
  subtitleColor?: ColorValue;
  showAlertDot?: boolean;
  onClick?: () => void;
}) {
  return (
    <div
      onClick={onClick}
      style={{
        ...cardStyle(),
        padding: 14,
        position: "relative",
        minWidth: 0,
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <CupertinoIcon icon={icon} color="activeBlue" size={22} />
      <div style={{ marginTop: 8, fontSize: 15, fontWeight: 600 }}>{title}</div>
      <div
        style={{
          marginTop: 2,
          fontSize: 11,
          fontWeight: subtitleColor ? 500 : 400,
          color: subtitleColor
            ? resolveColor(subtitleColor)
            : "var(--cupertino-system-grey)",
          whiteSpace: "nowrap",
          overflow: "hidden",
          textOverflow: "ellipsis",
        }}
      >
        {subtitle}
      </div>
      {showAlertDot && (
        <span
          style={{
            position: "absolute",
            top: 14,
            right: 14,
            width: 8,
            height: 8,
            borderRadius: "50%",
            background: "var(--cupertino-system-red)",
          }}
        />
      )}
    </div>
  );
}
