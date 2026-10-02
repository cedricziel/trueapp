import { useState } from "react";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { UsageBar } from "./Metrics";
import { cardStyle } from "./shared";

export type JobState = "WAITING" | "RUNNING" | "SUCCESS" | "FAILED" | "ABORTED";

export interface Job {
  /** Middleware method, e.g. "pool.scrub" or "zfs.replication.run". Drives the icon. */
  method: string;
  state: JobState;
  /** Human title; falls back to the method's last segment, title-cased. */
  description?: string;
  /** 0-100, shown while RUNNING. */
  progressPercent?: number;
  progressDescription?: string;
  /** e.g. "1m 12s". */
  elapsedLabel?: string;
  /** e.g. "3m ago". */
  startedLabel?: string;
  finishedLabel?: string;
  error?: string;
  abortable?: boolean;
}

function visualFor(job: Job): { icon: CupertinoIconName; color: ColorValue } {
  if (job.state === "SUCCESS")
    return { icon: "checkmark_circle_fill", color: "systemGreen" };
  if (job.state === "FAILED")
    return { icon: "xmark_circle_fill", color: "systemRed" };
  if (job.state === "ABORTED")
    return { icon: "minus_circle_fill", color: "systemGrey" };
  const m = job.method;
  if (m.startsWith("zfs.replication"))
    return { icon: "arrow_2_circlepath", color: "systemTeal" };
  if (m.startsWith("pool.scrub"))
    return { icon: "shield", color: "systemGreen" };
  if (m.startsWith("cloudsync"))
    return { icon: "cloud_upload", color: "systemOrange" };
  if (m.startsWith("smart.test"))
    return { icon: "waveform_path", color: "systemPurple" };
  if (m.startsWith("zfs.snapshot"))
    return { icon: "camera", color: "systemGrey" };
  return { icon: "gear", color: "systemBlue" };
}

function titleFor(job: Job) {
  if (job.description) return job.description;
  const last = job.method.split(".").pop() ?? job.method;
  const words = last.split("_").filter(Boolean);
  return words.length
    ? words.map((w) => w[0].toUpperCase() + w.slice(1)).join(" ")
    : job.method;
}

function MetaRow({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: "flex", fontSize: 12, gap: 8 }}>
      <span style={{ color: "var(--cupertino-system-grey)" }}>{label}</span>
      <span
        style={{
          flex: 1,
          textAlign: "right",
          fontWeight: 500,
          overflow: "hidden",
          textOverflow: "ellipsis",
          whiteSpace: "nowrap",
        }}
      >
        {value}
      </span>
    </div>
  );
}

export interface JobCardWidgetProps {
  job: Job;
  /** Start expanded (details, error and Cancel/Retry visible). Tapping the card toggles it. */
  defaultExpanded?: boolean;
  /** Shown as "Cancel Job" on running abortable jobs. */
  onCancel?: () => void;
  /** Shown as "Retry" on failed jobs. */
  onRetry?: () => void;
  /** Swap the action for a spinner while a cancel/retry is in flight. */
  busy?: boolean;
}

/**
 * A middleware job in the Jobs list: method-tinted icon tile, title and
 * method, live percent + progress bar while running, a status chip when
 * finished, and an expandable detail panel with Cancel/Retry.
 */
