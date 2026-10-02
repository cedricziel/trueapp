import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoButton,
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
          title="Biometric Unlock"
          subtitle="Require Face ID to open server details"
        />
        <CupertinoButton size="small">Enable</CupertinoButton>
      </Row>
      <Row>
        <FormRowLabel
          title="Session Timeout"
          subtitle="Lock again after 15 minutes of inactivity"
        />
        <CupertinoButton size="small">15 min</CupertinoButton>
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
