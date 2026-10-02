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

function DatasetProperties() {
  return (
    <SectionCard title="Properties" icon="square_stack_3d_down_right">
      <InfoRow label="Dataset" value="tank/media" />
      <InfoRow label="Used" value="1.8 TiB" />
      <InfoRow label="Available" value="2.4 TiB" valueColor="systemGreen" />
      <InfoRow label="Compression" value="LZ4 (1.42x)" />
      <InfoRow label="Quota" value="92% of 2 TiB" valueColor="systemOrange" />
    </SectionCard>
  );
}

function ShareDetails() {
  return (
    <SectionCard title="SMB Share" icon="globe" iconColor="systemTeal">
      <InfoRow
        label="Path"
        value="/mnt/backup/timemachine/macbook-pro-office"
      />
      <InfoRow label="Purpose" value="Multi-protocol (NFSv4/SMB) shares" />
      <InfoRow label="Read only" value="No" />
      <InfoRow
        label="Last error"
        value="Permission denied"
        valueColor="systemRed"
      />
    </SectionCard>
  );
}

export const DatasetPropertiesLight = () => (
  <Pane>
    <DatasetProperties />
  </Pane>
);

export const DatasetPropertiesDark = () => (
  <Pane dark>
    <DatasetProperties />
  </Pane>
);

export const LongValuesWrapLight = () => (
  <Pane>
    <ShareDetails />
  </Pane>
);

export const LongValuesWrapDark = () => (
  <Pane dark>
    <ShareDetails />
  </Pane>
);
