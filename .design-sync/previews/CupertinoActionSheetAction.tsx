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

function ActionStyles() {
  return (
    <CupertinoActionSheet
      title="Pool tank"
      actions={[
        <CupertinoActionSheetAction>View Datasets</CupertinoActionSheetAction>,
        <CupertinoActionSheetAction isDefaultAction>
          Start Scrub
        </CupertinoActionSheetAction>,
        <CupertinoActionSheetAction isDestructiveAction>
          Export Pool
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
