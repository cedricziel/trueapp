import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoButton,
  CupertinoFormRow,
  CupertinoFormSection,
  CupertinoSwitch,
  FormRowLabel,
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

function SettingsSections() {
  return (
    <>
      <CupertinoFormSection header="MENU BAR">
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Minimize to Menu Bar"
              subtitle="Close window minimizes to menu bar instead of quitting"
            />
          }
        >
          <CupertinoSwitch value />
        </CupertinoFormRow>
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Show in Dock"
              subtitle="Display app icon in dock while running"
            />
          }
        >
          <CupertinoSwitch value={false} />
        </CupertinoFormRow>
      </CupertinoFormSection>
      <CupertinoFormSection header="DATABASE">
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Clear Database"
              subtitle="Remove all servers and reset app data"
            />
          }
        >
          <CupertinoButton size="small" color="systemRed">
            Clear
          </CupertinoButton>
        </CupertinoFormRow>
      </CupertinoFormSection>
    </>
  );
}

function InsetSection() {
  return (
    <CupertinoFormSection header="SERVER" insetGrouped>
      <CupertinoFormRow prefix="Name">Basement NAS</CupertinoFormRow>
      <CupertinoFormRow prefix="Host">https://nas.local</CupertinoFormRow>
      <CupertinoFormRow prefix="Version">TrueNAS SCALE 25.04</CupertinoFormRow>
    </CupertinoFormSection>
  );
}

export const SettingsLight = () => (
  <Pane>
    <SettingsSections />
  </Pane>
);

export const SettingsDark = () => (
  <Pane dark>
    <SettingsSections />
  </Pane>
);

export const InsetGroupedLight = () => (
  <Pane>
    <InsetSection />
  </Pane>
);

export const InsetGroupedDark = () => (
  <Pane dark>
    <InsetSection />
  </Pane>
);
