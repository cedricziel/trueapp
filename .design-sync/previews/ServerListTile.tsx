import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoNavigationBar,
  DeviceFrame,
  ServerListTile,
  type DeviceKind,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: "16px 0", width: 380 }}
    >
      {children}
    </CupertinoApp>
  );
}

function AllStatuses() {
  return (
    <div>
      <ServerListTile
        server={{ name: "Basement NAS", baseUrl: "https://nas.local" }}
        status={{ connectivity: "loading" }}
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
      <ServerListTile
        server={{ name: "Media Server", baseUrl: "https://media.lan" }}
      />
    </div>
  );
}

export const StatusesLight = () => (
  <Pane>
    <AllStatuses />
  </Pane>
);

export const StatusesDark = () => (
  <Pane dark>
    <AllStatuses />
  </Pane>
);

function Fleet() {
  return (
    <>
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
      <ServerListTile
        server={{ name: "Office Mini", baseUrl: "http://192.168.1.40" }}
        status={{ connectivity: "offline" }}
      />
      <ServerListTile
        server={{ name: "Media Server", baseUrl: "https://media.lan" }}
        status={{ connectivity: "unknown" }}
      />
    </>
  );
}

function Frame({
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
      <Fleet />
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Frame device="phone" scale={0.6} />;
export const PhonePortraitDark = () => (
  <Frame device="phone" dark scale={0.6} />
);
export const TabletLandscapeLight = () => (
  <Frame device="tablet" orientation="landscape" scale={0.45} />
);
export const TabletLandscapeDark = () => (
  <Frame device="tablet" orientation="landscape" dark scale={0.45} />
);
