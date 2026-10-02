import type { ReactNode } from "react";
import {
  ConnectionStatusWidget,
  CupertinoApp,
  type TrueNASConnectionState,
} from "@truenas-manager/ui";

const STATES: TrueNASConnectionState[] = [
  "connected",
  "connecting",
  "reconnecting",
  "error",
  "disconnected",
];

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 220 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

const AllStates = () => (
  <>
    <ConnectionStatusWidget state="connected" latencyMs={24} />
    <ConnectionStatusWidget state="connected" isHealthy={false} />
    {STATES.slice(1).map((s) => (
      <ConnectionStatusWidget key={s} state={s} />
    ))}
  </>
);

export const AllStatesLight = () => (
  <Pane>
    <AllStates />
  </Pane>
);

export const AllStatesDark = () => (
  <Pane dark>
    <AllStates />
  </Pane>
);

const Dots = () => (
  <>
    {STATES.map((s) => (
      <span
        key={s}
        style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13 }}
      >
        <ConnectionStatusWidget state={s} compact />
        {s[0].toUpperCase() + s.slice(1)}
      </span>
    ))}
  </>
);

export const CompactDotsLight = () => (
  <Pane>
    <Dots />
  </Pane>
);

export const CompactDotsDark = () => (
  <Pane dark>
    <Dots />
  </Pane>
);
