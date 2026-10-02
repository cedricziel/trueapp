import { useState, type ReactNode } from "react";
import { ShellBackButton } from "../components/Navigation";
import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import {
  CupertinoFormRow,
  CupertinoFormSection,
  CupertinoPageScaffold,
  CupertinoSwitch,
  CupertinoTextFormFieldRow,
} from "../primitives/Forms";
import { CupertinoSegmentedControl } from "./internal/CupertinoSegmentedControl";

export type AppPortProtocol = "http" | "https";

/** A user-configured port/URL for an app, as stored by the app (not TrueNAS). */
export interface AppPortConfig {
  portNumber: number;
  /** Defaults to `http`. */
  protocol?: AppPortProtocol;
  /** e.g. "Web UI"; the row title falls back to "Port <n>". */
  serviceName?: string;
  /** Overrides `apiUrl` and the default `<protocol>://localhost:<port>`. */
  customUrl?: string;
  /** Portal URL reported by the TrueNAS API. */
  apiUrl?: string;
  isPrimary?: boolean;
  /** Defaults to true. */
  isEnabled?: boolean;
}

export interface AppConfig {
  /** The TrueNAS app name, e.g. "jellyfin". */
  appName: string;
  displayName?: string;
  isEnabled: boolean;
  ports: AppPortConfig[];
}

export interface PortEditorState {
  port: AppPortConfig;
  /** "Add Port" with no Set as Primary / Delete section. */
  isNew?: boolean;
}

export interface AppConfigurationScreenProps {
  config: AppConfig;
  /** Display Name field text. Defaults to `displayName ?? appName`. */
  displayNameValue?: string;
  /** Primary URL field text. Defaults to the primary port's custom URL. */
  primaryUrlValue?: string;
  /** Open the Add/Edit Port modal over the screen. */
  portEditor?: PortEditorState;
  onBack?: () => void;
  onSave?: () => void;
  onDisplayNameChange?: (value: string) => void;
  onEnabledChange?: (value: boolean) => void;
  onPrimaryUrlChange?: (value: string) => void;
  onOpenPortUrl?: (url: string) => void;
  onEditPort?: (port: AppPortConfig) => void;
  onAddPort?: () => void;
  onPortEditorCancel?: () => void;
  onPortEditorSave?: (port: AppPortConfig) => void;
  onPortEditorDelete?: () => void;
  onPortEditorSetPrimary?: () => void;
}

function effectiveUrl(port: AppPortConfig) {
  return (
    port.customUrl ??
    port.apiUrl ??
    `${port.protocol ?? "http"}://localhost:${port.portNumber}`
  );
}

/**
 * The per-app "Configure <app>" form: display name, enabled switch and primary
 * URL, the app's ports with Primary badges and open/edit buttons, and an Add
 * Port button that opens the port editor. Reached from "Edit Configuration"
 * in an installed app's detail action sheet.
 */
export function AppConfigurationScreen({
  config,
  displayNameValue,
  primaryUrlValue,
  portEditor,
  onBack,
  onSave,
  onDisplayNameChange,
  onEnabledChange,
  onPrimaryUrlChange,
  onOpenPortUrl,
  onEditPort,
  onAddPort,
  onPortEditorCancel,
  onPortEditorSave,
  onPortEditorDelete,
  onPortEditorSetPrimary,
}: AppConfigurationScreenProps) {
  const primary = config.ports.find((p) => p.isPrimary);
  return (
    <CupertinoPageScaffold
      background="systemGroupedBackground"
      navigationBar={
        <CupertinoNavigationBar
          leading={<ShellBackButton onClick={onBack} />}
          middle={`Configure ${config.appName}`}
          trailing={<TextButton onClick={onSave}>Save</TextButton>}
        />
      }
    >
      <div style={{ padding: 16 }}>
        <CupertinoFormSection header="App Information">
          <CupertinoTextFormFieldRow
            prefix="Display Name"
            placeholder={config.appName}
            value={displayNameValue ?? config.displayName ?? config.appName}
            onChange={onDisplayNameChange}
          />
          <CupertinoFormRow prefix="Enabled">
            <CupertinoSwitch
              value={config.isEnabled}
              onChange={onEnabledChange}
            />
          </CupertinoFormRow>
          <CupertinoTextFormFieldRow
            prefix="Primary URL"
            placeholder="https://example.com:8080"
            value={primaryUrlValue ?? primary?.customUrl ?? ""}
            onChange={onPrimaryUrlChange}
          />
        </CupertinoFormSection>
        <div style={{ height: 24 }} />
        <CupertinoFormSection header="Ports">
          {config.ports.length === 0 ? (
            <CenteredRow>
              <span style={{ color: "var(--cupertino-secondary-label)" }}>
                No ports configured
              </span>
            </CenteredRow>
          ) : (
            config.ports.map((port, i) => (
              <PortRow
                key={i}
                port={port}
                onOpen={() => onOpenPortUrl?.(effectiveUrl(port))}
                onEdit={() => onEditPort?.(port)}
              />
            ))
          )}
        </CupertinoFormSection>
        <div style={{ height: 24 }} />
        <CupertinoFormSection>
          <CenteredRow>
            <CupertinoButton onClick={onAddPort}>
              <CupertinoIcon icon="add" />
              Add Port
            </CupertinoButton>
          </CenteredRow>
        </CupertinoFormSection>
      </div>

      {portEditor && (
        <PortEditModal
          key={JSON.stringify(portEditor.port)}
          port={portEditor.port}
          isNewPort={portEditor.isNew ?? false}
          onCancel={onPortEditorCancel}
          onSave={onPortEditorSave}
          onDelete={onPortEditorDelete}
          onSetPrimary={onPortEditorSetPrimary}
        />
      )}
    </CupertinoPageScaffold>
  );
}

