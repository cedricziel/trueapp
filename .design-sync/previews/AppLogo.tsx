import type { ReactNode } from "react";
import { AppLogo, CupertinoApp } from "@truenas-manager/ui";

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

function Sizes() {
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 20 }}>
      {[22, 32, 48, 72].map((s) => (
        <div
          key={s}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 6,
          }}
        >
          <AppLogo size={s} />
          <span
            style={{ fontSize: 11, color: "var(--cupertino-secondary-label)" }}
          >
            {s}px
          </span>
        </div>
      ))}
    </div>
  );
}

function Welcome() {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 12,
        padding: "12px 0",
      }}
    >
      <AppLogo size={72} />
      <div style={{ fontSize: 22, fontWeight: 700 }}>TrueNAS Manager</div>
      <div
        style={{
          fontSize: 15,
          color: "var(--cupertino-secondary-label)",
          textAlign: "center",
        }}
      >
        Monitor pools, apps and jobs across your TrueNAS servers.
      </div>
    </div>
  );
}

export const SizesLight = () => (
  <Pane>
    <Sizes />
  </Pane>
);

export const SizesDark = () => (
  <Pane dark>
    <Sizes />
  </Pane>
);

export const WelcomeLight = () => (
  <Pane>
    <Welcome />
  </Pane>
);

export const WelcomeDark = () => (
  <Pane dark>
    <Welcome />
  </Pane>
);
