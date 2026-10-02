import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerPoolsScreen,
  type DeviceKind,
  type PoolListItem,
  type ServerPoolsScreenProps,
} from "@truenas-manager/ui";

const pools: PoolListItem[] = [
  {
    name: "tank",
    status: "ONLINE",
    healthy: true,
    topologyDescription: "RAIDZ1 (4 drives)",
    disks: [
      { name: "sda", status: "online" },
      { name: "sdb", status: "online" },
      { name: "sdc", status: "online" },
      { name: "sdd", status: "online" },
    ],
  },
  {
    name: "backup",
    status: "DEGRADED",
    healthy: false,
    topologyDescription: "Mirror (2 drives)",
    disks: [
      { name: "sde", status: "online" },
      { name: "sdf", status: "faulted" },
    ],
  },
];

const noop = () => {};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: Partial<ServerPoolsScreenProps> & {
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
        <ServerPoolsScreen
          serverName="Basement NAS"
          pools={pools}
          jobsBell={{ needsAttention: true }}
          onBack={noop}
          onRetry={noop}
          onSettings={noop}
          onPoolClick={noop}
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
export const Loading = () => <Shell loading />;
export const ConnectionTimeout = () => (
  <Shell
    dark
    connectionError={{
      type: "connectionTimeout",
      shortMessage: "Connection timed out",
      userFriendlyMessage:
        "Basement NAS didn't respond in time. Check that it's powered on and reachable from this network.",
      isRetryable: true,
    }}
  />
);
export const Empty = () => <Shell pools={[]} />;
