import type { ReactNode } from "react";
import { AppStateBadge, CupertinoApp } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 360 }}
    >
      <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

function InstalledStates() {
  return (
    <>
      <AppStateBadge app={{ installed: true, state: "running" }} />
      <AppStateBadge app={{ installed: true, state: "deploying" }} />
      <AppStateBadge app={{ installed: true, state: "stopping" }} />
      <AppStateBadge app={{ installed: true, state: "stopped" }} />
      <AppStateBadge app={{ installed: true, state: "crashed" }} />
    </>
  );
}

function CatalogStates() {
  return (
    <>
      <AppStateBadge app={{ installed: true }} />
      <AppStateBadge app={{ installed: false }} />
    </>
  );
}

export const InstalledStatesLight = () => (
  <Pane>
    <InstalledStates />
  </Pane>
);

export const InstalledStatesDark = () => (
  <Pane dark>
    <InstalledStates />
  </Pane>
);

export const UnknownAndAvailableLight = () => (
  <Pane>
    <CatalogStates />
  </Pane>
);

export const UnknownAndAvailableDark = () => (
  <Pane dark>
    <CatalogStates />
  </Pane>
);
