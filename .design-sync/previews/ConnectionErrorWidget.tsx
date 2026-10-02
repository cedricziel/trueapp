import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoNavigationBar,
  ConnectionErrorWidget,
  DeviceFrame,
  ShellBackButton,
  type ConnectionError,
} from "@truenas-manager/ui";

const noop = () => {};

const unreachable: ConnectionError = {
  type: "networkUnreachable",
  shortMessage: "Server not reachable",
  userFriendlyMessage:
    "Cannot reach the server. Check the IP address or hostname, your network connection, and that the server is powered on.",
  isRetryable: true,
  technicalDetails:
    "SocketException: Connection refused (OS Error: errno = 61), address = 192.168.1.40, port = 443",
};

const timeout: ConnectionError = {
  type: "connectionTimeout",
  shortMessage: "Connection timed out",
  userFriendlyMessage:
    "Connection timed out. Check that the server is responding, your network connectivity, and firewall settings.",
  isRetryable: true,
};

const credentials: ConnectionError = {
  type: "invalidCredentials",
  shortMessage: "Invalid credentials",
  userFriendlyMessage:
    "Username or password is incorrect. Check your credentials, make sure caps lock is off, and that the account is not locked.",
  isRetryable: false,
  technicalDetails: "auth.login_ex: FAILURE (EINVAL)",
};

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 380 }}
    >
      {children}
    </CupertinoApp>
  );
}

export const UnreachableWithDetailsLight = () => (
  <Pane>
    <ConnectionErrorWidget
      error={unreachable}
      onRetry={noop}
      onSettings={noop}
      onShowDetails={noop}
    />
  </Pane>
);

export const UnreachableWithDetailsDark = () => (
  <Pane dark>
    <ConnectionErrorWidget
      error={unreachable}
      onRetry={noop}
      onSettings={noop}
      onShowDetails={noop}
    />
  </Pane>
);

export const TimeoutLight = () => (
  <Pane>
    <ConnectionErrorWidget error={timeout} onRetry={noop} onSettings={noop} />
  </Pane>
);

export const InvalidCredentialsDark = () => (
  <Pane dark>
    <ConnectionErrorWidget
      error={credentials}
      onRetry={noop}
      onSettings={noop}
      onShowDetails={noop}
    />
  </Pane>
);

function ServerScreen({ error }: { error: ConnectionError }) {
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
        <ConnectionErrorWidget
          error={error}
          onRetry={noop}
          onSettings={noop}
          onShowDetails={noop}
        />
      </div>
    </>
  );
}

export const PhonePortraitLight = () => (
  <DeviceFrame device="phone" brightness="light" scale={0.5}>
    <ServerScreen error={unreachable} />
  </DeviceFrame>
);

export const PhonePortraitDark = () => (
  <DeviceFrame device="phone" brightness="dark" scale={0.5}>
    <ServerScreen error={unreachable} />
  </DeviceFrame>
);

export const TabletLandscapeLight = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="light"
    scale={0.4}
  >
    <ServerScreen error={timeout} />
  </DeviceFrame>
);

export const TabletLandscapeDark = () => (
  <DeviceFrame
    device="tablet"
    orientation="landscape"
    brightness="dark"
    scale={0.4}
  >
    <ServerScreen error={timeout} />
  </DeviceFrame>
);
