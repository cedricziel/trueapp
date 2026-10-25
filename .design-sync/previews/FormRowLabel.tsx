import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoButton,
  CupertinoSwitch,
  FormRowLabel,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      background="systemGroupedBackground"
      style={{ padding: 16, width: 380 }}
    >
      <div
        style={{
          borderRadius: 10,
          overflow: "hidden",
          background: "var(--cupertino-secondary-system-grouped-background)",
        }}
      >
        {children}
      </div>
    </CupertinoApp>
  );
}

function Row({ children, last }: { children: ReactNode; last?: boolean }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        gap: 12,
        padding: "10px 16px",
        borderBottom: last
          ? undefined
          : "0.5px solid var(--cupertino-separator)",
      }}
    >
      {children}
    </div>
  );
}

function SettingsRows() {
  return (
    <>
      <Row>
        <FormRowLabel
          title="Minimize to Menu Bar"
          subtitle="Close window minimizes to menu bar instead of quitting"
        />
        <CupertinoSwitch value />
      </Row>
      <Row>
        <FormRowLabel
          title="Show in Dock"
          subtitle="Display app icon in dock while running"
        />
        <CupertinoSwitch value={false} />
      </Row>
      <Row last>
        <FormRowLabel
          title="Clear Database"
          subtitle="Removes cached servers, jobs and metrics from this device"
        />
        <CupertinoButton size="small" variant="filled" color="destructiveRed">
          Clear
        </CupertinoButton>
      </Row>
    </>
  );
}

export const SettingsRowsLight = () => (
  <Pane>
    <SettingsRows />
  </Pane>
);

export const SettingsRowsDark = () => (
  <Pane dark>
    <SettingsRows />
  </Pane>
);
