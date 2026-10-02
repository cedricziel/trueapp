import {
  CupertinoFormRow,
  CupertinoPageScaffold,
  CupertinoSwitch,
} from "../primitives/Forms";
import {
  ServerFormBody,
  ServerFormNavigationBar,
  type ServerFormProps,
} from "./ServerFormSections";

export interface EditServerScreenProps extends ServerFormProps {
  /** "Set as Default Server" switch. */
  isDefault: boolean;
  onIsDefaultChange?: (value: boolean) => void;
  /** The password is still being read from the Keychain: its placeholder reads "Loading...". */
  isLoadingCredentials?: boolean;
}

/**
 * The "Edit Server" form for a saved server: the Add Server form prefilled
 * with its settings, plus a default-server switch. The password may stay
 * empty here because the Keychain already holds it.
 */
export function EditServerScreen({
  isDefault,
  onIsDefaultChange,
  isLoadingCredentials = false,
  ...props
}: EditServerScreenProps) {
  const { name, host, username } = props.values;
  const isValid = !!(name && host && username);
  return (
    <CupertinoPageScaffold
      background="systemGroupedBackground"
      navigationBar={
        <ServerFormNavigationBar
          title="Edit Server"
          canSave={isValid}
          onCancel={props.onCancel}
          onSave={props.onSave}
        />
      }
    >
      <ServerFormBody
        {...props}
        passwordPlaceholder={isLoadingCredentials ? "Loading..." : "Password"}
        canTestConnection
        extraSwitchRows={
          <CupertinoFormRow prefix="Set as Default Server">
            <CupertinoSwitch value={isDefault} onChange={onIsDefaultChange} />
          </CupertinoFormRow>
        }
      />
    </CupertinoPageScaffold>
  );
}
