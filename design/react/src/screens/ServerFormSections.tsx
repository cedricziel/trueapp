import type { ReactNode } from "react";
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
  CupertinoSwitch,
  CupertinoTextField,
  CupertinoTextFormFieldRow,
} from "../primitives/Forms";

/** The editable fields shared by the Add Server and Edit Server forms. */
export interface ServerFormValues {
  name: string;
  host: string;
  /** Empty means the protocol default. */
  port: string;
  localUrl: string;
  username: string;
  password: string;
  useHttps: boolean;
  allowUntrustedCertificates: boolean;
  trustedWifiSsids: string[];
  /** Text typed into the "Add SSID" field, not yet added. */
  ssidDraft: string;
}

export interface ConnectionTestResult {
  /** Green when true, red otherwise. */
  success: boolean;
  message: string;
}

/** The alert the server form is currently showing, if any. */
export type ServerFormDialog = "noWifiDetected" | "wifiDetectionError";

/** Props both server form screens share: values, Wi-Fi detection and connection-test state, callbacks. */
export interface ServerFormProps {
  values: ServerFormValues;
  /** The detected current Wi-Fi network; offered as "Add Current" unless already trusted. */
  currentWifiSsid?: string;
  /** Shows a spinner in the "Current Network" row. */
  isDetectingWifi?: boolean;
  isTestingConnection?: boolean;
  connectionTestResult?: ConnectionTestResult;
  dialog?: ServerFormDialog;
  /** The failure text for the `wifiDetectionError` dialog. */
  wifiDetectionError?: string;
  /** Receives the changed fields. Turning HTTPS on or off also clears `port`. */
  onChange?: (patch: Partial<ServerFormValues>) => void;
  onCancel?: () => void;
  onSave?: () => void;
  onDetectWifi?: () => void;
  onAddCurrentWifi?: () => void;
  /** "Add" next to the SSID field; receives the trimmed draft. */
  onAddWifiSsid?: (ssid: string) => void;
  onRemoveWifiSsid?: (ssid: string) => void;
  onTestConnection?: () => void;
  onDismissDialog?: () => void;
}

const sectionGap = <div style={{ height: 16 }} />;

export function ServerFormNavigationBar({
  title,
  canSave,
  onCancel,
  onSave,
}: {
  title: string;
  canSave: boolean;
  onCancel?: () => void;
  onSave?: () => void;
}) {
  return (
    <CupertinoNavigationBar
      middle={title}
      leading={
        <CupertinoButton padding={0} minSize={0} onClick={onCancel}>
          Cancel
        </CupertinoButton>
      }
      trailing={
        <CupertinoButton
          padding={0}
          minSize={0}
          disabled={!canSave}
          onClick={onSave}
        >
          Save
        </CupertinoButton>
      }
    />
  );
}

/** A `CupertinoFormRow` whose trailing control takes all remaining width, like Flutter's `Row(Expanded(...))`. */
function ExpandedFormRow({
  prefix,
  children,
}: {
  prefix: ReactNode;
  children: ReactNode;
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        minHeight: 44,
        padding: "6px 16px 6px 20px",
        boxSizing: "border-box",
      }}
    >
      <span style={{ flexShrink: 0 }}>{prefix}</span>
      <div
        style={{
          flex: 1,
          minWidth: 0,
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        {children}
      </div>
    </div>
  );
}

function TrustedWifiSection({
  values,
  currentWifiSsid,
  isDetectingWifi,
  onChange,
  onDetectWifi,
  onAddCurrentWifi,
  onAddWifiSsid,
  onRemoveWifiSsid,
}: ServerFormProps) {
  const suggestCurrent =
    currentWifiSsid != null &&
    !values.trustedWifiSsids.includes(currentWifiSsid);
  return (
    <CupertinoFormSection header="TRUSTED WI-FI NETWORKS">
      {suggestCurrent && (
        <CupertinoFormRow
          prefix={
            <div style={{ display: "flex", flexDirection: "column" }}>
              <span>Current Network</span>
              <span
                style={{ fontSize: 14, color: "var(--cupertino-system-grey)" }}
              >
                {currentWifiSsid}
              </span>
            </div>
          }
        >
          <CupertinoButton padding={0} onClick={onAddCurrentWifi}>
            Add Current
          </CupertinoButton>
        </CupertinoFormRow>
      )}
      {currentWifiSsid == null && !isDetectingWifi && (
        <CupertinoFormRow prefix="Current Network">
          <CupertinoButton padding={0} onClick={onDetectWifi}>
            Detect
          </CupertinoButton>
        </CupertinoFormRow>
      )}
      {isDetectingWifi && (
        <CupertinoFormRow prefix="Current Network">
          <CupertinoActivityIndicator />
        </CupertinoFormRow>
      )}
      <ExpandedFormRow prefix="Add SSID">
        <CupertinoTextField
          placeholder="Wi-Fi network name"
          value={values.ssidDraft}
          onChange={onChange && ((ssidDraft) => onChange({ ssidDraft }))}
          style={{ flex: 1, minWidth: 0 }}
        />
        <CupertinoButton
          padding={0}
          onClick={() => onAddWifiSsid?.(values.ssidDraft.trim())}
        >
          Add
        </CupertinoButton>
      </ExpandedFormRow>
      {values.trustedWifiSsids.map((ssid) => (
        <CupertinoFormRow key={ssid} prefix={ssid}>
          <CupertinoButton padding={0} onClick={() => onRemoveWifiSsid?.(ssid)}>
            Remove
          </CupertinoButton>
        </CupertinoFormRow>
      ))}
    </CupertinoFormSection>
  );
}

