import type { ColorValue } from "../colors";
import type { CupertinoIconName } from "../primitives/CupertinoIcon";
import { StatusPill } from "./SectionCard";

/** Lifecycle state of an installed app, as reported by TrueNAS `app.query`. */
export type AppState =
  | "running"
  | "deploying"
  | "stopping"
  | "stopped"
  | "crashed"
  | "unknown";

export interface AppStateBadgeProps {
  app: {
    installed: boolean;
    /** Defaults to "unknown", which shows a grey "Installed" chip. */
    state?: AppState;
  };
}

const INSTALLED_STATES: Record<
  AppState,
  { label: string; color: ColorValue; icon?: CupertinoIconName }
> = {
  running: {
    label: "Running",
    color: "systemGreen",
    icon: "checkmark_circle_fill",
  },
  deploying: {
    label: "Deploying",
    color: "systemOrange",
    icon: "arrow_2_circlepath",
  },
  stopping: {
    label: "Stopping",
    color: "systemOrange",
    icon: "arrow_2_circlepath",
  },
  stopped: { label: "Stopped", color: "systemGrey", icon: "stop_circle" },
  crashed: {
    label: "Crashed",
    color: "systemRed",
    icon: "exclamationmark_triangle_fill",
  },
  unknown: { label: "Installed", color: "systemGrey" },
};

/**
 * An app's running state as a `StatusPill`: Running, Deploying, Stopping,
 * Stopped or Crashed for installed apps ("Installed" when the state is
 * unknown), and a blue "Available" for catalog-only apps.
 */
export function AppStateBadge({ app }: AppStateBadgeProps) {
  const { label, color, icon } = app.installed
    ? INSTALLED_STATES[app.state ?? "unknown"]
    : { label: "Available", color: "systemBlue" as const, icon: undefined };
  return <StatusPill label={label} color={color} icon={icon} />;
}
