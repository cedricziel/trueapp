import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerJobsScreen,
  type DeviceKind,
  type Job,
  type ServerJobsScreenProps,
} from "@truenas-manager/ui";

const running: Job[] = [
  {
    method: "pool.scrub",
    state: "RUNNING",
    description: "Scrub pool tank",
    progressPercent: 42,
    progressDescription: "Scanning 4.1 TiB of 9.8 TiB",
    elapsedLabel: "1h 12m",
    startedLabel: "Today 02:00",
    abortable: true,
  },
  {
    method: "app.pull_images",
    state: "RUNNING",
    description: "Pull images for nextcloud",
    progressPercent: 78,
    progressDescription: "Downloading nextcloud:30.0.4",
    elapsedLabel: "36s",
  },
];

const waiting: Job[] = [
  {
    method: "zfs.replication.run",
    state: "WAITING",
    description: "Replicate tank/media to backup-box",
  },
];

const history: Job[] = [
  {
    method: "cloudsync.sync",
    state: "FAILED",
    description: "Cloud sync to Backblaze B2",
    startedLabel: "Today 01:00",
    finishedLabel: "Today 01:04",
    error: "[EFAULT] Failed to authenticate: invalid application key",
  },
  {
    method: "zfs.snapshot.create",
    state: "SUCCESS",
    description: "Snapshot tank/documents@auto-2026-10-02_00-00",
    finishedLabel: "Today 00:00",
  },
  {
    method: "zfs.snapshot.create",
    state: "SUCCESS",
    description: "Snapshot tank/photos@auto-2026-10-02_00-00",
    finishedLabel: "Today 00:00",
  },
  {
    method: "smart.test.manual_test",
    state: "ABORTED",
    description: "SMART short test on sda",
    finishedLabel: "Yesterday 22:15",
  },
];

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
} & Partial<ServerJobsScreenProps>) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <ServerJobsScreen
          serverName="Basement NAS"
          runningJobs={running}
          waitingJobs={waiting}
          historyJobs={history}
          recentFailuresCount={1}
          onRefresh={() => {}}
          onCancelJob={() => {}}
          onRetryJob={() => {}}
          {...props}
        />
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Shell />;
export const PhonePortraitDark = () => <Shell dark />;
export const PhoneLandscapeLight = () => <Shell orientation="landscape" />;
export const TabletPortraitLight = () => (
  <Shell device="tablet" scale={0.45} tab="history" />
);
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark scale={0.45} />
);
export const DesktopLight = () => (
  <Shell device="desktop" scale={0.5} tab="history" />
);
export const DesktopDark = () => <Shell device="desktop" dark scale={0.5} />;

export const WaitingTab = () => <Shell tab="waiting" />;
export const HistoryTabDark = () => <Shell dark tab="history" />;
export const EmptyRunning = () => (
  <Shell runningJobs={[]} waitingJobs={[]} recentFailuresCount={0} />
);
export const LoadingDark = () => <Shell dark loading />;
export const LoadError = () => (
  <Shell error="Not connected to Basement NAS. Check the server is reachable." />
);
