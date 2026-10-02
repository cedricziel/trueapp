import type { ReactNode } from "react";
import { CupertinoApp, LoadingStateWidget } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 320 }}
    >
      {children}
    </CupertinoApp>
  );
}

export const LoadingPoolsLight = () => (
  <Pane>
    <LoadingStateWidget message="Loading pools..." />
  </Pane>
);

export const LoadingPoolsDark = () => (
  <Pane dark>
    <LoadingStateWidget message="Loading pools..." />
  </Pane>
);

export const SpinnerOnlyLight = () => (
  <Pane>
    <LoadingStateWidget />
  </Pane>
);

export const SpinnerOnlyDark = () => (
  <Pane dark>
    <LoadingStateWidget />
  </Pane>
);
