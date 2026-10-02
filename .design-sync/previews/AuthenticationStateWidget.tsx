import type { ReactNode } from "react";
import {
  AuthenticationStateWidget,
  CupertinoApp,
  CupertinoNavigationBar,
  DeviceFrame,
  ShellBackButton,
  type AuthenticationState,
} from "@truenas-manager/ui";

const noop = () => {};

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 420 }}
    >
      {children}
    </CupertinoApp>
  );
}

function Gate({ state }: { state: AuthenticationState }) {
  return (
    <AuthenticationStateWidget
      state={state}
      error={
        state === "failed"
          ? "Face ID did not match. Try again or use your passcode."
          : "Unlock to view Basement NAS."
      }
      serverName="Basement NAS"
      onAuthenticate={noop}
    />
  );
}

export const AuthenticatingLight = () => (
  <Pane>
    <Gate state="authenticating" />
  </Pane>
);

export const AuthenticatingDark = () => (
  <Pane dark>
    <Gate state="authenticating" />
  </Pane>
);

export const RequiredLight = () => (
  <Pane>
    <Gate state="required" />
  </Pane>
);

export const FailedDark = () => (
  <Pane dark>
    <Gate state="failed" />
  </Pane>
);

function LockedScreen({ state }: { state: AuthenticationState }) {
  return (
    <>
      <CupertinoNavigationBar
        leading={<ShellBackButton previousPageTitle="Servers" />}
        middle="Basement NAS"
      />
      <div
        style={{
          flex: 1,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <Gate state={state} />
      </div>
    </>
  );
}

export const RequiredPhonePortraitDark = () => (
  <DeviceFrame device="phone" brightness="dark" scale={0.5}>
    <LockedScreen state="required" />
  </DeviceFrame>
);

export const FailedPhonePortraitLight = () => (
  <DeviceFrame device="phone" brightness="light" scale={0.5}>
    <LockedScreen state="failed" />
  </DeviceFrame>
);

export const RequiredTabletLandscapeLight = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="light"
    scale={0.4}
  >
    <LockedScreen state="required" />
  </DeviceFrame>
);

export const FailedTabletLandscapeDark = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="dark"
    scale={0.4}
  >
    <LockedScreen state="failed" />
  </DeviceFrame>
);
