import type { ReactNode } from "react";
import { CupertinoApp, InfoRow, SectionCard } from "@truenas-manager/ui";

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

function PoolGeneral() {
  return (
    <SectionCard title="General" icon="square_stack_3d_down_right">
      <InfoRow label="Name" value="tank" />
      <InfoRow label="Status" value="ONLINE" valueColor="systemGreen" />
      <InfoRow label="Topology" value="RAIDZ1 · 4 disks" />
      <InfoRow label="Scrub" value="Finished 2 days ago, 0 errors" />
    </SectionCard>
  );
}

export const PoolDetailsLight = () => (
  <Pane>
    <PoolGeneral />
  </Pane>
);

export const PoolDetailsDark = () => (
  <Pane dark>
    <PoolGeneral />
  </Pane>
);

export const UserProfileLight = () => (
  <Pane>
    <SectionCard title="Account" icon="lock_shield" iconColor="systemPurple">
      <InfoRow label="Username" value="admin" />
      <InfoRow label="Full name" value="Local Administrator" />
      <InfoRow label="Two-factor" value="Disabled" valueColor="systemOrange" />
      <InfoRow label="Home directory" value="/mnt/tank/home/admin" />
    </SectionCard>
  </Pane>
);

export const UserProfileDark = () => (
  <Pane dark>
    <SectionCard title="Account" icon="lock_shield" iconColor="systemPurple">
      <InfoRow label="Username" value="admin" />
      <InfoRow label="Full name" value="Local Administrator" />
      <InfoRow label="Two-factor" value="Disabled" valueColor="systemOrange" />
      <InfoRow label="Home directory" value="/mnt/tank/home/admin" />
    </SectionCard>
  </Pane>
);
