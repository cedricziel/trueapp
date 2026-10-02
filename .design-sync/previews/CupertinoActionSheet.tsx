import type { ReactNode } from "react";
import {
  CupertinoActionSheet,
  CupertinoActionSheetAction,
  CupertinoApp,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      background="systemGroupedBackground"
      style={{ paddingTop: 24, width: 390 }}
    >
      {children}
    </CupertinoApp>
  );
}

function ServerSheet() {
  return (
    <CupertinoActionSheet
      title="Basement NAS"
      message="https://nas.local"
      actions={[
        <CupertinoActionSheetAction>Edit Server</CupertinoActionSheetAction>,
      ]}
      cancelButton={
        <CupertinoActionSheetAction isDefaultAction>
          Cancel
        </CupertinoActionSheetAction>
      }
    />
  );
}

function JellyfinSheet() {
  return (
    <CupertinoActionSheet
      title="Jellyfin"
      message="Running · 10.10.3"
      actions={[
        <CupertinoActionSheetAction>Open Web UI</CupertinoActionSheetAction>,
        <CupertinoActionSheetAction>Restart</CupertinoActionSheetAction>,
        <CupertinoActionSheetAction>
          Upgrade to 10.10.4
        </CupertinoActionSheetAction>,
        <CupertinoActionSheetAction isDestructiveAction>
          Stop App
        </CupertinoActionSheetAction>,
      ]}
      cancelButton={
        <CupertinoActionSheetAction isDefaultAction>
          Cancel
        </CupertinoActionSheetAction>
      }
    />
  );
}

export const EditServerLight = () => (
  <Pane>
    <ServerSheet />
  </Pane>
);

export const EditServerDark = () => (
  <Pane dark>
    <ServerSheet />
  </Pane>
);

export const AppActionsLight = () => (
  <Pane>
    <JellyfinSheet />
  </Pane>
);

export const AppActionsDark = () => (
  <Pane dark>
    <JellyfinSheet />
  </Pane>
);
