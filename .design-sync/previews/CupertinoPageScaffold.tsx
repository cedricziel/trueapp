import {
  CupertinoApp,
  CupertinoButton,
  CupertinoFormSection,
  CupertinoNavigationBar,
  CupertinoPageScaffold,
  CupertinoTextFormFieldRow,
  DeviceFrame,
} from "@truenas-manager/ui";

function AddServerPage() {
  return (
    <CupertinoPageScaffold
      background="systemGroupedBackground"
      navigationBar={
        <CupertinoNavigationBar
          leading={
            <CupertinoButton size="small" padding={0}>
              Cancel
            </CupertinoButton>
          }
          middle="Add Server"
          trailing={
            <CupertinoButton size="small" padding={0}>
              <b>Save</b>
            </CupertinoButton>
          }
        />
      }
    >
      <CupertinoFormSection header="SERVER">
        <CupertinoTextFormFieldRow prefix="Name" value="Basement NAS" />
        <CupertinoTextFormFieldRow prefix="Host" value="https://nas.local" />
        <CupertinoTextFormFieldRow prefix="Port" placeholder="443" />
      </CupertinoFormSection>
      <CupertinoFormSection
        header="CREDENTIALS"
        footer="The password is stored in the Keychain."
      >
        <CupertinoTextFormFieldRow prefix="Username" value="admin" />
        <CupertinoTextFormFieldRow
          prefix="Password"
          value="correct-horse"
          obscureText
        />
      </CupertinoFormSection>
    </CupertinoPageScaffold>
  );
}

function Plain({ dark }: { dark?: boolean }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ width: 390, height: 480 }}
    >
      <AddServerPage />
    </CupertinoApp>
  );
}

function Framed({
  dark,
  device,
}: {
  dark?: boolean;
  device: "phone" | "tablet";
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: "max-content" }}
    >
      <DeviceFrame
        device={device}
        orientation={device === "phone" ? "portrait" : "landscape"}
        brightness={dark ? "dark" : "light"}
        scale={device === "phone" ? 0.6 : 0.55}
      >
        <AddServerPage />
      </DeviceFrame>
    </CupertinoApp>
  );
}

export const AddServerLight = () => <Plain />;

export const AddServerDark = () => <Plain dark />;

export const PhonePortraitLight = () => <Framed device="phone" />;

export const PhonePortraitDark = () => <Framed dark device="phone" />;

export const TabletLandscapeLight = () => <Framed device="tablet" />;

export const TabletLandscapeDark = () => <Framed dark device="tablet" />;
