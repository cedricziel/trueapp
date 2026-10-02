import type { ReactNode } from "react";
import { CupertinoActivityIndicator, CupertinoApp } from "@truenas-manager/ui";

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
    <div style={{ display: "flex", alignItems: "flex-end", gap: 24 }}>
      {[8, 10, 14, 20].map((r) => (
        <div
          key={r}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 8,
          }}
        >
          <CupertinoActivityIndicator radius={r} animating={false} />
          <span
            style={{ fontSize: 11, color: "var(--cupertino-secondary-label)" }}
          >
            radius {r}
          </span>
        </div>
      ))}
    </div>
  );
}

function Row({ children }: { children: ReactNode }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      {children}
    </div>
  );
}

function InContext() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <Row>
        <CupertinoActivityIndicator animating={false} />
        <span style={{ fontSize: 15 }}>Connecting to Basement NAS…</span>
      </Row>
      <Row>
        <CupertinoActivityIndicator
          radius={8}
          color="systemBlue"
          animating={false}
        />
        <span style={{ fontSize: 15 }}>pool.scrub on tank</span>
      </Row>
      <Row>
        <CupertinoActivityIndicator
          radius={8}
          color="systemOrange"
          animating={false}
        />
        <span style={{ fontSize: 15 }}>Reconnecting…</span>
      </Row>
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

export const InContextLight = () => (
  <Pane>
    <InContext />
  </Pane>
);

export const InContextDark = () => (
  <Pane dark>
    <InContext />
  </Pane>
);
