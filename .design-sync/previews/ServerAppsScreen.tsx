import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerAppsScreen,
  type DeviceKind,
  type ServerAppsScreenProps,
  type TrueNASApp,
} from "@truenas-manager/ui";

const GB = 1024 ** 3;
const MB = 1024 ** 2;

const jellyfin: TrueNASApp = {
  name: "Jellyfin",
  description:
    "Free software media system that puts you in control of managing and streaming your media.",
  installed: true,
  healthy: true,
  categories: ["media", "streaming"],
  latestAppVersion: "10.10.3",
  isFavorite: true,
  resourceUsage: {
    cpuUsage: 12.4,
    memoryUsage: 1.3 * GB,
    memoryLimit: 4096,
    networkRxBytes: 820 * MB,
    networkTxBytes: 4.2 * GB,
    lastUpdatedLabel: "5s ago",
  },
  usedPorts: [{ containerPort: 8096, protocol: "tcp", hostPort: 30013 }],
  portals: { "Web UI": "http://nas.local:30013" },
};

const nextcloud: TrueNASApp = {
  name: "Nextcloud",
  description:
    "A safe home for all your data: files, calendars, contacts and collaboration on your own server.",
  installed: true,
  healthy: true,
  categories: ["productivity", "cloud"],
  latestAppVersion: "30.0.2",
  upgradeVersion: "30.0.4",
  resourceUsage: { cpuUsage: 3.1, memoryUsage: 612 * MB },
  usedPorts: [{ containerPort: 443, protocol: "tcp", hostPort: 30027 }],
};

const immich: TrueNASApp = {
  name: "Immich",
  description:
    "High-performance self-hosted photo and video backup with machine learning search.",
  installed: true,
  healthy: false,
  categories: ["photos"],
  latestAppVersion: "1.121.0",
  healthyError: "Container immich-server restarting (exit code 1)",
};

const homeAssistant: TrueNASApp = {
  name: "Home Assistant",
  description:
    "Open source home automation that puts local control and privacy first.",
  installed: true,
  healthy: true,
  categories: ["home-automation"],
  latestAppVersion: "2024.11.3",
  isFavorite: true,
  resourceUsage: { cpuUsage: 1.8, memoryUsage: 420 * MB },
  customUrl: "https://ha.example.net",
  usedPorts: [{ containerPort: 8123, protocol: "tcp", hostPort: 30103 }],
};

const plex: TrueNASApp = {
  name: "Plex",
  description:
    "Organise your movies, shows and music and stream them to any device.",
  installed: false,
  categories: ["media"],
  latestAppVersion: "1.41.2",
};
const syncthing: TrueNASApp = {
  name: "Syncthing",
  description: "Continuous peer-to-peer file synchronization between devices.",
  installed: false,
  categories: ["storage", "sync"],
  latestAppVersion: "1.28.1",
};
const vaultwarden: TrueNASApp = {
  name: "Vaultwarden",
  description: "Lightweight Bitwarden-compatible password manager server.",
  installed: false,
  categories: ["security"],
  latestAppVersion: "1.32.5",
};

const installed = [homeAssistant, immich, jellyfin, nextcloud];
const available = [plex, syncthing, vaultwarden];

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
} & Partial<ServerAppsScreenProps>) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <ServerAppsScreen
          apps={installed}
          runningJobsCount={1}
          onRefresh={() => {}}
          {...props}
        />
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Shell />;
export const PhonePortraitDark = () => <Shell dark />;
export const PhoneLandscapeLight = () => <Shell orientation="landscape" />;
export const TabletPortraitLight = () => <Shell device="tablet" scale={0.45} />;
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark scale={0.45} />
);
export const DesktopLight = () => <Shell device="desktop" scale={0.5} />;
export const DesktopDark = () => <Shell device="desktop" dark scale={0.5} />;

export const AvailableSegment = () => (
  <Shell segment="available" apps={available} sortByName={false} />
);
export const FavoritesSegmentDark = () => (
  <Shell dark segment="favorites" apps={[homeAssistant, jellyfin]} />
);
export const UpdatesSegment = () => (
  <Shell segment="updates" apps={[nextcloud]} />
);
export const SearchNoMatch = () => <Shell searchQuery="minecraft" apps={[]} />;
export const LoadingDark = () => <Shell dark loading apps={[]} />;
export const LoadError = () => (
  <Shell
    apps={[]}
    error={{
      message: "Connection timed out",
      details: "app.query did not respond within 30s",
    }}
  />
);
export const StaleCatalogNoticeDark = () => (
  <Shell
    dark
    segment="available"
    apps={available}
    catalogError={{ shortMessage: "Catalog sync failed" }}
  />
);