export function JobCardWidget({
  job,
  defaultExpanded = false,
  onCancel,
  onRetry,
  busy = false,
}: JobCardWidgetProps) {
  const [expanded, setExpanded] = useState(defaultExpanded);
  const { icon, color } = visualFor(job);
  const c = resolveColor(color);
  const running = job.state === "RUNNING";
  const finished =
    job.state === "SUCCESS" ||
    job.state === "FAILED" ||
    job.state === "ABORTED";
  const failed = job.state === "FAILED";
  const pct = job.progressPercent ?? 0;
  const badge =
    { SUCCESS: "Success", FAILED: "Failed", ABORTED: "Aborted" }[
      job.state as "SUCCESS"
    ] ?? "Done";

  return (
    <div
      onClick={() => setExpanded((e) => !e)}
      style={{ ...cardStyle(), cursor: "pointer" }}
    >
      <div style={{ display: "flex", alignItems: "flex-start" }}>
        <div
          style={{
            width: 44,
            height: 44,
            flexShrink: 0,
            borderRadius: 10,
            background: withAlpha(color, 0.1),
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <CupertinoIcon icon={icon} color={color} size={21} />
        </div>
        <div style={{ flex: 1, minWidth: 0, marginLeft: 12 }}>
          <div style={{ fontSize: 16, fontWeight: 600 }}>{titleFor(job)}</div>
          <div
            style={{
              marginTop: 2,
              fontSize: 13,
              color: "var(--cupertino-system-grey)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {job.state === "WAITING" ? `Queued · ${job.method}` : job.method}
          </div>
        </div>
        <div
          style={{
            marginLeft: 8,
            display: "flex",
            flexDirection: "column",
            alignItems: "flex-end",
            gap: 4,
          }}
        >
          {running && (
            <span style={{ fontSize: 16, fontWeight: 600, color: c }}>
              {Math.round(pct)}%
            </span>
          )}
          {finished && (
            <span
              style={{
                padding: "4px 9px",
                borderRadius: 7,
                background: withAlpha(color, 0.1),
                color: c,
                fontSize: 12,
                fontWeight: 600,
              }}
            >
              {badge}
            </span>
          )}
          <CupertinoIcon
            icon={expanded ? "chevron_up" : "chevron_down"}
            size={14}
            color="tertiaryLabel"
          />
        </div>
      </div>

      {running && (
        <div style={{ marginTop: 12 }}>
          <UsageBar usage={pct} color="systemBlue" />
          {job.progressDescription && (
            <div
              style={{
                marginTop: 6,
                fontSize: 11,
                color: "var(--cupertino-secondary-label)",
              }}
            >
              {job.progressDescription}
            </div>
          )}
          {job.elapsedLabel && (
            <div
              style={{
                marginTop: 4,
                fontSize: 11,
                color: "var(--cupertino-tertiary-label)",
              }}
            >
              Elapsed {job.elapsedLabel}
            </div>
          )}
        </div>
      )}

      {expanded && (
        <div
          style={{
            marginTop: 14,
            paddingTop: 12,
            borderTop: "0.5px solid var(--cupertino-separator)",
            display: "flex",
            flexDirection: "column",
            gap: 8,
          }}
        >
          {job.startedLabel && (
            <MetaRow label="Started" value={job.startedLabel} />
          )}
          {job.finishedLabel && (
            <MetaRow label="Finished" value={job.finishedLabel} />
          )}
          <MetaRow label="Method" value={job.method} />
          {failed && job.error && (
            <div
              style={{
                marginTop: 2,
                padding: 10,
                borderRadius: 8,
                background: withAlpha("systemRed", 0.1),
                display: "flex",
                gap: 8,
                alignItems: "flex-start",
                fontSize: 12,
              }}
            >
              <CupertinoIcon
                icon="exclamationmark_triangle_fill"
                size={14}
                color="systemRed"
              />
              <span style={{ flex: 1 }}>{job.error}</span>
            </div>
          )}
          {((running && job.abortable) || failed) && (
            <div
              style={{
                display: "flex",
                justifyContent: "flex-end",
                marginTop: 2,
              }}
              onClick={(e) => e.stopPropagation()}
            >
              {busy ? (
                <CupertinoActivityIndicator radius={8} />
              ) : failed && onRetry ? (
                <CupertinoButton
                  padding={0}
                  minSize={0}
                  onClick={onRetry}
                  style={{ fontSize: 14, fontWeight: 600 }}
                >
                  Retry
                </CupertinoButton>
              ) : running && job.abortable && onCancel ? (
                <CupertinoButton
                  padding={0}
                  minSize={0}
                  color="systemRed"
                  onClick={onCancel}
                  style={{ fontSize: 14, fontWeight: 600 }}
                >
                  Cancel Job
                </CupertinoButton>
              ) : null}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
