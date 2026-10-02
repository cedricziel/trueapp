import type { ReactNode } from "react";
import { withAlpha } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { InfoRow, SectionCard, StatusPill } from "../components/SectionCard";

export interface TrueNASUser {
  username: string;
  /** Empty when the account has no full name; the header falls back to `username`. */
  fullName: string;
  uid: number;
  gid: number;
  homeDirectory: string;
  shell: string;
  /** e.g. "Local Account", "Active Directory". */
  sourceDisplayName: string;
  isLocal: boolean;
  isAdministrator: boolean;
  hasTwoFactor: boolean;
  /** Group ids, rendered as blue chips. */
  groupList: number[];
}

export interface ProfileServerInfo {
  name: string;
  host: string;
  port: number;
  useHttps: boolean;
  lastConnected?: Date;
}

export interface UserProfileScreenProps {
  server: ProfileServerInfo;
  /** The signed-in user; omit (with no loading/error) for the "No user information available" state. */
  user?: TrueNASUser;
  isLoadingUser?: boolean;
  /** Shows the red retry card in place of the header. */
  userError?: string;
  /** Reference time for "Last Connected". Defaults to now. */
  now?: Date;
  onBack?: () => void;
  /** Retry on the error card, and "Load User Info" on the empty card. */
  onLoadUser?: () => void;
}

const headerCard = {
  background: "var(--cupertino-system-grey6)",
  borderRadius: 12,
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  textAlign: "center",
} as const;

/**
 * The User Profile screen, opened from the person icon in the server
 * dashboard's nav bar: the signed-in TrueNAS user's identity header, account
 * details, security and group memberships, plus the server's connection info.
 */
export function UserProfileScreen({
  server,
  user,
  isLoadingUser = false,
  userError,
  now,
  onBack,
  onLoadUser,
}: UserProfileScreenProps) {
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          leading={
            <CupertinoButton padding={0} minSize={0} onClick={onBack}>
              Back
            </CupertinoButton>
          }
          middle="User Profile"
        />
      }
    >
      <div
        style={{
          padding: 16,
          display: "flex",
          flexDirection: "column",
          gap: 20,
        }}
      >
        <UserHeader
          user={user}
          isLoading={isLoadingUser}
          error={userError}
          onLoadUser={onLoadUser}
        />
        {user && <AccountDetails user={user} />}
        {user && <SecurityInfo user={user} />}
        <ServerInfo server={server} now={now ?? new Date()} />
      </div>
    </CupertinoPageScaffold>
  );
}

