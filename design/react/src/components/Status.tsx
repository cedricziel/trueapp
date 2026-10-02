import logoUrl from "../../../logo.svg";
import { resolveColor, withAlpha, type ColorValue } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";

export interface AppLogoProps {
  /** Edge length in px. Defaults to 48. */
  size?: number;
}

/** The TrueNAS Manager logo tile (blue gradient squircle). */
export function AppLogo({ size = 48 }: AppLogoProps) {
  return (
    <img
      src={logoUrl}
      width={size}
      height={size}
      alt="TrueNAS Manager logo"
      style={{ display: "block" }}
    />
  );
}

export type TrueNASConnectionState =
  "connected" | "connecting" | "reconnecting" | "error" | "disconnected";

const STATE_VISUAL: Record<
  TrueNASConnectionState,
  { color: ColorValue; icon: CupertinoIconName }
> = {
  connected: { color: "systemGreen", icon: "checkmark_circle_fill" },
  connecting: { color: "systemOrange", icon: "arrow_clockwise" },
  reconnecting: { color: "systemOrange", icon: "arrow_clockwise" },
  error: { color: "systemRed", icon: "exclamationmark_circle_fill" },
  disconnected: { color: "systemGrey", icon: "circle" },
};

function stateLabel(state: TrueNASConnectionState, healthy: boolean) {
  switch (state) {
    case "connected":
      return healthy ? "Connected" : "Connection Issues";
    case "connecting":
      return "Connecting...";
    case "reconnecting":
      return "Reconnecting...";
    case "error":
      return "Connection Error";
    case "disconnected":
      return "Disconnected";
  }
}

export interface ConnectionStatusWidgetProps {
  state: TrueNASConnectionState;
  /** A connected-but-unhealthy link reads "Connection Issues". Defaults to true. */
  isHealthy?: boolean;
  /** Round-trip latency in ms, shown after "Connected". */
  latencyMs?: number;
  /** Render just an 8px colored dot. */
  compact?: boolean;
}

/** An icon + colored status label (or an 8px dot when `compact`) for a server connection. */
export function ConnectionStatusWidget({
  state,
  isHealthy = true,
  latencyMs,
  compact = false,
}: ConnectionStatusWidgetProps) {
  const { color, icon } = STATE_VISUAL[state];
  const c = resolveColor(color);
  if (compact) {
    return (
      <span
        style={{
          display: "inline-block",
          width: 8,
          height: 8,
          borderRadius: "50%",
          background: c,
        }}
      />
    );
  }
  return (
    <span style={{ display: "inline-flex", alignItems: "center" }}>
      <CupertinoIcon icon={icon} color={color} size={16} />
      <span style={{ marginLeft: 6, color: c, fontSize: 13, fontWeight: 500 }}>
        {stateLabel(state, isHealthy)}
      </span>
      {latencyMs != null && state === "connected" && (
        <span
          style={{
            marginLeft: 4,
            color: "var(--cupertino-system-grey)",
            fontSize: 11,
          }}
        >
          {latencyMs}ms
        </span>
      )}
    </span>
  );
}

export interface ConnectionStatusTitleWidgetProps {
  state: TrueNASConnectionState;
  isHealthy?: boolean;
  onClick?: () => void;
}

/**
 * The nav-bar connection chip: a tinted rounded capsule with a wifi glyph,
 * plus a spinner while (re)connecting. Tapping opens connection details.
 */
