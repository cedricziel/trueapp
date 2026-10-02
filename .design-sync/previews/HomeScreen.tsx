import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  HomeScreen,
  type DeviceKind,
  type HomeScreenProps,
  type HomeServerEntry,
} from "@truenas-manager/ui";

const basement: HomeServerEntry = {
  id: "basement",
  server: {
    name: "Basement NAS",
    baseUrl: "https://nas.local",
    isActive: true,
  },
  status: { connectivity: "online", cpuUsage: 18, storageUsage: 61 },
};
const backup: HomeServerEntry = {
  id: "backup",
  server: { name: "Backup Box", baseUrl: "https://backup.example.net" },
  status: {
    connectivity: "online",
    cpuUsage: 72,
    storageUsage: 91,
    activeAlertCount: 2,
    needsAttention: true,
  },
};
const office: HomeServerEntry = {
  id: "office",
  server: { name: "Office Mini", baseUrl: "http://192.168.1.40" },
  status: { connectivity: "offline", needsAttention: true },
};
const officeHealthy: HomeServerEntry = {
  ...office,
  status: { connectivity: "online", cpuUsage: 9, storageUsage: 34 },
};

const fleet: HomeScreenProps = {
  servers: [basement, backup, office],
  session: { minutesRemaining: 24 },
};

function Shell({
  device,
  orientation,
  dark,
  scale,
  props = fleet,
}: {
  device: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
  props?: HomeScreenProps;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <HomeScreen {...props} />
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

export const EmptyLight = () => (
  <Shell device="phone" scale={0.6} props={{ servers: [] }} />
);
export const LoadingDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{ servers: [], isLoading: true }}
  />
);
export const SingleNeedsAttentionLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{ servers: [basement, backup, officeHealthy] }}
  />
);
export const AllHealthySessionExpiringDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{
      servers: [
        basement,
        {
          ...backup,
          status: { connectivity: "online", cpuUsage: 31, storageUsage: 58 },
        },
        officeHealthy,
      ],
      session: { minutesRemaining: 3 },
    }}
  />
);
