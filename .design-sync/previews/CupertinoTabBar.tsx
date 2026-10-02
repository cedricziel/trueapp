import {
  CupertinoApp,
  CupertinoNavigationBar,
  CupertinoTabBar,
  DeviceFrame,
  ServerListTile,
} from "@truenas-manager/ui";

function Bar({
  dark,
  width,
  currentIndex = 0,
}: {
  dark?: boolean;
  width: number;
  currentIndex?: number;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ width, paddingTop: 16 }}
    >
      <CupertinoTabBar currentIndex={currentIndex} />
    </CupertinoApp>
  );
}

function PhoneScreen({ dark }: { dark?: boolean }) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width: 230 }}
    >
      <DeviceFrame
        device="phone"
        orientation="portrait"
        brightness={dark ? "dark" : "light"}
        scale={0.5}
      >
        <div style={{ flex: 1, minHeight: 0 }}>
          <CupertinoNavigationBar largeTitle="Servers" />
          <ServerListTile
            server={{
              name: "Basement NAS",
              baseUrl: "https://nas.local",
              isActive: true,
            }}
            status={{ connectivity: "online", cpuUsage: 18, storageUsage: 61 }}
          />
          <ServerListTile
            server={{ name: "Office Mini", baseUrl: "http://192.168.1.40" }}
            status={{ connectivity: "offline" }}
          />
        </div>
        <CupertinoTabBar currentIndex={0} />
      </DeviceFrame>
    </CupertinoApp>
  );
}

export const PhonePortraitLight = () => <Bar width={390} />;

export const PhonePortraitDark = () => <Bar dark width={390} />;

export const PhoneLandscapeLight = () => <Bar width={844} currentIndex={1} />;

export const PhoneLandscapeDark = () => (
  <Bar dark width={844} currentIndex={1} />
);

export const InPhoneFrameLight = () => <PhoneScreen />;

export const InPhoneFrameDark = () => <PhoneScreen dark />;
