import type { ReactNode } from "react";
import { CupertinoApp, StatusPill } from "@truenas-manager/ui";

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

function WithIcons() {
  return (
    <>
      <StatusPill
        label="ONLINE"
        color="systemGreen"
        icon="checkmark_circle_fill"
      />
      <StatusPill
        label="DEGRADED"
        color="systemOrange"
        icon="exclamationmark_triangle_fill"
      />
      <StatusPill label="FAULTED" color="systemRed" icon="xmark_circle_fill" />
      <StatusPill label="Scrubbing" color="systemBlue" icon="arrow_clockwise" />
      <StatusPill label="Encrypted" color="systemPurple" icon="lock" />
    </>
  );
}

function TextOnly() {
  return (
    <>
      <StatusPill label="RUNNING" color="systemGreen" />
      <StatusPill label="STOPPED" color="systemGrey" />
      <StatusPill label="Update available" color="systemOrange" />
      <StatusPill label="Deploying" color="systemBlue" />
      <StatusPill label="RAIDZ2" color="systemIndigo" />
    </>
  );
}

export const WithIconLight = () => (
  <Pane>
    <WithIcons />
  </Pane>
);

export const WithIconDark = () => (
  <Pane dark>
    <WithIcons />
  </Pane>
);

export const TextOnlyLight = () => (
  <Pane>
    <TextOnly />
  </Pane>
);

export const TextOnlyDark = () => (
  <Pane dark>
    <TextOnly />
  </Pane>
);
