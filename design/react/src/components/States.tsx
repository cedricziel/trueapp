import type { ReactNode } from "react";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";

const centered = {
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  padding: 32,
  textAlign: "center",
  whiteSpace: "pre-line",
} as const;

export interface LoadingStateWidgetProps {
  message?: string;
}

/**
 * A centered spinner with an optional grey label. Same layout as
 * `EmptyStateWidget` and `ErrorStateWidget`, so screens swap between the
 * three without a layout jump.
 */
export function LoadingStateWidget({ message }: LoadingStateWidgetProps) {
  return (
    <div style={centered}>
      <CupertinoActivityIndicator radius={14} />
      {message && (
        <div
          style={{
            marginTop: 16,
            fontSize: 14,
            color: "var(--cupertino-system-grey)",
          }}
        >
          {message}
        </div>
      )}
    </div>
  );
}

export interface EmptyStateWidgetProps {
  icon?: CupertinoIconName;
  /** Replaces `icon` when both are given, e.g. `<AppLogo />`. */
  leading?: ReactNode;
  title: string;
  message: string;
}

/** A centered 48px grey icon, grey title and lighter message for empty lists. */
export function EmptyStateWidget({
  icon,
  leading,
  title,
  message,
}: EmptyStateWidgetProps) {
  return (
    <div style={centered}>
      {leading ??
        (icon && <CupertinoIcon icon={icon} size={48} color="systemGrey" />)}
      <div
        style={{
          marginTop: 16,
          fontSize: 18,
          fontWeight: 600,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {title}
      </div>
      <div
        style={{
          marginTop: 8,
          fontSize: 14,
          color: "var(--cupertino-system-grey2)",
        }}
      >
        {message}
      </div>
    </div>
  );
}

export interface ErrorStateWidgetProps {
  title: string;
  message: string;
  /** Defaults to `exclamationmark_triangle`. Pass `null` to hide. */
  icon?: CupertinoIconName | null;
  /** Shows a filled "Retry" button when set. */
  onRetry?: () => void;
}

/** A centered red icon, title, grey message and optional filled Retry button. */
export function ErrorStateWidget({
  title,
  message,
  icon = "exclamationmark_triangle",
  onRetry,
}: ErrorStateWidgetProps) {
  return (
    <div style={centered}>
      {icon && (
        <div style={{ marginBottom: 16 }}>
          <CupertinoIcon icon={icon} size={48} color="systemRed" />
        </div>
      )}
      <div style={{ fontSize: 18, fontWeight: 600 }}>{title}</div>
      <div
        style={{
          marginTop: 8,
          fontSize: 14,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {message}
      </div>
      {onRetry && (
        <div style={{ marginTop: 16 }}>
          <CupertinoButton variant="filled" onClick={onRetry}>
            Retry
          </CupertinoButton>
        </div>
      )}
    </div>
  );
}

export type ConnectionErrorType =
  | "networkUnreachable"
  | "connectionTimeout"
  | "authenticationFailed"
  | "invalidCredentials"
  | "permissionDenied"
  | "serverError"
  | "invalidResponse"
  | "unknown";

export interface ConnectionError {
  type: ConnectionErrorType;
  /** Headline, e.g. "Server Unreachable". */
  shortMessage: string;
  /** Explanation shown under the headline. */
  userFriendlyMessage: string;
  isRetryable: boolean;
  /** Raw details; shows a "Show Technical Details" link when set. */
  technicalDetails?: string;
}

const ERROR_ICONS: Record<ConnectionErrorType, CupertinoIconName> = {
  networkUnreachable: "wifi_slash",
  connectionTimeout: "time",
  authenticationFailed: "lock_slash",
  invalidCredentials: "lock_slash",
  permissionDenied: "exclamationmark_shield",
  serverError: "exclamationmark_triangle",
  invalidResponse: "exclamationmark_bubble",
  unknown: "question_circle",
};

export interface ConnectionErrorWidgetProps {
  error: ConnectionError;
  onRetry?: () => void;
  onSettings?: () => void;
  onShowDetails?: () => void;
}

/**
 * The full-screen connection failure view: a 64px red icon chosen by error
 * type, red headline, grey explanation, "Try Again" / "Check Settings"
 * buttons, and a technical-details link.
 */
export function ConnectionErrorWidget({
  error,
  onRetry,
  onSettings,
  onShowDetails,
}: ConnectionErrorWidgetProps) {
  return (
    <div style={{ ...centered, padding: 16 }}>
      <CupertinoIcon
        icon={ERROR_ICONS[error.type]}
        size={64}
        color="systemRed"
      />
      <div
        style={{
          marginTop: 16,
          fontSize: 20,
          fontWeight: 700,
          color: "var(--cupertino-system-red)",
        }}
      >
        {error.shortMessage}
      </div>
      <div
        style={{
          marginTop: 12,
          fontSize: 16,
          color: "var(--cupertino-system-grey)",
        }}
      >
        {error.userFriendlyMessage}
      </div>
      <div
        style={{
          marginTop: 24,
          display: "flex",
          gap: 12,
          justifyContent: "center",
          flexWrap: "wrap",
        }}
      >
        {error.isRetryable && onRetry && (
          <CupertinoButton variant="filled" onClick={onRetry}>
            Try Again
          </CupertinoButton>
        )}
        {onSettings && (
          <CupertinoButton onClick={onSettings}>Check Settings</CupertinoButton>
        )}
      </div>
      {error.technicalDetails && (
        <div style={{ marginTop: 24 }}>
          <CupertinoButton
            onClick={onShowDetails}
            color="systemGrey"
            style={{ fontSize: 14 }}
          >
            Show Technical Details
          </CupertinoButton>
        </div>
      )}
    </div>
  );
}

export interface CompactConnectionErrorWidgetProps {
  error: ConnectionError;
  onRetry?: () => void;
}

/** An inline red-tinted error banner with an optional Retry, for lists and small spaces. */
export function CompactConnectionErrorWidget({
  error,
  onRetry,
}: CompactConnectionErrorWidgetProps) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        padding: 12,
        margin: 8,
        borderRadius: 8,
        background:
          "color-mix(in srgb, var(--cupertino-system-red) 10%, transparent)",
        border:
          "1px solid color-mix(in srgb, var(--cupertino-system-red) 30%, transparent)",
      }}
    >
      <CupertinoIcon
        icon="exclamationmark_triangle"
        size={20}
        color="systemRed"
      />
      <div
        style={{
          flex: 1,
          minWidth: 0,
          color: "var(--cupertino-system-red)",
          fontWeight: 500,
        }}
      >
        {error.shortMessage}
      </div>
      {error.isRetryable && onRetry && (
        <CupertinoButton
          onClick={onRetry}
          padding="4px 8px"
          minSize={0}
          style={{ fontSize: 14 }}
        >
          Retry
        </CupertinoButton>
      )}
    </div>
  );
}

