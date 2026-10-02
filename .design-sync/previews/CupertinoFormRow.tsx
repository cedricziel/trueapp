import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoFormRow,
  CupertinoFormSection,
  CupertinoIcon,
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

function RowKinds() {
  return (
    <CupertinoFormSection header="CONNECTION">
      <CupertinoFormRow prefix="Server">Basement NAS</CupertinoFormRow>
      <CupertinoFormRow prefix="Trusted Wi-Fi" onClick={() => {}}>
        <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
          2 networks
          <CupertinoIcon icon="chevron_right" size={18} color="systemGrey2" />
        </span>
      </CupertinoFormRow>
      <CupertinoFormRow
        prefix={
          <FormRowLabel
            title="Auto-reconnect"
            subtitle="Reconnect when the app returns to the foreground"
          />
        }
      >
        <CupertinoSwitch value />
      </CupertinoFormRow>
    </CupertinoFormSection>
  );
}

function HelperAndError() {
  return (
    <CupertinoFormSection header="ADD SERVER">
      <CupertinoFormRow
        prefix="Port"
        helper="Leave empty to use 443 for HTTPS."
      >
        443
      </CupertinoFormRow>
      <CupertinoFormRow
        prefix="Host"
        error="Enter a valid URL, e.g. https://nas.local"
      >
        nas.local:abc
      </CupertinoFormRow>
    </CupertinoFormSection>
  );
}

export const RowKindsLight = () => (
  <Pane>
    <RowKinds />
  </Pane>
);

export const RowKindsDark = () => (
  <Pane dark>
    <RowKinds />
  </Pane>
);

export const HelperAndErrorLight = () => (
  <Pane>
    <HelperAndError />
  </Pane>
);

export const HelperAndErrorDark = () => (
  <Pane dark>
    <HelperAndError />
  </Pane>
);
