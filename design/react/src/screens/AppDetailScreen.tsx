import { useState, type ReactNode } from "react";
import { resolveColor, withAlpha } from "../colors";
import { AppIcon, type TrueNASApp } from "../components/AppCardWidget";
import { AppStateBadge } from "../components/AppStateBadge";
import { ShellBackButton } from "../components/Navigation";
import {
  CupertinoAlertDialog,
  CupertinoDialogAction,
} from "../primitives/CupertinoAlertDialog";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import {
  CupertinoActionSheet,
  CupertinoActionSheetAction,
  CupertinoPageScaffold,
} from "../primitives/Forms";

export interface AppMaintainer {
  name: string;
  email?: string;
}

/** A catalog/installed app with the store-page details the detail screen shows. */
export interface AppDetail extends TrueNASApp {
  /** User-set display name; falls back to `name`. */
  displayName?: string;
  /** e.g. "10.9.11"; preferred over `latestAppVersion` for the header. */
  latestHumanVersion?: string;
  screenshots?: string[];
  /** HTML readme; tags are stripped and shown as plain text under "Details". */
  appReadme?: string;
  tags?: string[];
  catalog?: string;
  train?: string;
  /** Relative label, e.g. "3 days ago" or "Recently". */
  lastUpdatedLabel?: string;
  maintainers?: AppMaintainer[];
  /** Source repository URLs. */
  sources?: string[];
  /** Homepage URL; adds "View Homepage". */
  home?: string;
}

/** The start/stop/restart/upgrade entries of the "..." action sheet. */
export type AppLifecycleAction = "start" | "stop" | "restart" | "upgrade";

const LIFECYCLE_LABELS: Record<AppLifecycleAction, string> = {
  start: "Start",
  stop: "Stop",
  restart: "Restart",
  upgrade: "Upgrade",
};

/** The lifecycle actions that make sense for `app` right now, in menu order. */
function availableLifecycleActions(app: AppDetail): AppLifecycleAction[] {
  if (!app.installed) return [];
  const state = app.state ?? "unknown";
  const actions: AppLifecycleAction[] = [];
  if (state === "stopped" || state === "crashed") actions.push("start");
  if (state === "running" || state === "deploying" || state === "crashed") {
    actions.push("stop");
  }
  if (state === "running") actions.push("restart");
  if (app.upgradeVersion) actions.push("upgrade");
  return actions;
}

/** Same check as the app's `isWebUrl`: http(s) with a host. */
function isWebUrl(url: string) {
  try {
    const { protocol, hostname } = new URL(url);
    return (protocol === "http:" || protocol === "https:") && hostname !== "";
  } catch {
    return false;
  }
}

export interface AppDetailScreenProps {
  app: AppDetail;
  /** Index of the screenshot in the large preview. Defaults to 0. */
  selectedScreenshot?: number;
  /** Screenshot indices that failed to load and show the "unavailable" placeholder. */
  unavailableScreenshots?: number[];
  /** Show the "..." action sheet over the screen. */
  showActions?: boolean;
  /** Show the "App configuration not found" alert (Edit Configuration with no stored config). */
  showConfigNotFoundError?: boolean;
  /** Show the "Couldn't Open Link" alert for this URL (homepage or source that failed to open). */
  openLinkError?: string;
  onBack?: () => void;
  /** The nav bar "..." button. */
  onShowActions?: () => void;
  onDismissActions?: () => void;
  onSelectScreenshot?: (index: number) => void;
  /** A Start/Stop/Restart/Upgrade entry in the action sheet. */
  onLifecycleAction?: (action: AppLifecycleAction) => void;
  onEditConfiguration?: () => void;
  onToggleFavorite?: () => void;
  onOpenHomepage?: () => void;
  onViewSources?: () => void;
  onOpenSource?: (url: string) => void;
  onDismissError?: () => void;
  onDismissLinkError?: () => void;
}