export type AuthenticationState =
  "none" | "authenticating" | "required" | "failed" | "authenticated";

export interface AuthenticationStateWidgetProps {
  /** `authenticating` shows a spinner; `required`/`failed` show the lock screen; otherwise `children`. */
  state: AuthenticationState;
  /** The error text shown under the title on the lock screen. */
  error?: string;
  /** Server name shown at the bottom of the lock screen. */
  serverName?: string;
  onAuthenticate?: () => void;
  /** Content shown once authenticated. */
  children?: ReactNode;
}

/**
 * Gates server content behind the session lock: a spinner while
 * authenticating, a lock-shield screen with an Authenticate / Retry button
 * when locked or failed, and `children` once authenticated.
 */
export function AuthenticationStateWidget({
  state,
  error,
  serverName,
  onAuthenticate,
  children,
}: AuthenticationStateWidgetProps) {
  if (state === "authenticating") {
    return (
      <div style={centered}>
        <CupertinoActivityIndicator radius={20} />
        <div style={{ marginTop: 16 }}>Authenticating...</div>
      </div>
    );
  }
  if (state !== "required" && state !== "failed") return <>{children}</>;

  const retry = state === "failed";
  return (
    <div style={centered}>
      <CupertinoIcon icon="lock_shield" size={64} color="systemGrey" />
      <div
        style={{
          marginTop: 24,
          fontFamily: "var(--cupertino-font-display)",
          fontSize: 34,
          fontWeight: 700,
          letterSpacing: 0.38,
          lineHeight: 1.2,
        }}
      >
        {state === "required"
          ? "Authentication Required"
          : "Authentication Failed"}
      </div>
      {error && (
        <div style={{ marginTop: 12, color: "var(--cupertino-system-grey)" }}>
          {error}
        </div>
      )}
      <div style={{ marginTop: 24 }}>
        <CupertinoButton variant="filled" onClick={onAuthenticate}>
          <CupertinoIcon icon={retry ? "refresh" : "lock"} size={20} />
          {retry ? "Retry Authentication" : "Authenticate"}
        </CupertinoButton>
      </div>
      {serverName && (
        <div style={{ marginTop: 16, color: "var(--cupertino-system-grey2)" }}>
          Server: {serverName}
        </div>
      )}
    </div>
  );
}
