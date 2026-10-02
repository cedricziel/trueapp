import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoButton,
  CupertinoIcon,
} from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 340 }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-start",
          gap: 12,
        }}
      >
        {children}
      </div>
    </CupertinoApp>
  );
}

function Filled() {
  return (
    <>
      <CupertinoButton variant="filled" size="large" style={{ width: "100%" }}>
        Connect to Server
      </CupertinoButton>
      <CupertinoButton variant="filled" size="medium">
        Start Scrub
      </CupertinoButton>
      <CupertinoButton variant="filled" size="small">
        Upgrade
      </CupertinoButton>
      <CupertinoButton variant="filled" size="medium" color="systemRed">
        <CupertinoIcon icon="delete" size={18} />
        Delete Server
      </CupertinoButton>
      <CupertinoButton
        variant="filled"
        size="large"
        disabled
        style={{ width: "100%" }}
      >
        Saving…
      </CupertinoButton>
    </>
  );
}

function Plain() {
  return (
    <>
      <CupertinoButton size="large">Add Server</CupertinoButton>
      <CupertinoButton size="medium">
        <CupertinoIcon icon="refresh" size={20} />
        Refresh
      </CupertinoButton>
      <CupertinoButton size="small">View all jobs</CupertinoButton>
      <CupertinoButton size="medium" color="systemRed">
        Stop Jellyfin
      </CupertinoButton>
      <CupertinoButton size="medium" disabled>
        Restart Nextcloud
      </CupertinoButton>
    </>
  );
}

export const FilledLight = () => (
  <Pane>
    <Filled />
  </Pane>
);

export const FilledDark = () => (
  <Pane dark>
    <Filled />
  </Pane>
);

export const PlainLight = () => (
  <Pane>
    <Plain />
  </Pane>
);

export const PlainDark = () => (
  <Pane dark>
    <Plain />
  </Pane>
);
