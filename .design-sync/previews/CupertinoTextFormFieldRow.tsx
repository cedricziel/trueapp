import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoFormSection,
  CupertinoTextFormFieldRow,
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

function AddServerForm({ withError }: { withError?: boolean }) {
  return (
    <>
      <CupertinoFormSection header="SERVER">
        <CupertinoTextFormFieldRow prefix="Name" value="Basement NAS" />
        <CupertinoTextFormFieldRow
          prefix="Host"
          value={withError ? "nas.local:abc" : "https://nas.local"}
          error={
            withError ? "Enter a valid URL, e.g. https://nas.local" : undefined
          }
        />
        <CupertinoTextFormFieldRow prefix="Port" placeholder="443" />
      </CupertinoFormSection>
      <CupertinoFormSection header="CREDENTIALS">
        <CupertinoTextFormFieldRow prefix="Username" value="admin" />
        <CupertinoTextFormFieldRow
          prefix="Password"
          value="correct-horse"
          obscureText
          error={withError ? "Password is required" : undefined}
        />
      </CupertinoFormSection>
    </>
  );
}

export const AddServerLight = () => (
  <Pane>
    <AddServerForm />
  </Pane>
);

export const AddServerDark = () => (
  <Pane dark>
    <AddServerForm />
  </Pane>
);

export const ValidationErrorLight = () => (
  <Pane>
    <AddServerForm withError />
  </Pane>
);

export const ValidationErrorDark = () => (
  <Pane dark>
    <AddServerForm withError />
  </Pane>
);
