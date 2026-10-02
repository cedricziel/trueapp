import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  SettingsScreen,
  type DeviceKind,
  type SettingsScreenProps,
} from "@truenas-manager/ui";

function Shell({
  device,
  orientation,
  dark,
  scale,
  props,
}: {
  device: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
  props?: SettingsScreenProps;
}) {
  // Desktop previews stand in for the macOS build, which adds the MENU BAR section.
  const platform = device === "desktop" ? "macos" : "ios";
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={1}>
        <SettingsScreen
          platform={platform}
          minimizeToTray
          showInDock
          {...props}
        />
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

export const PhonePortraitLight = () => <Shell device="phone" scale={0.6} />;
export const PhonePortraitDark = () => (
  <Shell device="phone" dark scale={0.6} />
);
export const PhoneLandscapeLight = () => (
  <Shell device="phone" orientation="landscape" scale={0.6} />
);
export const TabletPortraitLight = () => <Shell device="tablet" scale={0.45} />;
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark scale={0.45} />
);
export const DesktopLight = () => <Shell device="desktop" scale={0.5} />;
export const DesktopDark = () => <Shell device="desktop" dark scale={0.5} />;

export const SessionUnlockedLight = () => (
  <Shell device="phone" scale={0.6} props={{ isSessionValid: true }} />
);
export const ClearDatabaseConfirmDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{ dialog: "clearDatabaseConfirm" }}
  />
);
export const SessionLockedDialogLight = () => (
  <Shell device="phone" scale={0.6} props={{ dialog: "sessionLocked" }} />
);
export const RecreatingDatabaseDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{ dialog: "clearingDatabase" }}
  />
);
export const ClearDatabaseErrorLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{
      dialog: "clearDatabaseError",
      clearDatabaseError:
        "FileSystemException: Cannot delete file, path = 'truenas_manager.sqlite'",
    }}
  />
);
export const WindowsSystemTrayDesktopLight = () => (
  <Shell
    device="desktop"
    scale={0.5}
    props={{ platform: "windows", minimizeToTray: false }}
  />
);
