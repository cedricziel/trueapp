import {
  CupertinoApp,
  CupertinoNavigationBar,
  CupertinoSidebar,
  DeviceFrame,
  InfoRow,
  SectionCard,
  ServerListTile,
} from "@truenas-manager/ui";

function Standalone({
  dark,
  selectedIndex,
}: {
  dark?: boolean;
  selectedIndex: number;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ width: 320, height: 220 }}
    >
      <CupertinoSidebar selectedIndex={selectedIndex} />
    </CupertinoApp>
  );
}

function ServersPane() {
  return (
    <div style={{ flex: 1, minWidth: 0 }}>
      <CupertinoNavigationBar largeTitle="Servers" />
      <ServerListTile
        server={{
          name: "Basement NAS",
          baseUrl: "https://nas.local",
          isActive: true,
        }}
        status={{ connectivity: "online", cpuUsage: 18, storageUsage: 61 }}
      />
      <ServerListTile
        server={{ name: "Backup Box", baseUrl: "https://backup.example.net" }}
        status={{
          connectivity: "online",
          cpuUsage: 72,
          storageUsage: 91,
          activeAlertCount: 2,
          needsAttention: true,
        }}
      />
    </div>
  );
}

function SettingsPane() {
  return (
    <div
      style={{
        flex: 1,
        minWidth: 0,
        background: "var(--cupertino-system-grouped-background)",
      }}
    >
      <CupertinoNavigationBar largeTitle="Settings" />
      <div style={{ padding: 20, maxWidth: 560 }}>
        <SectionCard title="Appearance" icon="settings">
          <InfoRow label="Theme" value="System" />
          <InfoRow label="Refresh interval" value="30 s" />
        </SectionCard>
      </div>
    </div>
  );
}

function InDevice({
  dark,
  device,
}: {
  dark?: boolean;
  device: "tablet" | "desktop";
}) {
  const settings = device === "desktop";
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: device === "desktop" ? 672 : 681 }}
    >
      <DeviceFrame
        device={device}
        orientation="landscape"
        brightness={dark ? "dark" : "light"}
        scale={device === "desktop" ? 0.5 : 0.55}
      >
        <div style={{ display: "flex", flex: 1, minHeight: 0 }}>
          <CupertinoSidebar selectedIndex={settings ? 1 : 0} />
          {settings ? <SettingsPane /> : <ServersPane />}
        </div>
      </DeviceFrame>
    </CupertinoApp>
  );
}

export const ServersSelectedLight = () => <Standalone selectedIndex={0} />;

export const ServersSelectedDark = () => <Standalone dark selectedIndex={0} />;

export const SettingsSelectedLight = () => <Standalone selectedIndex={1} />;

export const SettingsSelectedDark = () => <Standalone dark selectedIndex={1} />;

export const TabletLandscapeLight = () => <InDevice device="tablet" />;

export const TabletLandscapeDark = () => <InDevice dark device="tablet" />;

export const DesktopLight = () => <InDevice device="desktop" />;

export const DesktopDark = () => <InDevice dark device="desktop" />;
