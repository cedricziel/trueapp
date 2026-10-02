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
  width = 260,
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
      gap: 4,
      fontSize: 11,
      color: "var(--cupertino-system-grey)",
    }}
  >
    {children}
    {label}
  </div>
);

const AllStates = () => (
  <div style={{ display: "flex", justifyContent: "space-around" }}>
    <Labeled label="Idle">
      <JobsBellButton />
    </Labeled>
    <Labeled label="3 running">
      <JobsBellButton runningCount={3} />
    </Labeled>
    <Labeled label="12 running">
      <JobsBellButton runningCount={12} />
    </Labeled>
    <Labeled label="Failed">
      <JobsBellButton needsAttention />
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
    middle="Pools"
    trailing={
      <>
        <ConnectionStatusTitleWidget state="connected" />
        <JobsBellButton runningCount={2} />
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
