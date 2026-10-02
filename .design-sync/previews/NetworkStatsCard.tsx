import type { ReactNode } from "react";
import {
  CupertinoApp,
  NetworkStatsCard,
  type NetworkInterfaceStats,
} from "@truenas-manager/ui";

// eno3 is down and is filtered out by the card.
const interfaces: NetworkInterfaceStats[] = [
  { name: "eno1", receivedRate: "84.6 MB/s", sentRate: "2.3 MB/s", isUp: true },
  { name: "eno2", receivedRate: "1.2 MB/s", sentRate: "38.9 MB/s", isUp: true },
  { name: "eno3", receivedRate: "0 B/s", sentRate: "0 B/s", isUp: false },
];

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

export const InterfacesLight = () => (
  <Pane>
    <NetworkStatsCard interfaces={interfaces} />
  </Pane>
);

export const InterfacesDark = () => (
  <Pane dark>
    <NetworkStatsCard interfaces={interfaces} />
  </Pane>
);
