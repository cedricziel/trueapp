import type { ReactNode } from "react";
import { AppIcon, CupertinoApp } from "@truenas-manager/ui";

const healthy = { installed: true, healthy: true };
const unhealthy = { installed: true, healthy: false };
const available = { installed: false };

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 260 }}
    >
      {children}
    </CupertinoApp>
  );
}

function Row({
  label,
  app,
}: {
  label: string;
  app: { installed: boolean; healthy?: boolean };
}) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
      <AppIcon app={app} size={32} />
      <AppIcon app={app} size={44} />
      <AppIcon app={app} size={50} />
      <span style={{ fontSize: 13, color: "var(--cupertino-secondary-label)" }}>
        {label}
      </span>
    </div>
  );
}

function Sweep() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <Row label="Installed, healthy" app={healthy} />
      <Row label="Installed, unhealthy" app={unhealthy} />
      <Row label="Not installed" app={available} />
    </div>
  );
}

export const StatesLight = () => (
  <Pane>
    <Sweep />
  </Pane>
);

export const StatesDark = () => (
  <Pane dark>
    <Sweep />
  </Pane>
);
