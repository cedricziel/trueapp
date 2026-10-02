import type { ReactNode } from "react";
import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  UserProfileScreen,
  type DeviceKind,
  type UserProfileScreenProps,
} from "@truenas-manager/ui";

const now = new Date("2026-10-02T09:30:00Z");

const base: UserProfileScreenProps = {
  server: {
    name: "Basement NAS",
    host: "nas.local",
    port: 443,
    useHttps: true,
    lastConnected: new Date(now.getTime() - 14 * 60_000),
  },
  user: {
    username: "truenas_admin",
    fullName: "Ada Lindqvist",
    uid: 950,
    gid: 950,
    homeDirectory: "/mnt/tank/home/truenas_admin",
    shell: "/usr/bin/zsh",
    sourceDisplayName: "Local Account",
    isLocal: true,
    isAdministrator: true,
    hasTwoFactor: true,
    groupList: [544, 545, 950, 3001],
  },
  now,
};

function Shell({
  device = "phone",
  orientation,
  dark,
  children,
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  children: ReactNode;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={device === "phone" ? 0.6 : device === "tablet" ? 0.45 : 0.5}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        {children}
      </AdaptiveNavigationScaffold>
    </DeviceFrame>
  );
}

const Screen = (props: Partial<UserProfileScreenProps>) => (
  <UserProfileScreen {...base} {...props} />
);

export const PhonePortraitLight = () => (
  <Shell>
    <Screen />
  </Shell>
);
export const PhonePortraitDark = () => (
  <Shell dark>
    <Screen />
  </Shell>
);
export const PhoneLandscapeLight = () => (
  <Shell orientation="landscape">
    <Screen />
  </Shell>
);
export const TabletPortraitLight = () => (
  <Shell device="tablet">
    <Screen />
  </Shell>
);
export const TabletLandscapeDark = () => (
  <Shell device="tablet" orientation="landscape" dark>
    <Screen />
  </Shell>
);
export const DesktopLight = () => (
  <Shell device="desktop">
    <Screen />
  </Shell>
);
export const DesktopDark = () => (
  <Shell device="desktop" dark>
    <Screen />
  </Shell>
);
export const LoadingLight = () => (
  <Shell>
    <Screen user={undefined} isLoadingUser />
  </Shell>
);
export const ErrorDark = () => (
  <Shell dark>
    <Screen
      user={undefined}
      userError="[ENOMETHOD] auth.me: permission denied for this API key."
    />
  </Shell>
);
export const NoUserLight = () => (
  <Shell>
    <Screen user={undefined} />
  </Shell>
);
