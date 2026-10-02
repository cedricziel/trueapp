import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoButton,
  SectionHeader,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 360 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

const viewAll = (
  <CupertinoButton size="small" padding={0} minSize={0}>
    View All
  </CupertinoButton>
);

function Headers() {
  return (
    <>
      <SectionHeader title="Storage Pools" action={viewAll} />
      <SectionHeader title="Recent Alerts" />
      <SectionHeader
        title="Snapshots of tank/media/photos/2026-archive"
        action={viewAll}
      />
    </>
  );
}

export const WithAndWithoutActionLight = () => (
  <Pane>
    <Headers />
  </Pane>
);

export const WithAndWithoutActionDark = () => (
  <Pane dark>
    <Headers />
  </Pane>
);
