import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoNavigationBar,
  DeviceFrame,
  SystemStatsWidget,
  type DeviceKind,
  type SystemStatsWidgetProps,
} from "@truenas-manager/ui";

const GiB = 1024 ** 3;

const stats: SystemStatsWidgetProps = {
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
      <CupertinoNavigationBar largeTitle="Basement NAS" />
      <div style={{ padding: 16, overflow: "hidden" }}>
        <SystemStatsWidget {...stats} />
      </div>
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
export const DesktopDark = () => <Frame device="desktop" dark scale={0.5} />;

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 360 }}
    >
      {children}
    </CupertinoApp>
  );
}

function States() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <SystemStatsWidget isLoading />
      <SystemStatsWidget error="Connection timed out" />
      <SystemStatsWidget />
    </div>
  );
}

export const StatesLight = () => (
  <Pane>
    <States />
  </Pane>
);

export const StatesDark = () => (
  <Pane dark>
    <States />
  </Pane>
);
