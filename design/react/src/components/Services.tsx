import { useState, type ReactNode } from "react";
import { withAlpha } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import {
  CupertinoActionSheet,
  CupertinoActionSheetAction,
} from "../primitives/Forms";
import { StatusPill } from "./SectionCard";

export type ServiceAction = "start" | "stop" | "restart";

/** The running/enabled state of one TrueNAS service, as `service.query` returns it. */
export interface ServiceStatus {
  /** Internal TrueNAS service id, e.g. `cifs`, `ssh`, `iscsitarget`. Drives the display name. */
  id: string;
  isRunning: boolean;
  isEnabled: boolean;
}

const DISPLAY_NAMES: Record<string, string> = {
  cifs: "SMB",
  nfs: "NFS",
  ssh: "SSH",
  rsync: "Rsync",
  ftp: "FTP",
  snmp: "SNMP",
  smartd: "S.M.A.R.T.",
  ups: "UPS",
  iscsitarget: "iSCSI",
  webdav: "WebDAV",
  docker: "Apps",
};

/** The name shown in the UI: a known label, else the upper-cased id. */
export function serviceDisplayName(id: string): string {
  return DISPLAY_NAMES[id] ?? id.toUpperCase();
}

export interface ServiceTileProps {
  service: ServiceStatus;
  /** An action is in flight: a spinner replaces the state pill and the tile ignores taps. */
  isBusy?: boolean;
  onAction?: (action: ServiceAction) => void;
  /** Shows the Start / Stop / Restart action sheet. Leave unset to open it by tapping the tile. */
  sheetOpen?: boolean;
  onSheetOpenChange?: (open: boolean) => void;
}

/**
 * One service row: its name and a Running / Stopped pill (a spinner while an
 * action is in flight). Tapping opens an action sheet: Start when stopped,
 * Stop and Restart when running.
 */
export function ServiceTile({
  service,
  isBusy = false,
  onAction,
  sheetOpen,
  onSheetOpenChange,
}: ServiceTileProps) {
  const [localOpen, setLocalOpen] = useState(false);
  const open = sheetOpen ?? localOpen;
  const setOpen = (next: boolean) => {
    setLocalOpen(next);
    onSheetOpenChange?.(next);
  };
  const name = serviceDisplayName(service.id);
  const state = service.isRunning ? "Running" : "Stopped";
  const choose = (action: ServiceAction) => {
    setOpen(false);
    onAction?.(action);
  };

  return (
    <div style={{ marginBottom: 12 }}>
      <button
        type="button"
        className="cupertino-button"
        disabled={isBusy}
        onClick={() => setOpen(true)}
        style={{
          display: "flex",
          alignItems: "center",
          width: "100%",
          boxSizing: "border-box",
          padding: 16,
          font: "inherit",
          color: "var(--cupertino-label)",
          textAlign: "left",
          background: "var(--cupertino-system-background)",
          borderRadius: 12,
          border: "0.5px solid var(--cupertino-separator)",
          cursor: isBusy ? "default" : "pointer",
        }}
      >
        <span style={{ flex: 1, minWidth: 0, fontSize: 16, fontWeight: 600 }}>
          {name}
        </span>
        {isBusy ? (
          <CupertinoActivityIndicator />
        ) : (
          <StatusPill
            label={state}
            color={service.isRunning ? "systemGreen" : "systemGrey"}
          />
        )}
      </button>
      {open && (
        <ModalPopup onDismiss={() => setOpen(false)}>
          <CupertinoActionSheet
            title={name}
            message={state}
            actions={
              service.isRunning
                ? [
                    <CupertinoActionSheetAction
                      key="stop"
                      isDestructiveAction
                      onClick={() => choose("stop")}
                    >
                      Stop
                    </CupertinoActionSheetAction>,
                    <CupertinoActionSheetAction
                      key="restart"
                      isDestructiveAction
                      onClick={() => choose("restart")}
                    >
                      Restart
                    </CupertinoActionSheetAction>,
                  ]
                : [
                    <CupertinoActionSheetAction
                      key="start"
                      onClick={() => choose("start")}
                    >
                      Start
                    </CupertinoActionSheetAction>,
                  ]
            }
            cancelButton={
              <CupertinoActionSheetAction onClick={() => setOpen(false)}>
                Cancel
              </CupertinoActionSheetAction>
            }
          />
        </ModalPopup>
      )}
    </div>
  );
}

/** `showCupertinoModalPopup`'s dimmed barrier with the popup pinned to the bottom. */
function ModalPopup({
  children,
  onDismiss,
}: {
  children: ReactNode;
  onDismiss?: () => void;
}) {
  return (
    <div
      onClick={onDismiss}
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 1000,
        display: "flex",
        flexDirection: "column",
        justifyContent: "flex-end",
        background: "rgba(0,0,0,0.2)",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{ width: "100%", maxWidth: 520, margin: "0 auto" }}
      >
        {children}
      </div>
    </div>
  );
}

export interface ServiceActionErrorBannerProps {
  message: string;
  onDismiss?: () => void;
}

/**
 * The red banner above the service list when a start, stop or restart
 * failed: the error text and an X button to dismiss it.
 */
export function ServiceActionErrorBanner({
  message,
  onDismiss,
}: ServiceActionErrorBannerProps) {
  return (
    <div
      style={{
        marginBottom: 12,
        padding: "4px 4px 4px 16px",
        borderRadius: 12,
        background: withAlpha("systemRed", 0.1),
        display: "flex",
        alignItems: "center",
      }}
    >
      <div
        style={{
          flex: 1,
          minWidth: 0,
          fontSize: 14,
          color: "var(--cupertino-system-red)",
        }}
      >
        {message}
      </div>
      <CupertinoButton padding={8} minSize={0} onClick={onDismiss}>
        <CupertinoIcon icon="xmark" color="systemRed" size={16} />
      </CupertinoButton>
    </div>
  );
}
