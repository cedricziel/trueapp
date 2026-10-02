import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoFormRow,
  CupertinoFormSection,
  CupertinoSwitch,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      background="systemGroupedBackground"
      style={{ paddingBottom: 16, width: 390 }}
    >
      {children}
    </CupertinoApp>
  );
}

function States() {
  return (
    <CupertinoFormSection
      header="MENU BAR"
      footer="Launch at Login is managed by your administrator."
    >
      <CupertinoFormRow prefix="Show in Dock">
        <CupertinoSwitch value />
      </CupertinoFormRow>
      <CupertinoFormRow prefix="Show Job Notifications">
        <CupertinoSwitch value={false} />
      </CupertinoFormRow>
      <CupertinoFormRow prefix="Launch at Login (on)">
        <CupertinoSwitch value disabled />
      </CupertinoFormRow>
      <CupertinoFormRow prefix="Launch at Login (off)">
        <CupertinoSwitch value={false} disabled />
      </CupertinoFormRow>
    </CupertinoFormSection>
  );
}

export const StatesLight = () => (
  <Pane>
    <States />
  </Pane>
);

export const StatesDark = () => (
  <Pane dark>
    <States />
  </Pane>
);
