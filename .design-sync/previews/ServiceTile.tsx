import type { ReactNode } from "react";
import {
  CupertinoApp,
  ServiceTile,
  type ServiceStatus,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      {children}
    </CupertinoApp>
  );
}

const smb: ServiceStatus = { id: "cifs", isRunning: true, isEnabled: true };
const ssh: ServiceStatus = { id: "ssh", isRunning: false, isEnabled: false };
const iscsi: ServiceStatus = {
  id: "iscsitarget",
  isRunning: false,
  isEnabled: true,
};

const List = () => (
  <>
    <ServiceTile service={smb} />
    <ServiceTile service={iscsi} />
    <ServiceTile service={ssh} isBusy />
  </>
);

export const RunningLight = () => (
  <Pane>
    <ServiceTile service={smb} />
  </Pane>
);

export const StoppedLight = () => (
  <Pane>
    <ServiceTile service={ssh} />
  </Pane>
);

export const BusyLight = () => (
  <Pane>
    <ServiceTile service={smb} isBusy />
  </Pane>
);

export const RunningDark = () => (
  <Pane dark>
    <ServiceTile service={smb} />
  </Pane>
);

export const StoppedDark = () => (
  <Pane dark>
    <ServiceTile service={ssh} />
  </Pane>
);

export const ListDark = () => (
  <Pane dark>
    <List />
  </Pane>
);
