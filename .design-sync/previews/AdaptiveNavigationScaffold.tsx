import {
  AdaptiveNavigationScaffold,
  CupertinoNavigationBar,
  DeviceFrame,
  JobsBellButton,
  SectionHeader,
  ServerListTile,
  type DeviceKind,
} from "@truenas-manager/ui";

function ServersScreen() {
  return (
    <div>
      <CupertinoNavigationBar
        largeTitle="Servers"
        trailing={<JobsBellButton runningCount={2} />}
      />
      <div style={{ padding: "16px 16px 8px" }}>
        <SectionHeader title="Fleet" />
      </div>
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
      <ServerListTile
        server={{ name: "Office Mini", baseUrl: "http://192.168.1.40" }}
        status={{ connectivity: "offline" }}
      />
    </div>
  );
}

function Shell({
  device,
  orientation,
  dark,
  scale,
}: {
  device: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold>
        <ServersScreen />
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Shell device="phone" scale={0.6} />;
export const PhonePortraitDark = () => (
  <Shell device="phone" dark scale={0.6} />
);
export const PhoneLandscapeLight = () => (
  <Shell device="phone" orientation="landscape" scale={0.6} />
);
export const TabletPortraitLight = () => <Shell device="tablet" scale={0.45} />;
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark scale={0.45} />
);
export const DesktopLight = () => <Shell device="desktop" scale={0.5} />;
export const DesktopDark = () => <Shell device="desktop" dark scale={0.5} />;
