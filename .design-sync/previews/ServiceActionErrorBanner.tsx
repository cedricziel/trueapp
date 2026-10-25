import type { ReactNode } from "react";
import { CupertinoApp, ServiceActionErrorBanner } from "@truenas-manager/ui";

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

const SHORT = "Failed to restart SMB: [EFAULT] Service is not enabled.";
const LONG =
  "Failed to start iSCSI: [EFAULT] Failed to start iscsitarget: no targets are configured, so the service has nothing to serve.";

export const ShortLight = () => (
  <Pane>
    <ServiceActionErrorBanner message={SHORT} onDismiss={() => {}} />
  </Pane>
);

export const ShortDark = () => (
  <Pane dark>
    <ServiceActionErrorBanner message={SHORT} onDismiss={() => {}} />
  </Pane>
);

export const LongLight = () => (
  <Pane>
    <ServiceActionErrorBanner message={LONG} onDismiss={() => {}} />
  </Pane>
);

export const LongDark = () => (
  <Pane dark>
    <ServiceActionErrorBanner message={LONG} onDismiss={() => {}} />
  </Pane>
);
