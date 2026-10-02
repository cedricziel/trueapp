import type { ReactNode } from "react";
import { CupertinoApp, UsageBar, type ColorValue } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

function Labeled({
  name,
  usage,
  color,
  height,
}: {
  name: string;
  usage: number;
  color: ColorValue;
  height?: number;
}) {
  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          fontSize: 13,
          marginBottom: 6,
        }}
      >
        <span>{name}</span>
        <span style={{ color: "var(--cupertino-system-grey)" }}>{usage}%</span>
      </div>
      <UsageBar usage={usage} color={color} height={height} />
    </div>
  );
}

function Levels() {
  return (
    <>
      <Labeled name="backup" usage={23} color="systemGreen" />
      <Labeled name="tank" usage={68} color="systemOrange" />
      <Labeled name="boot-pool" usage={94} color="systemRed" />
    </>
  );
}

function Heights() {
  return (
    <>
      <Labeled name="CPU · 4px" usage={42} color="systemBlue" height={4} />
      <Labeled name="Memory · 8px" usage={71} color="systemPurple" />
      <Labeled
        name="tank capacity · 14px"
        usage={86}
        color="systemOrange"
        height={14}
      />
    </>
  );
}

export const UsageLevelsLight = () => (
  <Pane>
    <Levels />
  </Pane>
);

export const UsageLevelsDark = () => (
  <Pane dark>
    <Levels />
  </Pane>
);

export const CustomHeightLight = () => (
  <Pane>
    <Heights />
  </Pane>
);

export const CustomHeightDark = () => (
  <Pane dark>
    <Heights />
  </Pane>
);
