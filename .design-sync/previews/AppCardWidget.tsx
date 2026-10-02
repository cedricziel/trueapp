import type { ReactNode } from "react";
import {
  AppCardWidget,
  CupertinoApp,
  type TrueNASApp,
} from "@truenas-manager/ui";

const MiB = 1024 ** 2;
const GiB = 1024 ** 3;

const immichAvailable: TrueNASApp = {
  name: "Immich",
  description:
    "High-performance self-hosted photo and video management solution.",
  installed: false,
  categories: ["media", "photos"],
  latestAppVersion: "1.119.1",
};

const jellyfin: TrueNASApp = {
  name: "Jellyfin",
  description:
    "Free media system that puts you in control of managing and streaming your media.",
  installed: true,
  healthy: true,
  isFavorite: true,
  categories: ["media", "streaming"],
  latestAppVersion: "10.10.3",
  resourceUsage: {
    cpuUsage: 7.4,
    memoryUsage: 812 * MiB,
    memoryLimit: 4096,
    networkRxBytes: 1.8 * GiB,
    networkTxBytes: 24.6 * GiB,
    lastUpdatedLabel: "5s ago",
  },
  customUrl: "https://jellyfin.home.example.net",
  usedPorts: [
    { containerPort: 8096, protocol: "tcp", hostPort: 30013 },
    { containerPort: 7359, protocol: "udp", hostPort: 7359 },
  ],
  portals: { "Web UI": "http://nas.local:30013" },
};

const nextcloud: TrueNASApp = {
  name: "Nextcloud",
  description:
    "A safe home for all your data: files, calendars, contacts and more.",
  installed: true,
  healthy: true,
  categories: ["productivity", "storage"],
  latestAppVersion: "30.0.1",
  resourceUsage: {
    cpuUsage: 2.1,
    memoryUsage: 1.3 * GiB,
    networkRxBytes: 312 * MiB,
    networkTxBytes: 96 * MiB,
    lastUpdatedLabel: "5s ago",
  },
  upgradeVersion: "30.0.2",
  usedPorts: [{ containerPort: 80, protocol: "tcp", hostPort: 30027 }],
  portals: { "Web UI": "http://nas.local:30027" },
};

const homeAssistant: TrueNASApp = {
  name: "Home Assistant",
  description:
    "Open source home automation that puts local control and privacy first.",
  installed: true,
  healthy: false,
  categories: ["home-automation"],
  latestAppVersion: "2024.11.2",
  usedPorts: [{ containerPort: 8123, protocol: "tcp", hostPort: 30103 }],
  healthyError: "Container homeassistant exited with code 1",
};

function Pane({
  dark,
  width = 360,
  children,
}: {
  dark?: boolean;
  width?: number;
  children: ReactNode;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width }}
    >
      {children}
    </CupertinoApp>
  );
}

const noop = () => {};

export const AvailableLight = () => (
  <Pane>
    <AppCardWidget app={immichAvailable} />
  </Pane>
);

export const AvailableDark = () => (
  <Pane dark>
    <AppCardWidget app={immichAvailable} />
  </Pane>
);

export const InstalledRichLight = () => (
  <Pane>
    <AppCardWidget app={jellyfin} onToggleFavorite={noop} />
  </Pane>
);

export const InstalledRichDark = () => (
  <Pane dark>
    <AppCardWidget app={jellyfin} onToggleFavorite={noop} />
  </Pane>
);

export const UpgradeAvailableLight = () => (
  <Pane>
    <AppCardWidget app={nextcloud} onUpgrade={noop} />
  </Pane>
);

export const UnhealthyDark = () => (
  <Pane dark>
    <AppCardWidget app={homeAssistant} />
  </Pane>
);

export const WideLight = () => (
  <Pane width={700}>
    <AppCardWidget app={jellyfin} onToggleFavorite={noop} />
  </Pane>
);
