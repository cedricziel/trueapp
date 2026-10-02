import type { ReactNode } from "react";
import {
  CupertinoApp,
  TrendSparkline,
  type ColorValue,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

function Tile({
  name,
  value,
  values,
  color,
}: {
  name: string;
  value: string;
  values: number[];
  color: ColorValue;
}) {
  return (
    <div
      style={{
        padding: 12,
        background: "var(--cupertino-system-grey6)",
        borderRadius: 12,
        border: "0.5px solid var(--cupertino-separator)",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          fontSize: 13,
          marginBottom: 6,
        }}
      >
        <span style={{ color: "var(--cupertino-system-grey)" }}>{name}</span>
        <span style={{ fontWeight: 600 }}>{value}</span>
      </div>
      <TrendSparkline values={values} color={color} />
    </div>
  );
}

// 30 samples, one every 2s.
const cpuRising = [
  8, 9, 7, 10, 11, 9, 12, 14, 13, 15, 18, 17, 21, 24, 22, 27, 31, 29, 34, 38,
  36, 42, 47, 45, 51, 56, 54, 61, 66, 71,
];
const memFalling = [
  88, 87, 88, 86, 85, 85, 83, 82, 82, 80, 78, 79, 76, 74, 73, 71, 70, 68, 67,
  65, 64, 63, 61, 60, 60, 58, 57, 56, 55, 54,
];
const cpuFlat = [
  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
  12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
];

function Trends() {
  return (
    <>
      <Tile
        name="CPU · scrub on tank"
        value="71%"
        values={cpuRising}
        color="systemBlue"
      />
      <Tile
        name="Memory · ARC shrinking"
        value="54%"
        values={memFalling}
        color="systemPurple"
      />
      <Tile
        name="CPU · idle"
        value="12%"
        values={cpuFlat}
        color="systemGreen"
      />
      <Tile
        name="Network · waiting for data"
        value="—"
        values={[3]}
        color="systemTeal"
      />
    </>
  );
}

export const TrendsLight = () => (
  <Pane>
    <Trends />
  </Pane>
);

export const TrendsDark = () => (
  <Pane dark>
    <Trends />
  </Pane>
);
