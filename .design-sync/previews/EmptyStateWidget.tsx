import type { ReactNode } from "react";
import {
  AppLogo,
  CupertinoApp,
  CupertinoButton,
  CupertinoNavigationBar,
  DeviceFrame,
  EmptyStateWidget,
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

const NoPools = () => (
  <EmptyStateWidget
    icon="square_stack_3d_down_right"
    title="No Pools"
    message="No storage pools found"
  />
);

export const NoPoolsLight = () => (
  <Pane>
    <NoPools />
  </Pane>
);

export const NoPoolsDark = () => (
  <Pane dark>
    <NoPools />
  </Pane>
);

function ServersScreen() {
  return (
    <>
      <CupertinoNavigationBar
        largeTitle="Servers"
        trailing={
          <CupertinoButton padding={0} minSize={0} style={{ fontSize: 28 }}>
            +
          </CupertinoButton>
        }
      />
      <div
        style={{
          flex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <EmptyStateWidget
          leading={<AppLogo size={64} />}
          title="No servers added yet"
          message="Tap + to add your first TrueNAS server"
        />
      </div>
    </>
  );
}

export const NoServersPhoneLight = () => (
  <DeviceFrame device="phone" brightness="light" scale={0.5}>
    <ServersScreen />
  </DeviceFrame>
);

export const NoServersPhoneDark = () => (
  <DeviceFrame device="phone" brightness="dark" scale={0.5}>
    <ServersScreen />
  </DeviceFrame>
);

export const NoServersTabletLandscapeLight = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="light"
    scale={0.4}
  >
    <ServersScreen />
  </DeviceFrame>
);

export const NoServersTabletLandscapeDark = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="dark"
    scale={0.4}
  >
    <ServersScreen />
  </DeviceFrame>
);