/**
 * An app's store-style detail page: icon header with version and running-state
 * chip, screenshots, description and readme, catalog information, maintainers,
 * source links (non-web sources show as plain text) and a "View Homepage"
 * button. The "..." sheet adds lifecycle actions for installed apps. Pushed
 * when an app card is tapped in the Apps screen.
 */
export function AppDetailScreen({
  app,
  selectedScreenshot = 0,
  unavailableScreenshots = [],
  showActions = false,
  showConfigNotFoundError = false,
  openLinkError,
  onBack,
  onShowActions,
  onDismissActions,
  onSelectScreenshot,
  onLifecycleAction,
  onEditConfiguration,
  onToggleFavorite,
  onOpenHomepage,
  onViewSources,
  onOpenSource,
  onDismissError,
  onDismissLinkError,
}: AppDetailScreenProps) {
  const title = app.displayName ?? app.name;
  const screenshots = app.screenshots ?? [];
  const maintainers = app.maintainers ?? [];
  const sources = app.sources ?? [];
  const lifecycleActions = availableLifecycleActions(app);
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={title}
          leading={<ShellBackButton onClick={onBack} />}
          trailing={
            <CupertinoButton padding={0} minSize={0} onClick={onShowActions}>
              <CupertinoIcon icon="ellipsis" />
            </CupertinoButton>
          }
        />
      }
    >
      <div
        style={{
          padding: 16,
          display: "flex",
          flexDirection: "column",
          gap: 24,
        }}
      >
        <AppHeader app={app} title={title} />
        {screenshots.length > 0 && (
          <Screenshots
            urls={screenshots}
            selected={selectedScreenshot}
            unavailable={unavailableScreenshots}
            onSelect={onSelectScreenshot}
          />
        )}
        <Section title="Description">
          <div style={{ fontSize: 16, lineHeight: 1.4 }}>{app.description}</div>
          {app.appReadme && (
            <>
              <div style={{ marginTop: 16, fontSize: 18, fontWeight: 600 }}>
                Details
              </div>
              <div
                style={{
                  marginTop: 8,
                  padding: 16,
                  borderRadius: 12,
                  background: "var(--cupertino-system-grey6)",
                  fontSize: 14,
                  lineHeight: 1.4,
                  whiteSpace: "pre-wrap",
                }}
              >
                {readmeText(app.appReadme)}
              </div>
            </>
          )}
        </Section>
        <Information app={app} />
        {maintainers.length > 0 && (
          <Section title="Maintainers">
            {maintainers.map((m, i) => (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  marginBottom: 8,
                  padding: 12,
                  borderRadius: 8,
                  background: "var(--cupertino-system-grey6)",
                }}
              >
                <CupertinoIcon icon="person_circle" color="systemGrey" />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 16, fontWeight: 500 }}>{m.name}</div>
                  {m.email && (
                    <div
                      style={{
                        fontSize: 14,
                        color: "var(--cupertino-system-grey)",
                      }}
                    >
                      {m.email}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </Section>
        )}
        {sources.length > 0 && (
          <Section title="Sources">
            {sources.map((url) =>
              isWebUrl(url) ? (
                <button
                  key={url}
                  type="button"
                  className="cupertino-button"
                  onClick={() => onOpenSource?.(url)}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                    width: "100%",
                    marginBottom: 8,
                    padding: 12,
                    border: "none",
                    borderRadius: 8,
                    background: withAlpha("systemBlue", 0.1),
                    color: resolveColor("systemBlue"),
                    font: "inherit",
                    fontSize: 14,
                    textAlign: "left",
                    cursor: "pointer",
                  }}
                >
                  <CupertinoIcon icon="link" size={20} color="systemBlue" />
                  <span
                    style={{ flex: 1, minWidth: 0, overflowWrap: "anywhere" }}
                  >
                    {url}
                  </span>
                  <CupertinoIcon
                    icon="arrow_up_right"
                    size={16}
                    color="systemBlue"
                  />
                </button>
              ) : (
                <div
                  key={url}
                  style={{
                    marginBottom: 8,
                    padding: 12,
                    borderRadius: 8,
                    background: withAlpha("systemGrey", 0.1),
                    color: "var(--cupertino-secondary-label)",
                    fontSize: 14,
                    overflowWrap: "anywhere",
                  }}
                >
                  {url}
                </div>
              ),
            )}
          </Section>
        )}
        {app.home && (
          <CupertinoButton onClick={onOpenHomepage} style={{ width: "100%" }}>
            View Homepage
          </CupertinoButton>
        )}
        <div style={{ height: 8 }} />
      </div>

      {showActions && (
        <Overlay onDismiss={onDismissActions} align="flex-end">
          <CupertinoActionSheet
            title={title}
            actions={[
              ...lifecycleActions.map((action) => (
                <CupertinoActionSheetAction
                  key={action}
                  isDestructiveAction={action === "stop"}
                  onClick={() => onLifecycleAction?.(action)}
                >
                  {LIFECYCLE_LABELS[action]}
                </CupertinoActionSheetAction>
              )),
              ...(app.installed
                ? [
                    <CupertinoActionSheetAction onClick={onEditConfiguration}>
                      Edit Configuration
                    </CupertinoActionSheetAction>,
                  ]
                : []),
              <CupertinoActionSheetAction onClick={onToggleFavorite}>
                {app.isFavorite ? "Remove from Favorites" : "Add to Favorites"}
              </CupertinoActionSheetAction>,
              ...(app.home
                ? [
                    <CupertinoActionSheetAction onClick={onOpenHomepage}>
                      View Homepage
                    </CupertinoActionSheetAction>,
                  ]
                : []),
              ...(sources.length > 0
                ? [
                    <CupertinoActionSheetAction onClick={onViewSources}>
                      View Sources
                    </CupertinoActionSheetAction>,
                  ]
                : []),
            ]}
            cancelButton={
              <CupertinoActionSheetAction
                isDefaultAction
                onClick={onDismissActions}
              >
                Cancel
              </CupertinoActionSheetAction>
            }
          />
        </Overlay>
      )}

      {showConfigNotFoundError && (
        <Overlay align="center">
          <CupertinoAlertDialog
            title="Error"
            content="App configuration not found. Please try refreshing the app list."
            actions={[
              <CupertinoDialogAction onClick={onDismissError}>
                OK
              </CupertinoDialogAction>,
            ]}
          />
        </Overlay>
      )}

      {openLinkError && (
        <Overlay align="center">
          <CupertinoAlertDialog
            title="Couldn't Open Link"
            content={openLinkError}
            actions={[
              <CupertinoDialogAction
                isDefaultAction
                onClick={onDismissLinkError}
              >
                OK
              </CupertinoDialogAction>,
            ]}
          />
        </Overlay>
      )}
    </CupertinoPageScaffold>
  );
}

