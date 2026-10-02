import type { ReactNode } from "react";
import { CupertinoApp, PoolCardWidget, type Pool } from "@truenas-manager/ui";

const TiB = 1024 ** 4;

const tank: Pool = {
  name: "tank",
  status: "ONLINE",
  healthy: true,
  topologyDescription: "RAIDZ1 · 4 disks",
  allocatedBytes: 6.42 * TiB,
  freeBytes: 4.48 * TiB,
  totalBytes: 10.9 * TiB,
};

const backup: Pool = {
  name: "backup",
  status: "DEGRADED",
  healthy: false,
  topologyDescription: "MIRROR · 2 disks",
  allocatedBytes: 2.71 * TiB,
  freeBytes: 0.92 * TiB,
  totalBytes: 3.63 * TiB,
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

export const HealthyLight = () => (
  <Pane>
    <PoolCardWidget pool={tank} />
  </Pane>
);

export const HealthyDark = () => (
  <Pane dark>
    <PoolCardWidget pool={tank} />
  </Pane>
);

export const DegradedLight = () => (
  <Pane>
    <PoolCardWidget pool={backup} />
  </Pane>
);

export const DegradedDark = () => (
  <Pane dark>
    <PoolCardWidget pool={backup} />
  </Pane>
);
