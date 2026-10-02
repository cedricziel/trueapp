import type { ReactNode } from "react";
import {
  CupertinoApp,
  MemoryStatsCard,
  type MemoryStats,
} from "@truenas-manager/ui";

const GiB = 1024 ** 3;

// 64 GiB box: ARC holds most of it, apps a healthy chunk.
const stats: MemoryStats = {
  freeMemory: 9.6 * GiB,
  arcSize: 38.2 * GiB,
  appsMemory: 16.2 * GiB,
};

const history = [
  71, 72, 72, 73, 73, 74, 74, 73, 74, 75, 75, 76, 76, 75, 76, 77, 77, 76, 77,
  78, 78, 79, 78, 79, 80, 80, 81, 80, 81, 81.9,
];

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

export const DefaultLight = () => (
  <Pane>
    <MemoryStatsCard stats={stats} memoryUsage={81.9} memoryHistory={history} />
  </Pane>
);

export const DefaultDark = () => (
  <Pane dark>
    <MemoryStatsCard stats={stats} memoryUsage={81.9} memoryHistory={history} />
  </Pane>
);
