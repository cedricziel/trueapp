import type { ReactNode } from "react";
import {
  CupertinoApp,
  DiskStatsCard,
  type DiskStats,
} from "@truenas-manager/ui";

const normal: DiskStats = {
  busy: 23.6,
  readRate: "48.2 MB/s",
  writeRate: "12.7 MB/s",
  readOps: 412.5,
  writeOps: 96.3,
};

const scrubbing: DiskStats = {
  busy: 91.4,
  readRate: "612.8 MB/s",
  writeRate: "3.1 MB/s",
  readOps: 4870.2,
  writeOps: 21.8,
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

export const NormalLight = () => (
  <Pane>
    <DiskStatsCard diskStats={normal} />
  </Pane>
);

export const NormalDark = () => (
  <Pane dark>
    <DiskStatsCard diskStats={normal} />
  </Pane>
);

export const ScrubbingLight = () => (
  <Pane>
    <DiskStatsCard diskStats={scrubbing} />
  </Pane>
);

export const ScrubbingDark = () => (
  <Pane dark>
    <DiskStatsCard diskStats={scrubbing} />
  </Pane>
);
