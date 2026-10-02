import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoIcon,
  CupertinoTextField,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 390 }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        {children}
      </div>
    </CupertinoApp>
  );
}

function Caption({ children }: { children: ReactNode }) {
  return (
    <span
      style={{
        fontSize: 13,
        color: "var(--cupertino-secondary-label)",
        marginBottom: -6,
      }}
    >
      {children}
    </span>
  );
}

function Fields() {
  return (
    <>
      <Caption>Trusted Wi-Fi SSID</Caption>
      <CupertinoTextField
        value="HomeNet-5G"
        prefix={<CupertinoIcon icon="wifi" size={18} color="systemGrey" />}
      />
      <CupertinoTextField
        placeholder="Add another SSID"
        prefix={<CupertinoIcon icon="wifi" size={18} color="systemGrey" />}
      />
      <Caption>API key</Caption>
      <CupertinoTextField monospace value="1-qA8fJz3kT0wV7mLx2Rb9cE4" />
      <Caption>Password</Caption>
      <CupertinoTextField value="correct-horse" obscureText />
    </>
  );
}

export const FieldsLight = () => (
  <Pane>
    <Fields />
  </Pane>
);

export const FieldsDark = () => (
  <Pane dark>
    <Fields />
  </Pane>
);
