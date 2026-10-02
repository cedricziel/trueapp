import type { ReactNode } from "react";
import {
  CompactConnectionErrorWidget,
  CupertinoApp,
  type ConnectionError,
} from "@truenas-manager/ui";

const noop = () => {};

const timeout: ConnectionError = {
  type: "connectionTimeout",
  shortMessage: "Connection timed out",
  userFriendlyMessage: "Connection timed out.",
  isRetryable: true,
};

const denied: ConnectionError = {
  type: "permissionDenied",
  shortMessage: "Permission denied",
  userFriendlyMessage: "Access denied.",
  isRetryable: false,
};

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 360 }}
    >
      {children}
    </CupertinoApp>
  );
}

export const RetryableLight = () => (
  <Pane>
    <CompactConnectionErrorWidget error={timeout} onRetry={noop} />
  </Pane>
);

export const RetryableDark = () => (
  <Pane dark>
    <CompactConnectionErrorWidget error={timeout} onRetry={noop} />
  </Pane>
);

export const NotRetryableLight = () => (
  <Pane>
    <CompactConnectionErrorWidget error={denied} onRetry={noop} />
  </Pane>
);

export const NotRetryableDark = () => (
  <Pane dark>
    <CompactConnectionErrorWidget error={denied} onRetry={noop} />
  </Pane>
);
