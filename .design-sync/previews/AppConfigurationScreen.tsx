import {
  AdaptiveNavigationScaffold,
  AppConfigurationScreen,
  DeviceFrame,
  type AppConfig,
  type AppConfigurationScreenProps,
  type DeviceKind,
} from "@truenas-manager/ui";

const jellyfin: AppConfig = {
  appName: "jellyfin",
  displayName: "Jellyfin",
  isEnabled: true,
  ports: [
    {
      portNumber: 30013,
      serviceName: "Web UI",
      customUrl: "https://media.example.net",
      isPrimary: true,
    },
    {
      portNumber: 8920,
      protocol: "https",
      serviceName: "HTTPS",
      apiUrl: "https://nas.local:8920",
    },
    { portNumber: 1900 },
  ],
};

const homeAssistant: AppConfig = {
  appName: "home-assistant",
  isEnabled: false,
  ports: [],
};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
} & Partial<AppConfigurationScreenProps>) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <AppConfigurationScreen config={jellyfin} {...props} />
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Shell />;
export const PhonePortraitDark = () => <Shell dark />;
export const PhoneLandscapeLight = () => <Shell orientation="landscape" />;
export const TabletPortraitLight = () => <Shell device="tablet" scale={0.45} />;
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark scale={0.45} />
);
export const DesktopLight = () => <Shell device="desktop" scale={0.5} />;
export const DesktopDark = () => <Shell device="desktop" dark scale={0.5} />;

export const NoPortsDisabled = () => <Shell config={homeAssistant} />;
export const EditPortModal = () => (
  <Shell
    portEditor={{ port: jellyfin.ports[1] }}
    onPortEditorDelete={() => {}}
    onPortEditorSetPrimary={() => {}}
  />
);
export const AddPortModalDark = () => (
  <Shell dark portEditor={{ port: { portNumber: 80 }, isNew: true }} />
);
