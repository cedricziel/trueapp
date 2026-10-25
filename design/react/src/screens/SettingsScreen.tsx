import { FormRowLabel } from "../components/Layout";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import {
  CupertinoAlertDialog,
  CupertinoDialogAction,
} from "../primitives/CupertinoAlertDialog";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import {
  CupertinoFormRow,
  CupertinoFormSection,
  CupertinoPageScaffold,
  CupertinoSwitch,
} from "../primitives/Forms";

export type SettingsPlatform = "ios" | "macos" | "windows" | "linux";

/** The alert the settings screen is currently showing, if any. */
export type SettingsDialog =
  | "clearDatabaseConfirm"
  | "clearingDatabase"
  | "databaseRecreated"
  | "clearDatabaseError";

export interface SettingsScreenProps {
  /** Desktop platforms add the MENU BAR (macOS) / SYSTEM TRAY section. Defaults to `ios`. */
  platform?: SettingsPlatform;
  minimizeToTray?: boolean;
  showInDock?: boolean;
  dialog?: SettingsDialog;
  /** The failure text for the `clearDatabaseError` dialog. */
  clearDatabaseError?: string;
  onMinimizeToTrayChange?: (value: boolean) => void;
  onShowInDockChange?: (value: boolean) => void;
  /** "Clear" tapped: the app opens the `clearDatabaseConfirm` dialog. */
  onClearDatabase?: () => void;
  onConfirmClearDatabase?: () => void;
  onDismissDialog?: () => void;
}

const spacer = <div style={{ height: 20 }} />;

function SettingsAlert({
  dialog,
  clearDatabaseError,
  onConfirmClearDatabase,
  onDismissDialog,
}: Pick<
  SettingsScreenProps,
  "clearDatabaseError" | "onConfirmClearDatabase" | "onDismissDialog"
> & { dialog: SettingsDialog }) {
  const ok = (
    <CupertinoDialogAction key="ok" onClick={onDismissDialog}>
      OK
    </CupertinoDialogAction>
  );
  switch (dialog) {
    case "clearDatabaseConfirm":
      return (
        <CupertinoAlertDialog
          barrier
          title="Clear Database"
          content={
            <>
              This will permanently delete all servers and app data. This action
              cannot be undone.
              <br />
              <br />
              Are you sure you want to continue?
            </>
          }
          actions={[
            <CupertinoDialogAction key="cancel" onClick={onDismissDialog}>
              Cancel
            </CupertinoDialogAction>,
            <CupertinoDialogAction
              key="clear"
              isDestructiveAction
              onClick={onConfirmClearDatabase}
            >
              Clear Database
            </CupertinoDialogAction>,
          ]}
        />
      );
    case "clearingDatabase":
      return (
        <CupertinoAlertDialog
          barrier
          content={
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 16,
              }}
            >
              <CupertinoActivityIndicator />
              Recreating database...
            </div>
          }
        />
      );
    case "databaseRecreated":
      return (
        <CupertinoAlertDialog
          barrier
          title="Database Recreated"
          content="The database has been completely recreated with the latest schema. You can now add servers without any constraint issues."
          actions={[ok]}
        />
      );
    case "clearDatabaseError":
      return (
        <CupertinoAlertDialog
          barrier
          title="Error"
          content={`Failed to clear database: ${clearDatabaseError ?? ""}`}
          actions={[ok]}
        />
      );
  }
}

/**
 * The Settings tab: desktop tray/dock options, clearing the database, and
 * version info. Clearing the database confirms through alerts, selected with
 * `dialog`.
 */
export function SettingsScreen({
  platform = "ios",
  minimizeToTray = false,
  showInDock = true,
  dialog,
  clearDatabaseError,
  onMinimizeToTrayChange,
  onShowInDockChange,
  onClearDatabase,
  onConfirmClearDatabase,
  onDismissDialog,
}: SettingsScreenProps) {
  const isDesktop = platform !== "ios";
  const isMacOS = platform === "macos";
  const grey = { color: "var(--cupertino-system-grey)" };

  return (
    <CupertinoPageScaffold
      background="systemGroupedBackground"
      navigationBar={<CupertinoNavigationBar middle="Settings" />}
    >
      {spacer}
      {isDesktop && (
        <>
          <CupertinoFormSection header={isMacOS ? "MENU BAR" : "SYSTEM TRAY"}>
            <CupertinoFormRow
              prefix={
                <FormRowLabel
                  title={
                    isMacOS ? "Minimize to Menu Bar" : "Minimize to System Tray"
                  }
                  subtitle={
                    isMacOS
                      ? "Close window minimizes to menu bar instead of quitting"
                      : "Close window minimizes to system tray instead of quitting"
                  }
                />
              }
            >
              <CupertinoSwitch
                value={minimizeToTray}
                onChange={onMinimizeToTrayChange}
              />
            </CupertinoFormRow>
            <CupertinoFormRow
              prefix={
                <FormRowLabel
                  title="Show in Dock"
                  subtitle="Display app icon in dock while running"
                />
              }
            >
              <CupertinoSwitch
                value={showInDock}
                onChange={onShowInDockChange}
              />
            </CupertinoFormRow>
          </CupertinoFormSection>
          {spacer}
        </>
      )}
      <CupertinoFormSection header="DATABASE">
        <CupertinoFormRow
          prefix={
            <FormRowLabel
              title="Clear Database"
              subtitle="Remove all servers and reset app data"
            />
          }
        >
          <CupertinoButton
            padding={0}
            color="destructiveRed"
            onClick={onClearDatabase}
          >
            Clear
          </CupertinoButton>
        </CupertinoFormRow>
      </CupertinoFormSection>
      {spacer}
      <CupertinoFormSection header="ABOUT">
        <CupertinoFormRow prefix="Version">
          <span style={grey}>1.0.0+1</span>
        </CupertinoFormRow>
        <CupertinoFormRow prefix="Database Schema">
          <span style={grey}>Version 1</span>
        </CupertinoFormRow>
      </CupertinoFormSection>
      {dialog && (
        <SettingsAlert
          dialog={dialog}
          clearDatabaseError={clearDatabaseError}
          onConfirmClearDatabase={onConfirmClearDatabase}
          onDismissDialog={onDismissDialog}
        />
      )}
    </CupertinoPageScaffold>
  );
}
