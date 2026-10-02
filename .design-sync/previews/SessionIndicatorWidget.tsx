import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoNavigationBar,
  JobsBellButton,
  SessionIndicatorWidget,
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
    <Labeled label="12 min left">
      <SessionIndicatorWidget minutesRemaining={12} />
    </Labeled>
    <Labeled label="3 min left">
      <SessionIndicatorWidget minutesRemaining={3} />
    </Labeled>
    <Labeled label="Countdown">
      <SessionIndicatorWidget
        minutesRemaining={14}
        secondsRemaining={7}
        showCountdown
      />
    </Labeled>
    <Labeled label="Expiring">
      <SessionIndicatorWidget
        minutesRemaining={0}
        secondsRemaining={42}
        showCountdown
      />
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
        <SessionIndicatorWidget
          minutesRemaining={4}
          secondsRemaining={18}
          showCountdown
        />
        <JobsBellButton needsAttention />
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
