import {
  AdaptiveNavigationScaffold,
  AppDetailScreen,
  DeviceFrame,
  type AppDetail,
  type AppDetailScreenProps,
  type DeviceKind,
} from "@truenas-manager/ui";

const jellyfin: AppDetail = {
  name: "Jellyfin",
  description:
    "Jellyfin is a free software media system that puts you in control of managing and streaming your media. Stream to any device from your own server, with no strings attached.",
  installed: true,
  healthy: true,
  isFavorite: true,
  latestAppVersion: "1.1.12",
  latestHumanVersion: "10.10.3_1.1.12",
  categories: ["media"],
  tags: ["media", "streaming", "movies", "music"],
  catalog: "TRUENAS",
  train: "community",
  lastUpdatedLabel: "4 days ago",
  screenshots: [
    "jellyfin-home.png",
    "jellyfin-player.png",
    "jellyfin-admin.png",
  ],
  appReadme:
    "<p>Jellyfin is the volunteer-built media solution.</p>\n<p>Media is stored in <code>/media</code> &amp; transcodes are written to <code>/cache</code>.</p>",
  maintainers: [
    { name: "truenas", email: "dev@ixsystems.com" },
    { name: "stavros-k" },
  ],
  sources: [
    "https://github.com/jellyfin/jellyfin",
    "https://hub.docker.com/r/jellyfin/jellyfin",
  ],
  home: "https://jellyfin.org",
};

const immich: AppDetail = {
  name: "Immich",
  description:
    "High-performance self-hosted photo and video backup solution with machine learning powered search.",
  installed: true,
  healthy: false,
  healthyError: "Container immich-server restarting (exit code 1)",
  latestAppVersion: "1.3.4",
  latestHumanVersion: "1.121.0_1.3.4",
  categories: ["media", "photos"],
  catalog: "TRUENAS",
  train: "community",
  lastUpdatedLabel: "2 days ago",
  maintainers: [{ name: "truenas", email: "dev@ixsystems.com" }],
  sources: ["https://github.com/immich-app/immich"],
  home: "https://immich.app",
};

const plex: AppDetail = {
  name: "Plex",
  description:
    "Plex organizes all of your video, music and photo collections and streams them to all of your screens.",
  installed: false,
  latestAppVersion: "1.2.7",
  latestHumanVersion: "1.41.2.9200_1.2.7",
  categories: ["media"],
  tags: ["media", "streaming"],
  catalog: "TRUENAS",
  train: "stable",
  lastUpdatedLabel: "1 month ago",
  screenshots: ["plex-library.png"],
  sources: ["https://hub.docker.com/r/plexinc/pms-docker"],
  home: "https://plex.tv",
};

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
} & Partial<AppDetailScreenProps>) {
  const app = props.app ?? jellyfin;
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <AppDetailScreen
          // No network in previews: every screenshot shows its placeholder.
          unavailableScreenshots={(app.screenshots ?? []).map((_, i) => i)}
          {...props}
          app={app}
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

export const NotInstalled = () => <Shell app={plex} />;
export const InstalledUnhealthyDark = () => <Shell dark app={immich} />;
export const ActionsSheetOpen = () => <Shell showActions />;
export const ConfigNotFoundAlertDark = () => (
  <Shell dark app={immich} showConfigNotFoundError />
);
