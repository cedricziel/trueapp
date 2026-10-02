import type { ReactNode } from "react";
import {
  AppCardWidget,
  CupertinoApp,
  CupertinoSearchTextField,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 390 }}
    >
      {children}
    </CupertinoApp>
  );
}

export const EmptyLight = () => (
  <Pane>
    <CupertinoSearchTextField placeholder="Search apps" />
  </Pane>
);

export const EmptyDark = () => (
  <Pane dark>
    <CupertinoSearchTextField placeholder="Search apps" />
  </Pane>
);

function Filtered() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <CupertinoSearchTextField placeholder="Search apps" value="jelly" />
      <AppCardWidget
        app={{
          name: "Jellyfin",
          description: "Free software media system for movies and TV",
          installed: true,
          healthy: true,
          latestAppVersion: "10.10.3",
          categories: ["media"],
        }}
      />
    </div>
  );
}

export const WithQueryLight = () => (
  <Pane>
    <Filtered />
  </Pane>
);

export const WithQueryDark = () => (
  <Pane dark>
    <Filtered />
  </Pane>
);
