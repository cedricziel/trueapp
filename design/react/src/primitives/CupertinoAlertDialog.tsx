import type { ReactNode } from "react";

export interface CupertinoDialogActionProps {
  children: ReactNode;
  /** Bold label - the action taken on Return (Flutter's `isDefaultAction`). */
  isDefaultAction?: boolean;
  /** Red label for destructive actions (Flutter's `isDestructiveAction`). */
  isDestructiveAction?: boolean;
  onClick?: () => void;
}

/** Flutter's `CupertinoDialogAction`: one button row in a `CupertinoAlertDialog`. */
export function CupertinoDialogAction({
  children,
  isDefaultAction = false,
  isDestructiveAction = false,
  onClick,
}: CupertinoDialogActionProps) {
  return (
    <button
      type="button"
      className="cupertino-button"
      onClick={onClick}
      style={{
        flex: 1,
        minHeight: 44,
        padding: "10px 8px",
        border: "none",
        background: "transparent",
        font: "inherit",
        fontSize: 17,
        letterSpacing: -0.41,
        fontWeight: isDefaultAction ? 600 : 400,
        color: isDestructiveAction
          ? "var(--cupertino-system-red)"
          : "var(--cupertino-system-blue)",
        cursor: "pointer",
      }}
    >
      {children}
    </button>
  );
}

export interface CupertinoAlertDialogProps {
  title?: ReactNode;
  /** Body text or composed content under the title. */
  content?: ReactNode;
  /** `CupertinoDialogAction`s. Two actions sit side by side; three or more stack. */
  actions?: ReactNode[];
  /** Render the dimmed full-screen barrier behind the dialog. Defaults to false (inline card). */
  barrier?: boolean;
}

/**
 * Flutter's `CupertinoAlertDialog`: the iOS alert with a centered title,
 * message, and hairline-separated action buttons. The app shows it via
 * `showCupertinoDialog` for confirmations ("Delete Server") and details
 * ("Connection Status").
 */
export function CupertinoAlertDialog({
  title,
  content,
  actions = [],
  barrier = false,
}: CupertinoAlertDialogProps) {
  const horizontal = actions.length <= 2;
  const dialog = (
    <div
      role="alertdialog"
      style={{
        width: 270,
        borderRadius: 14,
        overflow: "hidden",
        background:
          "color-mix(in srgb, var(--cupertino-secondary-system-background) 92%, transparent)",
        backdropFilter: "blur(20px)",
        color: "var(--cupertino-label)",
        textAlign: "center",
        boxShadow: "0 10px 40px rgba(0,0,0,0.18)",
      }}
    >
      <div style={{ padding: "19px 16px 18px" }}>
        {title != null && (
          <div
            style={{
              fontSize: 17,
              fontWeight: 600,
              letterSpacing: -0.41,
              lineHeight: 1.3,
            }}
          >
            {title}
          </div>
        )}
        {content != null && (
          <div
            style={{
              marginTop: title != null ? 2 : 0,
              fontSize: 13,
              letterSpacing: -0.08,
              lineHeight: 1.35,
            }}
          >
            {content}
          </div>
        )}
      </div>
      {actions.length > 0 && (
        <div
          style={{
            display: "flex",
            flexDirection: horizontal ? "row" : "column",
            borderTop: "0.5px solid var(--cupertino-separator)",
          }}
        >
          {actions.map((action, i) => (
            <div
              key={i}
              style={{
                flex: 1,
                display: "flex",
                borderLeft:
                  horizontal && i > 0
                    ? "0.5px solid var(--cupertino-separator)"
                    : undefined,
                borderTop:
                  !horizontal && i > 0
                    ? "0.5px solid var(--cupertino-separator)"
                    : undefined,
              }}
            >
              {action}
            </div>
          ))}
        </div>
      )}
    </div>
  );

  if (!barrier) return dialog;
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "rgba(0,0,0,0.2)",
        zIndex: 1000,
      }}
    >
      {dialog}
    </div>
  );
}
