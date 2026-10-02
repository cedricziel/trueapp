import type { ReactNode } from "react";
import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerHealthScreen,
  type DeviceKind,
  type HealthAlert,
  type HealthDisk,
  type HealthService,
  type ServerHealthScreenProps,
} from "@truenas-manager/ui";

const now = new Date("2026-10-02T09:30:00Z");
const minutesAgo = (m: number) => new Date(now.getTime() - m * 60_000);

const alerts: HealthAlert[] = [
  {
    level: "critical",
    message:
      "Pool backup state is DEGRADED: One or more devices has experienced an unrecoverable error.",
    occurredAt: minutesAgo(12),
  },
  {
    level: "warning",
    message: "Device /dev/sdc: 8 Currently unreadable (pending) sectors.",
    occurredAt: minutesAgo(3 * 60 + 5),
  },
  {
    level: "info",
    message: "Update 25.04.2 is available for download.",
    occurredAt: minutesAgo(2 * 24 * 60),
  },
];

const disks: HealthDisk[] = [
  { name: "sda", health: "PASSED", temperature: 34 },
  { name: "sdb", health: "PASSED", temperature: 36 },
  { name: "sdc", health: "FAILED", temperature: 41 },
  { name: "sdd", health: "PASSED", temperature: 35 },
];

const healthyDisks: HealthDisk[] = disks.map((d) =>
  d.name === "sdc" ? { ...d, health: "PASSED", temperature: 37 } : d,
);

const services: HealthService[] = [
  { displayName: "SMB", isRunning: true },
  { displayName: "NFS", isRunning: true },
  { displayName: "SSH", isRunning: true },
  { displayName: "UPS", isRunning: false },
  { displayName: "SNMP", isRunning: false },
];

const base: ServerHealthScreenProps = {
  serverName: "Basement NAS",
  activeAlerts: alerts,
  disks,
  services,
  now,
  jobsRunningCount: 1,
};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale,
  children,
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
  children: ReactNode;
}) {
  const s =
    scale ?? (device === "phone" ? 0.6 : device === "tablet" ? 0.45 : 0.5);
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={s}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        {children}
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

const Screen = (props: Partial<ServerHealthScreenProps>) => (
  <ServerHealthScreen {...base} {...props} />
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
export const AllOperationalLight = () => (
  <Shell>
    <Screen activeAlerts={[]} disks={healthyDisks} jobsRunningCount={0} />
  </Shell>
);
export const AllOperationalDark = () => (
  <Shell dark>
    <Screen activeAlerts={[]} disks={healthyDisks} jobsRunningCount={0} />
  </Shell>
);
export const LoadingLight = () => (
  <Shell>
    <Screen isLoading />
  </Shell>
);
export const ErrorDark = () => (
  <Shell dark>
    <Screen error="Connection to nas.local timed out after 30 seconds." />
  </Shell>
);
