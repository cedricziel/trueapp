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
      <CupertinoFormSection header="SECURITY">
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Authentication Session"
              subtitle="Manage biometric authentication session"
            />
          }
        >
          <CupertinoButton size="small">Lock Session</CupertinoButton>
        </CupertinoFormRow>
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
      <CupertinoFormSection
        header="MENU BAR"
        footer="Changes apply the next time TrueNAS Manager launches."
      >
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Show in Dock"
              subtitle="Display app icon in dock while running"
            />
          }
        >
          <CupertinoSwitch value />
        </CupertinoFormRow>
        <CupertinoFormRow prefix="Launch at Login">
          <CupertinoSwitch value={false} />
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
