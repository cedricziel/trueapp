import { resolveColor, type ColorValue } from "../colors";
import { JobCardWidget, type Job } from "../components/JobCardWidget";
import { ShellBackButton } from "../components/Navigation";
import { cardStyle } from "../components/shared";
import { EmptyStateWidget, ErrorStateWidget } from "../components/States";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { CupertinoSegmentedControl } from "./internal/CupertinoSegmentedControl";

export type JobsTab = "running" | "waiting" | "history";

export interface ServerJobsScreenProps {
  /** Shown as the back button's caption. */
  serverName?: string;
  runningJobs?: Job[];
  waitingJobs?: Job[];
  /** Finished jobs: succeeded, failed and aborted. */
  historyJobs?: Job[];
  /** Failures in the last 24h, for the overview card. Defaults to 0. */
  recentFailuresCount?: number;
  /** Defaults to `running`. */
  tab?: JobsTab;
  /** First load with no jobs yet: a centered spinner replaces the screen body. */
  loading?: boolean;
  /** The first load failed with no jobs yet: an error with Retry replaces the screen body. */
  error?: string;
  onBack?: () => void;
  onRefresh?: () => void;
  onTabChange?: (tab: JobsTab) => void;
  /** Offered on running jobs. */
  onCancelJob?: (job: Job) => void;
  /** Offered on failed jobs. */
  onRetryJob?: (job: Job) => void;
}

const EMPTY: Record<JobsTab, [title: string, message: string]> = {
  running: ["Nothing running", "Jobs in progress will appear here."],
  waiting: ["Nothing queued", "Jobs waiting to start will appear here."],
  history: [
    "No finished jobs",
    "Completed, failed, and aborted jobs will appear here.",
  ],
};

/**
 * The server's Jobs screen: a Running / Waiting / Failed-24h overview card, a
 * Running / Waiting / History segmented control, and the selected tab's
 * `JobCardWidget`s. Opened from the jobs bell in any server screen's nav bar.
 */
export function ServerJobsScreen({
  serverName,
  runningJobs = [],
  waitingJobs = [],
  historyJobs = [],
  recentFailuresCount = 0,
  tab = "running",
  loading = false,
  error,
  onBack,
  onRefresh,
  onTabChange,
  onCancelJob,
  onRetryJob,
}: ServerJobsScreenProps) {
  const jobs = {
    running: runningJobs,
    waiting: waitingJobs,
    history: historyJobs,
  }[tab];
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle="Jobs"
          leading={
            <ShellBackButton previousPageTitle={serverName} onClick={onBack} />
          }
          trailing={
            <CupertinoButton padding={0} minSize={0} onClick={onRefresh}>
              <CupertinoIcon icon="refresh" />
            </CupertinoButton>
          }
        />
      }
    >
      {loading ? (
        <div
          style={{
            height: "100%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <CupertinoActivityIndicator />
        </div>
      ) : error != null ? (
        <ErrorStateWidget
          title="Jobs Error"
          message={error}
          onRetry={onRefresh}
        />
      ) : (
        <>
          <div style={{ height: 12 }} />
          <div style={{ padding: "0 16px" }}>
            <JobsOverviewCard
              runningCount={runningJobs.length}
              waitingCount={waitingJobs.length}
              failedRecently={recentFailuresCount}
            />
          </div>
          <div style={{ height: 16 }} />
          <div style={{ padding: "0 16px" }}>
            <CupertinoSegmentedControl
              groupValue={tab}
              onValueChanged={onTabChange}
              segments={[
                { value: "running", label: `Running ${runningJobs.length}` },
                { value: "waiting", label: `Waiting ${waitingJobs.length}` },
                { value: "history", label: "History" },
              ]}
            />
          </div>
          <div style={{ height: 16 }} />
          {jobs.length === 0 ? (
            <EmptyStateWidget
              icon="clock"
              title={EMPTY[tab][0]}
              message={EMPTY[tab][1]}
            />
          ) : (
            <div style={{ padding: "0 16px" }}>
              {jobs.map((job, i) => (
                <div key={`${job.method}-${i}`} style={{ paddingBottom: 12 }}>
                  <JobCardWidget
                    job={job}
                    onCancel={
                      job.state === "RUNNING" && onCancelJob
                        ? () => onCancelJob(job)
                        : undefined
                    }
                    onRetry={
                      job.state === "FAILED" && onRetryJob
                        ? () => onRetryJob(job)
                        : undefined
                    }
                  />
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </CupertinoPageScaffold>
  );
}

function JobsOverviewCard({
  runningCount,
  waitingCount,
  failedRecently,
}: {
  runningCount: number;
  waitingCount: number;
  failedRecently: number;
}) {
  return (
    <div style={{ ...cardStyle(), display: "flex" }}>
      <Stat count={runningCount} label="Running" color="systemBlue" />
      <Stat count={waitingCount} label="Waiting" color="systemGrey" />
      <Stat
        count={failedRecently}
        label="Failed 24h"
        color={failedRecently > 0 ? "systemRed" : "systemGrey"}
      />
    </div>
  );
}

function Stat({
  count,
  label,
  color,
}: {
  count: number;
  label: string;
  color: ColorValue;
}) {
  return (
    <div style={{ flex: 1, textAlign: "center" }}>
      <div
        style={{ fontSize: 18, fontWeight: 600, color: resolveColor(color) }}
      >
        {count}
      </div>
      <div
        style={{
          marginTop: 2,
          fontSize: 11,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {label}
      </div>
    </div>
  );
}
