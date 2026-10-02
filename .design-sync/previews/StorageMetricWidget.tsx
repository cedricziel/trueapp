import type { ReactNode } from "react";
import { CupertinoApp, StorageMetricWidget } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      <div
        style={{
          padding: 16,
          background: "var(--cupertino-system-grey6)",
          borderRadius: 12,
          border: "0.5px solid var(--cupertino-separator)",
          display: "flex",
          justifyContent: "space-around",
        }}
      >
        {children}
      </div>
    </CupertinoApp>
  );
}

function Healthy() {
  return (
    <>
      <StorageMetricWidget label="Used" value="3.1TB" color="systemBlue" />
      <StorageMetricWidget
        label="Available"
        value="7.6TB"
        color="systemGreen"
      />
      <StorageMetricWidget label="Total" value="10.7TB" color="label" />
    </>
  );
}

function NearlyFull() {
  return (
    <>
      <StorageMetricWidget label="Used" value="3.4TB" color="systemRed" />
      <StorageMetricWidget
        label="Available"
        value="186.2GB"
        color="systemOrange"
      />
      <StorageMetricWidget label="Total" value="3.6TB" color="label" />
    </>
  );
}

export const PoolTankLight = () => (
  <Pane>
    <Healthy />
  </Pane>
);

export const PoolTankDark = () => (
  <Pane dark>
    <Healthy />
  </Pane>
);

export const PoolNearlyFullLight = () => (
  <Pane>
    <NearlyFull />
  </Pane>
);

export const PoolNearlyFullDark = () => (
  <Pane dark>
    <NearlyFull />
  </Pane>
);
