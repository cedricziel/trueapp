import type { ReactNode } from "react";
import {
  ConnectionStatusTitleWidget,
  CupertinoApp,
  CupertinoNavigationBar,
  JobsBellButton,
  ShellBackButton,
} from "@truenas-manager/ui";

function Pane({
  dark,
  width = 300,
  children,
}: {
  dark?: boolean;
  width?: number;
  children: ReactNode;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width }}
    >
      {children}
    </CupertinoApp>
  );
}

const Labeled = ({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) => (
  <div
    style={{
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      gap: 6,
      fontSize: 11,
      color: "var(--cupertino-system-grey)",
    }}
  >
    {children}
    {label}
  </div>
);

const AllStates = () => (
  <div style={{ display: "flex", gap: 14, justifyContent: "space-between" }}>
    <Labeled label="Healthy">
      <ConnectionStatusTitleWidget state="connected" />
    </Labeled>
    <Labeled label="Unhealthy">
      <ConnectionStatusTitleWidget state="connected" isHealthy={false} />
    </Labeled>
    <Labeled label="Connecting">
      <ConnectionStatusTitleWidget state="connecting" />
    </Labeled>
    <Labeled label="Error">
      <ConnectionStatusTitleWidget state="error" />
    </Labeled>
    <Labeled label="Offline">
      <ConnectionStatusTitleWidget state="disconnected" />
    </Labeled>
  </div>
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

const InNavBar = () => (
  <CupertinoNavigationBar
    leading={<ShellBackButton previousPageTitle="Servers" />}
    middle="Basement NAS"
    trailing={
      <>
        <ConnectionStatusTitleWidget state="reconnecting" />
        <JobsBellButton />
      </>
    }
  />
);

export const InNavBarLight = () => (
  <Pane width={420}>
    <InNavBar />
  </Pane>
);

export const InNavBarDark = () => (
  <Pane dark width={420}>
    <InNavBar />
  </Pane>
);
