import type { ReactNode } from "react";
import { CupertinoApp, ErrorStateWidget } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      {children}
    </CupertinoApp>
  );
}

const retry = () => {};

const PoolError = () => (
  <ErrorStateWidget
    title="Pool Error"
    message="Failed to load pools: request to pool.query timed out after 30s"
    onRetry={retry}
  />
);

export const PoolErrorWithRetryLight = () => (
  <Pane>
    <PoolError />
  </Pane>
);

export const PoolErrorWithRetryDark = () => (
  <Pane dark>
    <PoolError />
  </Pane>
);

const HealthError = () => (
  <ErrorStateWidget
    icon="exclamationmark_shield"
    title="Could Not Load Health"
    message="Your account lacks the READONLY_ADMIN role needed to read alerts."
  />
);

export const HealthNoRetryLight = () => (
  <Pane>
    <HealthError />
  </Pane>
);

export const HealthNoRetryDark = () => (
  <Pane dark>
    <HealthError />
  </Pane>
);