export function ConnectionStatusTitleWidget({
  state,
  isHealthy = true,
  onClick,
}: ConnectionStatusTitleWidgetProps) {
  let color: ColorValue;
  let icon: CupertinoIconName;
  switch (state) {
    case "connected":
      color = isHealthy ? "systemGreen" : "systemOrange";
      icon = isHealthy ? "wifi" : "wifi_exclamationmark";
      break;
    case "connecting":
    case "reconnecting":
      color = "systemOrange";
      icon = "arrow_clockwise";
      break;
    case "error":
      color = "systemRed";
      icon = "wifi_slash";
      break;
    default:
      color = "systemGrey";
      icon = "wifi_slash";
  }
  const busy = state === "connecting" || state === "reconnecting";
  return (
    <button
      type="button"
      onClick={onClick}
      title={stateLabel(state, isHealthy)}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        padding: "4px 8px",
        border: "none",
        borderRadius: 12,
        background: withAlpha(color, 0.1),
        cursor: "pointer",
      }}
    >
      <CupertinoIcon icon={icon} color={color} size={16} />
      {busy && <CupertinoActivityIndicator radius={6} color={color} />}
    </button>
  );
}

export interface JobsBellButtonProps {
  /** Jobs currently running: shows a blue count badge. */
  runningCount?: number;
  /** Nothing running but something failed recently: shows a red dot. */
  needsAttention?: boolean;
  onClick?: () => void;
}

/**
 * The job-status bell in every server screen's nav bar: blue with a count
 * badge while jobs run, a red dot when a recent job failed, otherwise a dim
 * outline.
 */
export function JobsBellButton({
  runningCount = 0,
  needsAttention = false,
  onClick,
}: JobsBellButtonProps) {
  const color: ColorValue =
    runningCount > 0
      ? "systemBlue"
      : needsAttention
        ? "systemRed"
        : "systemGrey2";
  const ring = "1.5px solid var(--cupertino-system-background)";
  return (
    <button
      type="button"
      className="cupertino-button"
      aria-label="Jobs"
      onClick={onClick}
      style={{
        position: "relative",
        width: 32,
        height: 32,
        padding: 0,
        border: "none",
        background: "transparent",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "pointer",
      }}
    >
      <CupertinoIcon icon="bell" color={color} size={20} />
      {runningCount > 0 ? (
        <span
          style={{
            position: "absolute",
            top: 3,
            right: 3,
            minWidth: 15,
            minHeight: 15,
            padding: "0 3px",
            boxSizing: "border-box",
            borderRadius: 8,
            border: ring,
            background: "var(--cupertino-system-blue)",
            color: "var(--cupertino-white)",
            fontSize: 10,
            fontWeight: 700,
            lineHeight: "12px",
            textAlign: "center",
          }}
        >
          {runningCount}
        </span>
      ) : needsAttention ? (
        <span
          style={{
            position: "absolute",
            top: 5,
            right: 5,
            width: 8,
            height: 8,
            boxSizing: "border-box",
            borderRadius: "50%",
            border: ring,
            background: "var(--cupertino-system-red)",
          }}
        />
      ) : null}
    </button>
  );
}

export interface SessionIndicatorWidgetProps {
  /** Minutes left on the unlocked session. Under 5 turns the lock orange. */
  minutesRemaining: number;
  /** Seconds part of the countdown. */
  secondsRemaining?: number;
  /** Show the mm:ss countdown next to the lock (debug builds only in the app). */
  showCountdown?: boolean;
  onClick?: () => void;
}

/** The nav-bar open-lock that shows an authenticated session is active; orange in its last 5 minutes. */
export function SessionIndicatorWidget({
  minutesRemaining,
  secondsRemaining = 0,
  showCountdown = false,
  onClick,
}: SessionIndicatorWidgetProps) {
  const color: ColorValue =
    minutesRemaining < 5 ? "systemOrange" : "systemGreen";
  return (
    <button
      type="button"
      className="cupertino-button"
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        padding: 0,
        border: "none",
        background: "transparent",
        cursor: "pointer",
        minHeight: 44,
      }}
    >
      <CupertinoIcon icon="lock_open" color={color} size={16} />
      {showCountdown && (
        <span style={{ fontSize: 12, color: resolveColor(color) }}>
          {minutesRemaining}:{String(secondsRemaining).padStart(2, "0")}
        </span>
      )}
    </button>
  );
}