function TextButton({
  children,
  color,
  onClick,
}: {
  children: ReactNode;
  color?: string;
  onClick?: () => void;
}) {
  return (
    <CupertinoButton padding={0} minSize={0} color={color} onClick={onClick}>
      {children}
    </CupertinoButton>
  );
}

function CenteredRow({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        minHeight: 44,
        padding: "6px 20px",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {children}
    </div>
  );
}

function PortRow({
  port,
  onOpen,
  onEdit,
}: {
  port: AppPortConfig;
  onOpen: () => void;
  onEdit: () => void;
}) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        padding: "12px 6px 12px 20px",
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 16, fontWeight: 500 }}>
          {port.serviceName ?? `Port ${port.portNumber}`}
        </div>
        <div
          style={{
            marginTop: 4,
            fontSize: 14,
            color: "var(--cupertino-secondary-label)",
            overflowWrap: "anywhere",
          }}
        >
          {effectiveUrl(port)}
        </div>
      </div>
      {port.isPrimary && (
        <span
          style={{
            padding: "4px 8px",
            borderRadius: 12,
            background: "var(--cupertino-system-blue)",
            color: "var(--cupertino-white)",
            fontSize: 12,
            fontWeight: 500,
          }}
        >
          Primary
        </span>
      )}
      <div style={{ width: 8 }} />
      <CupertinoButton padding={0} onClick={onOpen}>
        <CupertinoIcon icon="link" size={20} />
      </CupertinoButton>
      <CupertinoButton padding={0} onClick={onEdit}>
        <CupertinoIcon icon="pencil" size={20} />
      </CupertinoButton>
    </div>
  );
}

/**
 * The Add/Edit Port modal (a full page scaffold shown via
 * `showCupertinoModalPopup`): port, HTTP/HTTPS, service name, custom URL and
 * enabled; existing ports also get Set as Primary and Delete Port.
 */
function PortEditModal({
  port,
  isNewPort,
  onCancel,
  onSave,
  onDelete,
  onSetPrimary,
}: {
  port: AppPortConfig;
  isNewPort: boolean;
  onCancel?: () => void;
  onSave?: (port: AppPortConfig) => void;
  onDelete?: () => void;
  onSetPrimary?: () => void;
}) {
  const [portText, setPortText] = useState(String(port.portNumber));
  const [protocol, setProtocol] = useState<AppPortProtocol>(
    port.protocol ?? "http",
  );
  const [serviceName, setServiceName] = useState(port.serviceName ?? "");
  const [customUrl, setCustomUrl] = useState(port.customUrl ?? "");
  const [isEnabled, setIsEnabled] = useState(port.isEnabled ?? true);

  const save = () => {
    const portNumber = Number.parseInt(portText, 10);
    if (Number.isNaN(portNumber)) return;
    onSave?.({
      ...port,
      portNumber,
      protocol,
      serviceName: serviceName || undefined,
      customUrl: customUrl || undefined,
      isEnabled,
    });
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 1000,
        display: "flex",
        flexDirection: "column",
        background: "rgba(0,0,0,0.2)",
      }}
    >
      <CupertinoPageScaffold
        background="systemGroupedBackground"
        navigationBar={
          <CupertinoNavigationBar
            leading={<TextButton onClick={onCancel}>Cancel</TextButton>}
            middle={isNewPort ? "Add Port" : "Edit Port"}
            trailing={<TextButton onClick={save}>Save</TextButton>}
          />
        }
      >
        <div style={{ padding: 16 }}>
          <CupertinoFormSection>
            <CupertinoTextFormFieldRow
              prefix="Port"
              value={portText}
              onChange={(v) => setPortText(v.replace(/\D/g, ""))}
            />
            <CupertinoFormRow prefix="Protocol">
              <div style={{ width: 160 }}>
                <CupertinoSegmentedControl
                  groupValue={protocol}
                  onValueChanged={setProtocol}
                  segments={[
                    { value: "http", label: "HTTP" },
                    { value: "https", label: "HTTPS" },
                  ]}
                />
              </div>
            </CupertinoFormRow>
            <CupertinoTextFormFieldRow
              prefix="Service Name"
              placeholder="e.g., Web UI, API"
              value={serviceName}
              onChange={setServiceName}
            />
            <CupertinoTextFormFieldRow
              prefix="Custom URL"
              placeholder="Leave empty for default"
              value={customUrl}
              onChange={setCustomUrl}
            />
            <CupertinoFormRow prefix="Enabled">
              <CupertinoSwitch value={isEnabled} onChange={setIsEnabled} />
            </CupertinoFormRow>
          </CupertinoFormSection>
          {!isNewPort && (onSetPrimary || onDelete) && (
            <>
              <div style={{ height: 24 }} />
              <CupertinoFormSection>
                {onSetPrimary && (
                  <CenteredRow>
                    <CupertinoButton onClick={onSetPrimary}>
                      Set as Primary
                    </CupertinoButton>
                  </CenteredRow>
                )}
                {onDelete && (
                  <CenteredRow>
                    <CupertinoButton color="destructiveRed" onClick={onDelete}>
                      Delete Port
                    </CupertinoButton>
                  </CenteredRow>
                )}
              </CupertinoFormSection>
            </>
          )}
        </div>
      </CupertinoPageScaffold>
    </div>
  );
}
