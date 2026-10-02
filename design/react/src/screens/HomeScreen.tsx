import { withAlpha } from "../colors";
import {
  ServerListTile,
  type FleetServerStatus,
  type NasServer,
} from "../components/ServerListTile";
import { EmptyStateWidget, LoadingStateWidget } from "../components/States";
import {
  AppLogo,
  SessionIndicatorWidget,
  type SessionIndicatorWidgetProps,
} from "../components/Status";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";

export interface HomeServerEntry {
  id: string;
  server: NasServer;
  /** Fleet health snapshot; entries with `needsAttention` sort to the top. */
  status?: FleetServerStatus;
}

export interface HomeScreenProps {
  /** In list order as loaded; the screen moves servers needing attention to the top. */
  servers: HomeServerEntry[];
  /** Shows "Loading servers..." instead of the list. */
  isLoading?: boolean;
  /** The unlocked biometric session shown next to the title; omit when the session is locked. */
  session?: SessionIndicatorWidgetProps;
  onAddServer?: () => void;
  onServerSelected?: (id: string) => void;
}

const fill = {
  height: "100%",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
} as const;

function FleetBanner({
  needsAttention,
}: {
  needsAttention: HomeServerEntry[];
}) {
  if (needsAttention.length === 0) return null;
  return (
    <div
      style={{
        margin: "12px 16px 4px",
        padding: 14,
        borderRadius: 12,
        background: withAlpha("systemRed", 0.08),
        display: "flex",
        alignItems: "center",
        gap: 10,
      }}
    >
      <CupertinoIcon
        icon="exclamationmark_triangle_fill"
        color="systemRed"
        size={20}
        style={{ flexShrink: 0 }}
      />
      <span
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: 14,
          fontWeight: 600,
          color: "var(--cupertino-system-red)",
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
        }}
      >
        {needsAttention.length === 1
          ? `${needsAttention[0].server.name} needs attention`
          : `${needsAttention.length} servers need attention`}
      </span>
    </div>
  );
}

/**
 * The "Servers" home screen: every saved TrueNAS server as a list tile with
 * its fleet health, servers needing attention first under a red banner. It is
 * the app's landing screen; tapping a server opens its detail screen.
 */
export function HomeScreen({
  servers,
  isLoading = false,
  session,
  onAddServer,
  onServerSelected,
}: HomeScreenProps) {
  const needsAttention = servers.filter((s) => s.status?.needsAttention);
  const rest = servers.filter((s) => !s.status?.needsAttention);

  let body;
  if (isLoading) {
    body = (
      <div style={fill}>
        <LoadingStateWidget message="Loading servers..." />
      </div>
    );
  } else if (servers.length === 0) {
    body = (
      <div style={fill}>
        <EmptyStateWidget
          leading={<AppLogo size={88} />}
          title="No servers added yet"
          message="Tap + to add your first TrueNAS server"
        />
      </div>
    );
  } else {
    body = (
      <>
        <FleetBanner needsAttention={needsAttention} />
        {[...needsAttention, ...rest].map((entry) => (
          <ServerListTile
            key={entry.id}
            server={entry.server}
            status={entry.status}
            onClick={
              onServerSelected ? () => onServerSelected(entry.id) : undefined
            }
          />
        ))}
      </>
    );
  }

  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={
            <span style={{ display: "inline-flex", alignItems: "center" }}>
              Servers
              {session && (
                <span style={{ marginLeft: 8, display: "inline-flex" }}>
                  <SessionIndicatorWidget {...session} />
                </span>
              )}
            </span>
          }
          trailing={
            <CupertinoButton padding={0} minSize={0} onClick={onAddServer}>
              <CupertinoIcon icon="add" />
            </CupertinoButton>
          }
        />
      }
    >
      {body}
    </CupertinoPageScaffold>
  );
}