function UserHeader({
  user,
  isLoading,
  error,
  onLoadUser,
}: {
  user?: TrueNASUser;
  isLoading: boolean;
  error?: string;
  onLoadUser?: () => void;
}) {
  if (isLoading) {
    return (
      <div style={{ ...headerCard, padding: 32 }}>
        <CupertinoActivityIndicator />
      </div>
    );
  }

  if (error != null) {
    return (
      <div
        style={{
          ...headerCard,
          padding: 16,
          background: withAlpha("systemRed", 0.1),
          border: `1px solid ${withAlpha("systemRed", 0.3)}`,
          color: "var(--cupertino-system-red)",
        }}
      >
        <CupertinoIcon
          icon="exclamationmark_triangle"
          color="systemRed"
          size={32}
        />
        <div style={{ marginTop: 8, fontSize: 16, fontWeight: 600 }}>
          Failed to load user information
        </div>
        <div style={{ marginTop: 4, fontSize: 14 }}>{error}</div>
        <div style={{ marginTop: 16 }}>
          <CupertinoButton onClick={onLoadUser}>Retry</CupertinoButton>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div style={{ ...headerCard, padding: 24 }}>
        <CupertinoIcon icon="person_circle" color="systemGrey" size={48} />
        <div
          style={{
            marginTop: 12,
            fontSize: 16,
            fontWeight: 600,
            color: "var(--cupertino-system-grey)",
          }}
        >
          No user information available
        </div>
        <div style={{ marginTop: 16 }}>
          <CupertinoButton onClick={onLoadUser}>Load User Info</CupertinoButton>
        </div>
      </div>
    );
  }

  const hasDistinctFullName =
    user.fullName !== "" && user.fullName !== user.username;
  return (
    <div style={{ ...headerCard, padding: 20 }}>
      <div
        style={{
          width: 80,
          height: 80,
          borderRadius: 40,
          background: withAlpha("activeBlue", 0.1),
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <CupertinoIcon icon="person_fill" color="activeBlue" size={40} />
      </div>
      <div style={{ marginTop: 16, fontSize: 24, fontWeight: 700 }}>
        {user.fullName !== "" ? user.fullName : user.username}
      </div>
      {hasDistinctFullName && (
        <div
          style={{
            marginTop: 4,
            fontSize: 16,
            color: "var(--cupertino-system-grey)",
          }}
        >
          @{user.username}
        </div>
      )}
      <div
        style={{
          marginTop: 12,
          display: "flex",
          flexWrap: "wrap",
          justifyContent: "center",
          gap: 8,
        }}
      >
        {user.isAdministrator && (
          <>
            <StatusPill
              label="Administrator"
              color="systemOrange"
              icon="star_fill"
            />
            {/* The app's Wrap keeps a stray 8px SizedBox after this pill. */}
            <span style={{ width: 8 }} />
          </>
        )}
        {user.hasTwoFactor && (
          <StatusPill
            label="2FA Enabled"
            color="systemGreen"
            icon="lock_shield_fill"
          />
        )}
      </div>
    </div>
  );
}

function AccountDetails({ user }: { user: TrueNASUser }) {
  return (
    <SectionCard title="Account Details" icon="person_circle">
      <InfoRow label="Username" value={user.username} />
      {user.fullName !== "" && (
        <InfoRow label="Full Name" value={user.fullName} />
      )}
      <InfoRow label="User ID" value={String(user.uid)} />
      <InfoRow label="Group ID" value={String(user.gid)} />
      <InfoRow label="Home Directory" value={user.homeDirectory} />
      <InfoRow label="Shell" value={user.shell} />
      <InfoRow label="Account Source" value={user.sourceDisplayName} />
      <InfoRow label="Local Account" value={user.isLocal ? "Yes" : "No"} />
    </SectionCard>
  );
}

function SecurityInfo({ user }: { user: TrueNASUser }) {
  return (
    <SectionCard title="Security & Permissions" icon="lock_shield">
      <InfoRow
        label="Administrator"
        value={user.isAdministrator ? "Yes" : "No"}
        valueColor={user.isAdministrator ? "systemOrange" : "systemGrey"}
      />
      <InfoRow
        label="Two-Factor Authentication"
        value={user.hasTwoFactor ? "Enabled" : "Disabled"}
        valueColor={user.hasTwoFactor ? "systemGreen" : "systemGrey"}
      />
      {user.groupList.length > 0 && (
        <>
          <div
            style={{
              marginTop: 8,
              fontSize: 14,
              color: "var(--cupertino-system-grey)",
            }}
          >
            Groups
          </div>
          <div
            style={{ marginTop: 4, display: "flex", flexWrap: "wrap", gap: 6 }}
          >
            {user.groupList.map((group) => (
              <GroupChip key={group}>{group}</GroupChip>
            ))}
          </div>
        </>
      )}
    </SectionCard>
  );
}

function GroupChip({ children }: { children: ReactNode }) {
  return (
    <span
      style={{
        padding: "4px 8px",
        borderRadius: 8,
        background: withAlpha("systemBlue", 0.1),
        color: "var(--cupertino-system-blue)",
        fontSize: 12,
      }}
    >
      {children}
    </span>
  );
}

function formatLastConnected(date: Date, now: Date): string {
  const minutes = Math.floor((now.getTime() - date.getTime()) / 60000);
  if (minutes < 1) return "Just now";
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hours ago`;
  return `${Math.floor(hours / 24)} days ago`;
}

function ServerInfo({ server, now }: { server: ProfileServerInfo; now: Date }) {
  return (
    <SectionCard title="Server Information" icon="cube_box">
      <InfoRow label="Server Name" value={server.name} />
      <InfoRow label="Host" value={server.host} />
      <InfoRow label="Port" value={String(server.port)} />
      <InfoRow label="Protocol" value={server.useHttps ? "HTTPS" : "HTTP"} />
      {server.lastConnected && (
        <InfoRow
          label="Last Connected"
          value={formatLastConnected(server.lastConnected, now)}
        />
      )}
    </SectionCard>
  );
}