function ServerFormAlert({
  dialog,
  wifiDetectionError,
  onDismissDialog,
}: Pick<ServerFormProps, "wifiDetectionError" | "onDismissDialog"> & {
  dialog: ServerFormDialog;
}) {
  const content =
    dialog === "noWifiDetected" ? (
      <>
        Unable to detect current Wi-Fi network. This could be due to:
        <br />
        <br />• Not connected to Wi-Fi
        <br />• Location permission not granted
        <br />• Platform restrictions (macOS/iOS)
        <br />
        <br />
        You can still manually enter network names.
      </>
    ) : (
      <>
        Failed to detect Wi-Fi network: {wifiDetectionError}
        <br />
        <br />
        You can still manually enter network names.
      </>
    );
  return (
    <CupertinoAlertDialog
      barrier
      title={
        dialog === "noWifiDetected"
          ? "No Wi-Fi Detected"
          : "Wi-Fi Detection Error"
      }
      content={content}
      actions={[
        <CupertinoDialogAction key="ok" onClick={onDismissDialog}>
          OK
        </CupertinoDialogAction>,
      ]}
    />
  );
}

/**
 * The scrolling body of the Add/Edit Server screens: server details, local
 * network, trusted Wi-Fi, authentication, connection switches and the
 * connection test, plus any open alert.
 */
export function ServerFormBody(
  props: ServerFormProps & {
    /** Password placeholder; "Loading..." while the edit screen reads the Keychain. */
    passwordPlaceholder: string;
    /** Extra switch rows after "Allow Untrusted Certificates" (the edit screen's default-server toggle). */
    extraSwitchRows?: ReactNode;
    canTestConnection: boolean;
  },
) {
  const {
    values,
    isTestingConnection = false,
    connectionTestResult,
    dialog,
    wifiDetectionError,
    onChange,
    onTestConnection,
    onDismissDialog,
    passwordPlaceholder,
    extraSwitchRows,
    canTestConnection,
  } = props;
  const field = (
    key: "name" | "host" | "port" | "localUrl" | "username" | "password",
  ) => onChange && ((value: string) => onChange({ [key]: value }));

  return (
    <div style={{ padding: 16 }}>
      <CupertinoFormSection header="SERVER DETAILS">
        <CupertinoTextFormFieldRow
          prefix="Name"
          placeholder="My TrueNAS Server"
          value={values.name}
          onChange={field("name")}
        />
        <CupertinoTextFormFieldRow
          prefix="Host"
          placeholder="192.168.1.100"
          value={values.host}
          onChange={field("host")}
        />
        <CupertinoTextFormFieldRow
          prefix="Port"
          placeholder="Default port (443 for HTTPS, 80 for HTTP)"
          value={values.port}
          onChange={field("port")}
        />
      </CupertinoFormSection>
      {sectionGap}
      <CupertinoFormSection header="LOCAL NETWORK (OPTIONAL)">
        <CupertinoTextFormFieldRow
          prefix="Local URL"
          placeholder="http://192.168.1.100:80"
          value={values.localUrl}
          onChange={field("localUrl")}
        />
      </CupertinoFormSection>
      {sectionGap}
      <TrustedWifiSection {...props} />
      {sectionGap}
      <CupertinoFormSection header="AUTHENTICATION">
        <CupertinoTextFormFieldRow
          prefix="Username"
          placeholder="admin"
          value={values.username}
          onChange={field("username")}
        />
        <CupertinoTextFormFieldRow
          prefix="Password"
          placeholder={passwordPlaceholder}
          obscureText
          value={values.password}
          onChange={field("password")}
        />
      </CupertinoFormSection>
      {sectionGap}
      <CupertinoFormSection>
        <CupertinoFormRow prefix="Use HTTPS">
          <CupertinoSwitch
            value={values.useHttps}
            onChange={
              onChange && ((useHttps) => onChange({ useHttps, port: "" }))
            }
          />
        </CupertinoFormRow>
        <CupertinoFormRow prefix="Allow Untrusted Certificates">
          <CupertinoSwitch
            value={values.allowUntrustedCertificates}
            onChange={
              onChange &&
              ((allowUntrustedCertificates) =>
                onChange({ allowUntrustedCertificates }))
            }
          />
        </CupertinoFormRow>
        {extraSwitchRows}
      </CupertinoFormSection>
      {sectionGap}
      <CupertinoFormSection header="CONNECTION TEST">
        <CupertinoFormRow prefix="Test Connection">
          <CupertinoButton
            padding="0 16px"
            disabled={!canTestConnection || isTestingConnection}
            onClick={onTestConnection}
          >
            {isTestingConnection ? <CupertinoActivityIndicator /> : "Test"}
          </CupertinoButton>
        </CupertinoFormRow>
        {connectionTestResult && (
          // CupertinoFormRow lets its prefix shrink to nothing, so a long message would cover "Result".
          <ExpandedFormRow prefix="Result">
            <span
              style={{
                flex: 1,
                textAlign: "right",
                color: connectionTestResult.success
                  ? "var(--cupertino-system-green)"
                  : "var(--cupertino-system-red)",
              }}
            >
              {connectionTestResult.message}
            </span>
          </ExpandedFormRow>
        )}
      </CupertinoFormSection>
      {dialog && (
        <ServerFormAlert
          dialog={dialog}
          wifiDetectionError={wifiDetectionError}
          onDismissDialog={onDismissDialog}
        />
      )}
    </div>
  );
}
