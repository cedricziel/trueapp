import type { ReactNode } from "react";
import {
  AdaptiveNavigationScaffold,
  CupertinoApp,
  CupertinoNavigationBar,
  DeviceFrame,
  JobsBellButton,
  ServerListTile,
  type DeviceKind,
} from "@truenas-manager/ui";

function ServersScreen() {
  return (
    <div>
      <CupertinoNavigationBar
        largeTitle="Servers"
        trailing={<JobsBellButton runningCount={1} />}
      />
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

function Frame({
  device,
  orientation,
  dark,
  scale,
}: {
  device: DeviceKind;
  orientation: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
}) {
  const compact =
    device === "phone" || (device === "tablet" && orientation === "portrait");
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
      <span style={{ fontSize: 12, color: "var(--cupertino-secondary-label)" }}>
        {device} · {orientation}
      </span>
      <DeviceFrame
        device={device}
        orientation={orientation}
        brightness={dark ? "dark" : "light"}
        scale={scale}
      >
        <AdaptiveNavigationScaffold layout={compact ? "compact" : "expanded"}>
          <ServersScreen />
        </AdaptiveNavigationScaffold>
      </DeviceFrame>
    </div>
  );
}

function Board({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{
        padding: 16,
        display: "flex",
        alignItems: "flex-start",
        gap: 24,
        width: "max-content",
      }}
    >
      {children}
    </CupertinoApp>
  );
}

export const PhoneLight = () => (
  <Board>
    <Frame device="phone" orientation="portrait" scale={0.45} />
    <Frame device="phone" orientation="landscape" scale={0.45} />
  </Board>
);

export const PhoneDark = () => (
  <Board dark>
    <Frame device="phone" orientation="portrait" dark scale={0.45} />
    <Frame device="phone" orientation="landscape" dark scale={0.45} />
  </Board>
);

export const TabletLight = () => (
  <Board>
    <Frame device="tablet" orientation="portrait" scale={0.35} />
    <Frame device="tablet" orientation="landscape" scale={0.35} />
  </Board>
);

export const TabletDark = () => (
  <Board dark>
    <Frame device="tablet" orientation="portrait" dark scale={0.35} />
    <Frame device="tablet" orientation="landscape" dark scale={0.35} />
  </Board>
);

export const DesktopLight = () => (
  <Board>
    <Frame device="desktop" orientation="landscape" scale={0.45} />
  </Board>
);

export const DesktopDark = () => (
  <Board dark>
    <Frame device="desktop" orientation="landscape" dark scale={0.45} />
  </Board>
);
