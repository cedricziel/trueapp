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

function DeleteServer() {
  return (
    <CupertinoAlertDialog
      title="Delete Server"
      content='Remove "Basement NAS" (https://nas.local)? Its saved password will be removed from the Keychain.'
      actions={[
        <CupertinoDialogAction isDefaultAction>Cancel</CupertinoDialogAction>,
        <CupertinoDialogAction isDestructiveAction>
          Delete
        </CupertinoDialogAction>,
      ]}
    />
  );
}

function AppActions() {
  return (
    <CupertinoAlertDialog
      title="Jellyfin"
      content="Jellyfin is running on Basement NAS. What would you like to do?"
      actions={[
        <CupertinoDialogAction>Restart</CupertinoDialogAction>,
        <CupertinoDialogAction isDestructiveAction>
          Stop App
        </CupertinoDialogAction>,
        <CupertinoDialogAction isDefaultAction>Cancel</CupertinoDialogAction>,
      ]}
    />
  );
}

export const DeleteServerLight = () => (
  <Pane>
    <DeleteServer />
  </Pane>
);

export const DeleteServerDark = () => (
  <Pane dark>
    <DeleteServer />
  </Pane>
);

export const StackedActionsLight = () => (
  <Pane>
    <AppActions />
  </Pane>
);

export const StackedActionsDark = () => (
  <Pane dark>
    <AppActions />
  </Pane>
);
