import { CupertinoPageScaffold } from "../primitives/Forms";
import {
  ServerFormBody,
  ServerFormNavigationBar,
  type ServerFormProps,
} from "./ServerFormSections";

export type {
  ConnectionTestResult,
  ServerFormDialog,
  ServerFormValues,
} from "./ServerFormSections";

export type AddServerScreenProps = ServerFormProps;

/**
 * The "Add Server" form, pushed from the home screen's + button: server
 * details, local network, trusted Wi-Fi networks, credentials and a
 * connection test. Save and Test enable once name, host, username and
 * password are filled in.
 */
export function AddServerScreen(props: AddServerScreenProps) {
  const { name, host, username, password } = props.values;
  const isValid = !!(name && host && username && password);
  return (
    <CupertinoPageScaffold
      background="systemGroupedBackground"
      navigationBar={
        <ServerFormNavigationBar
          title="Add Server"
          canSave={isValid}
          onCancel={props.onCancel}
          onSave={props.onSave}
        />
      }
    >
      <ServerFormBody
        {...props}
        passwordPlaceholder="Password"
        canTestConnection={isValid}
      />
    </CupertinoPageScaffold>
  );
}
