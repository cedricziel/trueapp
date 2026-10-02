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
  width,
  children,
}: {
  dark?: boolean;
  width: number;
  children: ReactNode;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ width, paddingBottom: 24 }}
    >
      {children}
    </CupertinoApp>
  );
}

function ServerBar() {
  return (
    <CupertinoNavigationBar
      leading={<ShellBackButton previousPageTitle="Servers" />}
      middle="Basement NAS"
      trailing={
        <>
          <ConnectionStatusTitleWidget state="connected" />
          <JobsBellButton runningCount={2} />
        </>
      }
    />
  );
}

function ServersLargeTitle() {
  return (
    <CupertinoNavigationBar
      largeTitle="Servers"
      trailing={<JobsBellButton needsAttention />}
    />
  );
}

export const PhoneLight = () => (
  <Pane width={390}>
    <ServerBar />
  </Pane>
);

export const PhoneDark = () => (
  <Pane dark width={390}>
    <ServerBar />
  </Pane>
);

export const LargeTitleLight = () => (
  <Pane width={390}>
    <ServersLargeTitle />
  </Pane>
);

export const LargeTitleDark = () => (
  <Pane dark width={390}>
    <ServersLargeTitle />
  </Pane>
);

export const WideLight = () => (
  <Pane width={840}>
    <ServerBar />
  </Pane>
);

export const WideDark = () => (
  <Pane dark width={840}>
    <ServerBar />
  </Pane>
);
