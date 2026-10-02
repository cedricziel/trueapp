import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  PoolDetailScreen,
  type DatasetListItem,
  type DeviceKind,
  type PoolDetailScreenProps,
} from "@truenas-manager/ui";

const datasets: DatasetListItem[] = [
  { name: "tank", mountpoint: "/mnt/tank", used: "6.8T", available: "3.9T" },
  {
    name: "tank/home",
    mountpoint: "/mnt/tank/home",
    used: "412G",
    available: "3.9T",
  },
  {
    name: "tank/media",
    mountpoint: "/mnt/tank/media",
    used: "5.1T",
    available: "3.9T",
  },
  {
    name: "tank/media/movies",
    mountpoint: "/mnt/tank/media/movies",
    used: "3.7T",
    available: "3.9T",
  },
  {
    name: "tank/apps",
    mountpoint: "/mnt/tank/apps",
    used: "86.2G",
    available: "3.9T",
  },
  { name: "tank/vm-disk", type: "VOLUME", used: "120G", available: "3.9T" },
];

const noop = () => {};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: Partial<PoolDetailScreenProps> & {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <PoolDetailScreen
          pool={{
            name: "tank",
            status: "ONLINE",
            healthy: true,
            topologyDescription: "RAIDZ1 (4 drives)",
          }}
          datasets={datasets}
          jobsBell={{ runningCount: 1 }}
          onBack={noop}
          onRetry={noop}
          onDatasetClick={noop}
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
export const DegradedPool = () => (
  <Shell
    dark
    pool={{
      name: "backup",
      status: "DEGRADED",
      healthy: false,
      topologyDescription: "Mirror (2 drives)",
    }}
    datasets={[
      {
        name: "backup",
        mountpoint: "/mnt/backup",
        used: "1.4T",
        available: "2.2T",
      },
      {
        name: "backup/snapshots",
        mountpoint: "/mnt/backup/snapshots",
        used: "1.3T",
        available: "2.2T",
      },
    ]}
  />
);
export const DatasetsLoading = () => <Shell loading />;
export const DatasetsError = () => (
  <Shell dark error="pool.dataset.query failed: connection reset by peer" />
);
export const DatasetsEmpty = () => <Shell datasets={[]} />;