/** The dimmed modal barrier behind a popup (`showCupertinoModalPopup` / `showCupertinoDialog`). */
function Overlay({
  align,
  onDismiss,
  children,
}: {
  align: "center" | "flex-end";
  onDismiss?: () => void;
  children: ReactNode;
}) {
  return (
    <div
      onClick={onDismiss}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 1000,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: align,
        background: "rgba(0,0,0,0.2)",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ width: "100%", maxWidth: align === "center" ? 270 : 500 }}
      >
        {children}
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div>
      <div style={{ fontSize: 20, fontWeight: 600, marginBottom: 12 }}>
        {title}
      </div>
      {children}
    </div>
  );
}

function AppHeader({ app, title }: { app: AppDetail; title: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <AppIcon app={app} size={80} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 24, fontWeight: 700 }}>{title}</div>
        <div
          style={{
            marginTop: 4,
            fontSize: 16,
            color: "var(--cupertino-system-grey)",
          }}
        >
          v{app.latestHumanVersion || app.latestAppVersion || ""}
        </div>
        <div style={{ display: "flex", marginTop: 8 }}>
          <AppStateBadge app={app} />
        </div>
      </div>
    </div>
  );
}

function Screenshots({
  urls,
  selected,
  unavailable,
  onSelect,
}: {
  urls: string[];
  selected: number;
  unavailable: number[];
  onSelect?: (index: number) => void;
}) {
  return (
    <Section title="Screenshots">
      <div
        style={{
          height: 200,
          borderRadius: 12,
          overflow: "hidden",
          background: "var(--cupertino-system-grey6)",
        }}
      >
        <Screenshot
          key={urls[selected]}
          url={urls[selected]}
          unavailable={unavailable.includes(selected)}
          placeholder={
            <div
              style={{
                height: "100%",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 8,
                color: "var(--cupertino-system-grey)",
              }}
            >
              <CupertinoIcon icon="photo" size={48} color="systemGrey" />
              Screenshot unavailable
            </div>
          }
        />
      </div>
      {urls.length > 1 && (
        <div
          style={{
            marginTop: 12,
            height: 60,
            display: "flex",
            gap: 8,
            overflowX: "auto",
          }}
        >
          {urls.map((url, i) => {
            const isSelected = i === selected;
            return (
              <button
                key={url}
                type="button"
                onClick={() => onSelect?.(i)}
                style={{
                  width: 80,
                  height: 60,
                  flexShrink: 0,
                  boxSizing: "border-box",
                  padding: 0,
                  borderRadius: 8,
                  overflow: "hidden",
                  border: isSelected
                    ? "2px solid var(--cupertino-system-blue)"
                    : "1px solid var(--cupertino-separator)",
                  background: "transparent",
                  cursor: "pointer",
                }}
              >
                <Screenshot
                  url={url}
                  unavailable={unavailable.includes(i)}
                  placeholder={
                    <div
                      style={{
                        height: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        background: "var(--cupertino-system-grey6)",
                      }}
                    >
                      <CupertinoIcon icon="photo" color="systemGrey" />
                    </div>
                  }
                />
              </button>
            );
          })}
        </div>
      )}
    </Section>
  );
}

