import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoNavigationBar,
  ShellBackButton,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp brightness={dark ? "dark" : "light"} style={{ width: 390 }}>
      {children}
    </CupertinoApp>
  );
}

export const WithTitleLight = () => (
  <Pane>
    <CupertinoNavigationBar
      leading={<ShellBackButton previousPageTitle="Servers" />}
      middle="Basement NAS"
    />
  </Pane>
);

export const WithTitleDark = () => (
  <Pane dark>
    <CupertinoNavigationBar
      leading={<ShellBackButton previousPageTitle="Servers" />}
      middle="Basement NAS"
    />
  </Pane>
);

export const ChevronOnlyLight = () => (
  <Pane>
    <CupertinoNavigationBar leading={<ShellBackButton />} middle="Pool tank" />
  </Pane>
);

export const ChevronOnlyDark = () => (
  <Pane dark>
    <CupertinoNavigationBar leading={<ShellBackButton />} middle="Pool tank" />
  </Pane>
);
