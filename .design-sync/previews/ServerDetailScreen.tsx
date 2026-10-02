import type { ReactNode } from "react";
import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerDetailScreen,
  type DeviceKind,
  type Pool,
  type ServerDetailScreenProps,
  type SystemStatsWidgetProps,
  type TrueNASApp,
} from "@truenas-manager/ui";

const MiB = 1024 ** 2;
const GiB = 1024 ** 3;
const TiB = 1024 ** 4;

const systemStats: SystemStatsWidgetProps = {
  cpu: {
    cpuUsage: 23.8,
    cpuHistory: [
      14, 16, 15, 19, 22, 18, 17, 21, 26, 31, 28, 24, 22, 20, 23, 27, 25, 21,
      19, 22, 24, 29, 33, 30, 26, 23, 21, 24, 25, 23.8,
    ],
    cores: {
      cpu0: 31,
      cpu1: 18,
      cpu2: 27,
      cpu3: 12,
      cpu4: 64,
      cpu5: 15,
      cpu6: 22,
      cpu7: 9,
    },
  },
  memory: {
    stats: {
      freeMemory: 9.6 * GiB,
      arcSize: 38.2 * GiB,
      appsMemory: 16.2 * GiB,
    },
    memoryUsage: 62.4,
    memoryHistory: [
      58, 58, 59, 59, 60, 60, 59, 60, 61, 61, 60, 61, 62, 61, 62, 62, 61, 62,
      63, 62, 62, 63, 62, 62, 63, 62, 62, 63, 62, 62.4,
    ],
  },
  disk: {
    busy: 23.6,
    readRate: "48.2 MB/s",
    writeRate: "12.7 MB/s",
    readOps: 412.5,
    writeOps: 96.3,
  },
  network: [
    { name: "eno1", receivedRate: "84.6 MB/s", sentRate: "2.3 MB/s" },
    { name: "eno2", receivedRate: "1.2 MB/s", sentRate: "38.9 MB/s" },
  ],
};

const pools: Pool[] = [
  {
    name: "tank",
    status: "ONLINE",
    healthy: true,
    topologyDescription: "RAIDZ2 · 6 disks",
    allocatedBytes: 21.4 * TiB,
    freeBytes: 11.3 * TiB,
    totalBytes: 32.7 * TiB,
  },
  {
    name: "backup",
    status: "DEGRADED",
    healthy: false,
    topologyDescription: "MIRROR · 2 disks",
    allocatedBytes: 6.1 * TiB,
    freeBytes: 1.2 * TiB,
    totalBytes: 7.3 * TiB,
  },
];

const apps: TrueNASApp[] = [
  {
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
      networkRxBytes: 1.8 * GiB,
      networkTxBytes: 24.6 * GiB,
      lastUpdatedLabel: "5s ago",
    },
    portals: { "Web UI": "http://nas.local:30013" },
  },
  {
    name: "Nextcloud",
    description:
      "A safe home for all your data: files, calendars, contacts and more.",
    installed: true,
    healthy: true,
    isFavorite: true,
    categories: ["productivity", "storage"],
    latestAppVersion: "30.0.1",
    upgradeVersion: "30.0.2",
    resourceUsage: {
      cpuUsage: 2.1,
      memoryUsage: 1.3 * GiB,
      networkRxBytes: 312 * MiB,
      networkTxBytes: 96 * MiB,
      lastUpdatedLabel: "5s ago",
    },
  },
  {
    name: "Home Assistant",
    description: "Open source home automation that puts local control first.",
    installed: true,
    healthy: true,
    categories: ["home-automation"],
    latestAppVersion: "2026.9.3",
  },
  {
    name: "Immich",
    description:
      "High-performance self-hosted photo and video management solution.",
    installed: false,
    categories: ["media", "photos"],
    latestAppVersion: "1.119.1",
  },
];

const base: ServerDetailScreenProps = {
  serverName: "Basement NAS",
  systemStats,
  pools,
  apps,
  jobsRunningCount: 1,
};

function Shell({
  device = "phone",
  orientation,
  dark,
  children,
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  children: ReactNode;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={device === "phone" ? 0.6 : device === "tablet" ? 0.45 : 0.5}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        {children}
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

const Screen = (props: Partial<ServerDetailScreenProps>) => (
  <ServerDetailScreen {...base} {...props} />
);

export const PhonePortraitLight = () => (
  <Shell>
    <Screen />
  </Shell>
);
export const PhonePortraitDark = () => (
  <Shell dark>
    <Screen />
  </Shell>
);
export const PhoneLandscapeLight = () => (
  <Shell orientation="landscape">
    <Screen />
  </Shell>
);
export const TabletPortraitLight = () => (
  <Shell device="tablet">
    <Screen />
  </Shell>
);
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark>
    <Screen />
  </Shell>
);
export const DesktopLight = () => (
  <Shell device="desktop">
    <Screen />
  </Shell>
);
export const DesktopDark = () => (
  <Shell device="desktop" dark>
    <Screen />
  </Shell>
);
export const AlertsBannerDark = () => (
  <Shell dark>
    <Screen
      activeAlerts={[
        {
          level: "critical",
          message:
            "Pool backup state is DEGRADED: One or more devices has experienced an unrecoverable error.",
        },
        {
          level: "warning",
          message: "Device /dev/sdc: 8 Currently unreadable (pending) sectors.",
        },
      ]}
      jobsRunningCount={0}
      jobsNeedAttention
    />
  </Shell>
);
export const AuthRequiredLight = () => (
  <Shell>
    <Screen authState="required" connectionState="connecting" />
  </Shell>
);
export const PoolsLoadingLight = () => (
  <Shell>
    <Screen
      systemStats={{ isLoading: true }}
      pools={[]}
      poolsLoading
      appsLoading
    />
  </Shell>
);
export const PoolsErrorDark = () => (
  <Shell dark>
    <Screen
      systemStats={{}}
      pools={[]}
      poolsError="[EFAULT] pool.query: middleware call timed out"
      apps={[]}
      connectionState="connected"
      connectionHealthy={false}
    />
  </Shell>
);
export const PoolsAndAppsTabletLight = () => (
  <Shell device="tablet">
    <Screen systemStats={{ isLoading: true }} />
  </Shell>
);
export const AppsOverviewDark = () => (
  <Shell dark>
    <Screen systemStats={{ isLoading: true }} pools={[pools[0]]} />
  </Shell>
);
export const ServerMenuOpenLight = () => (
  <Shell>
    <Screen showServerMenu />
  </Shell>
);