/** A cover-fit image that swaps to `placeholder` when flagged or when it fails to load. */
function Screenshot({
  url,
  unavailable,
  placeholder,
}: {
  url: string;
  unavailable: boolean;
  placeholder: ReactNode;
}) {
  const [failed, setFailed] = useState(false);
  if (unavailable || failed) return <>{placeholder}</>;
  return (
    <img
      src={url}
      alt=""
      onError={() => setFailed(true)}
      style={{
        width: "100%",
        height: "100%",
        objectFit: "cover",
        display: "block",
      }}
    />
  );
}

function Information({ app }: { app: AppDetail }) {
  const tags = app.tags ?? [];
  return (
    <Section title="Information">
      <div
        style={{
          padding: 16,
          borderRadius: 12,
          background: "var(--cupertino-system-grey6)",
          display: "flex",
          flexDirection: "column",
          gap: 12,
        }}
      >
        <DetailRow label="Category" value={(app.categories ?? []).join(", ")} />
        {tags.length > 0 && <DetailRow label="Tags" value={tags.join(", ")} />}
        <DetailRow label="Catalog" value={app.catalog ?? ""} />
        <DetailRow label="Train" value={app.train ?? ""} />
        {app.lastUpdatedLabel && (
          <DetailRow label="Last Updated" value={app.lastUpdatedLabel} />
        )}
        {app.installed && app.healthy === false && app.healthyError && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 8,
              padding: 12,
              borderRadius: 8,
              background: withAlpha("systemRed", 0.1),
              color: resolveColor("systemRed"),
              fontSize: 14,
            }}
          >
            <CupertinoIcon
              icon="exclamationmark_triangle_fill"
              size={16}
              color="systemRed"
            />
            <span style={{ flex: 1 }}>{app.healthyError}</span>
          </div>
        )}
      </div>
    </Section>
  );
}

/** The detail page's own 100px-label row (narrower than the shared `InfoRow`). */
function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", alignItems: "flex-start", fontSize: 14 }}>
      <div
        style={{
          width: 100,
          flexShrink: 0,
          fontWeight: 500,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {label}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>{value || "Not specified"}</div>
    </div>
  );
}

function readmeText(html: string) {
  return html
    .replace(/<[^>]*>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}
