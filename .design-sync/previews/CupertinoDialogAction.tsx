import type { ReactNode } from "react";
import {
  CupertinoAlertDialog,
  CupertinoApp,
  CupertinoDialogAction,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      background="systemGroupedBackground"
      style={{
        padding: 24,
        width: 318,
        display: "flex",
        justifyContent: "center",
      }}
    >
      {children}
    </CupertinoApp>
  );
}

function ActionStyles() {
  return (
    <CupertinoAlertDialog
      title="Start Scrub"
      content="Scrub pool tank now? This can take several hours."
      actions={[
        <CupertinoDialogAction>Schedule Later</CupertinoDialogAction>,
        <CupertinoDialogAction isDefaultAction>
          Start Scrub
        </CupertinoDialogAction>,
        <CupertinoDialogAction isDestructiveAction>
          Cancel Running Scrub
        </CupertinoDialogAction>,
      ]}
    />
  );
}

function SignOut() {
  return (
    <CupertinoAlertDialog
      title="Sign Out"
      content="Sign out of Basement NAS? You'll need your password to reconnect."
      actions={[
        <CupertinoDialogAction>Cancel</CupertinoDialogAction>,
        <CupertinoDialogAction isDefaultAction isDestructiveAction>
          Sign Out
        </CupertinoDialogAction>,
      ]}
    />
  );
}

export const ActionStylesLight = () => (
  <Pane>
    <ActionStyles />
  </Pane>
);

export const ActionStylesDark = () => (
  <Pane dark>
    <ActionStyles />
  </Pane>
);

export const SideBySideLight = () => (
  <Pane>
    <SignOut />
  </Pane>
);

export const SideBySideDark = () => (
  <Pane dark>
    <SignOut />
  </Pane>
);
