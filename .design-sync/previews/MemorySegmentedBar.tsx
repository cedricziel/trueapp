import type { ReactNode } from "react";
import {
  CupertinoApp,
  MemorySegmentedBar,
  SectionCard,
  type MemoryStats,
} from "@truenas-manager/ui";

const GiB = 1024 ** 3;

const typical: MemoryStats = {
  freeMemory: 14.2 * GiB,
  arcSize: 10.6 * GiB,
  appsMemory: 7.2 * GiB,
};

const arcHeavy: MemoryStats = {
  freeMemory: 4.8 * GiB,
  arcSize: 47.5 * GiB,
  appsMemory: 11.7 * GiB,
};

function Pane({
  dark,
  title,
  children,
}: {
  dark?: boolean;
  title: string;
  children: ReactNode;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 360 }}
    >
      <SectionCard title={title} icon="memories" iconColor="systemPurple">
        {children}
      </SectionCard>
    </CupertinoApp>
  );
}

export const TypicalLight = () => (
  <Pane title="Memory · 32 GiB">
    <MemorySegmentedBar stats={typical} />
  </Pane>
);

export const TypicalDark = () => (
  <Pane dark title="Memory · 32 GiB">
    <MemorySegmentedBar stats={typical} />
  </Pane>
);

export const ArcHeavyLight = () => (
  <Pane title="Memory · 64 GiB">
    <MemorySegmentedBar stats={arcHeavy} />
  </Pane>
);

export const ArcHeavyDark = () => (
  <Pane dark title="Memory · 64 GiB">
    <MemorySegmentedBar stats={arcHeavy} />
  </Pane>
);
