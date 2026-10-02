import type { ReactNode } from "react";
import { CupertinoApp, JobCardWidget } from "@truenas-manager/ui";

function Pane({ dark, children }: { dark?: boolean; children: ReactNode }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{
        padding: 16,
        width: 380,
        display: "flex",
        flexDirection: "column",
        gap: 12,
      }}
    >
      {children}
    </CupertinoApp>
  );
}

const noop = () => {};

function Running() {
  return (
    <JobCardWidget
      job={{
        method: "pool.scrub",
        state: "RUNNING",
        description: "Scrub of pool tank",
        progressPercent: 42,
        progressDescription: "Scanned 1.8 TiB of 4.3 TiB",
        elapsedLabel: "1h 12m",
        abortable: true,
      }}
      onCancel={noop}
    />
  );
}

function Failed() {
  return (
    <JobCardWidget
      defaultExpanded
      job={{
        method: "cloudsync.sync",
        state: "FAILED",
        description: "Cloud Sync to Backblaze B2",
        startedLabel: "14m ago",
        finishedLabel: "9m ago",
        error:
          "Authentication failed: application key is invalid or has been revoked.",
      }}
      onRetry={noop}
    />
  );
}

function Succeeded() {
  return (
    <JobCardWidget
      job={{
        method: "zfs.snapshot.create",
        state: "SUCCESS",
        description: "Snapshot tank/home@auto-2026-10-02",
      }}
    />
  );
}

function Queued() {
  return (
    <JobCardWidget job={{ method: "zfs.replication.run", state: "WAITING" }} />
  );
}

export const JobStatesLight = () => (
  <Pane>
    <Running />
    <Queued />
    <Succeeded />
    <Failed />
  </Pane>
);

export const JobStatesDark = () => (
  <Pane dark>
    <Running />
    <Queued />
    <Succeeded />
    <Failed />
  </Pane>
);

export const RunningExpandedLight = () => (
  <Pane>
    <JobCardWidget
      defaultExpanded
      job={{
        method: "smart.test",
        state: "RUNNING",
        description: "SMART long test on sda",
        progressPercent: 76,
        elapsedLabel: "3h 4m",
        startedLabel: "3h ago",
        abortable: true,
      }}
      onCancel={noop}
    />
  </Pane>
);
