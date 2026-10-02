import type { ReactNode } from "react";
import { CpuStatsCard, CupertinoApp } from "@truenas-manager/ui";

const lowHistory = [
  9, 11, 8, 12, 14, 10, 9, 13, 18, 15, 11, 10, 12, 16, 21, 17, 13, 11, 10, 12,
  14, 11, 9, 10, 13, 15, 12, 11, 13, 12.4,
];
const lowCores = {
  cpu0: 14,
  cpu1: 9,
  cpu2: 18,
  cpu3: 7,
  cpu4: 12,
  cpu5: 11,
  cpu6: 16,
  cpu7: 10,
};

const highHistory = [
  38, 42, 47, 51, 55, 61, 66, 63, 70, 74, 78, 81, 79, 84, 88, 86, 83, 85, 89,
  91, 87, 84, 86, 90, 88, 85, 87, 89, 86, 87.3,
];
const highCores = {
  cpu0: 96,
  cpu1: 91,
  cpu2: 88,
  cpu3: 72,
  cpu4: 94,
  cpu5: 81,
  cpu6: 47,
  cpu7: 90,
};

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

export const LowLoadLight = () => (
  <Pane>
    <CpuStatsCard cpuUsage={12.4} cpuHistory={lowHistory} cores={lowCores} />
  </Pane>
);

export const LowLoadDark = () => (
  <Pane dark>
    <CpuStatsCard cpuUsage={12.4} cpuHistory={lowHistory} cores={lowCores} />
  </Pane>
);

export const HighLoadLight = () => (
  <Pane>
    <CpuStatsCard cpuUsage={87.3} cpuHistory={highHistory} cores={highCores} />
  </Pane>
);

export const HighLoadDark = () => (
  <Pane dark>
    <CpuStatsCard cpuUsage={87.3} cpuHistory={highHistory} cores={highCores} />
  </Pane>
);
