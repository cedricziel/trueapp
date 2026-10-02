import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  EditServerScreen,
  type DeviceKind,
  type EditServerScreenProps,
  type ServerFormValues,
} from "@truenas-manager/ui";

const basement: ServerFormValues = {
  name: "Basement NAS",
  host: "nas.local",
  port: "",
  localUrl: "http://192.168.1.10:80",
  username: "admin",
  password: "correct-horse-battery",
  useHttps: true,
  allowUntrustedCertificates: true,
  trustedWifiSsids: ["HomeNet", "HomeNet-5G"],
  ssidDraft: "",
};

const saved: EditServerScreenProps = { values: basement, isDefault: true };

/** Scrolls the screen's scroller to the bottom so the CONNECTION TEST rows are in frame. */
function scrollToBottom(el: HTMLDivElement | null) {
  if (!el) return;
  for (const node of Array.from(el.querySelectorAll<HTMLElement>("div"))) {
    if (getComputedStyle(node).overflowY === "auto") {
      node.scrollTop = node.scrollHeight;
    }
  }
}

function Shell({
  device,
  orientation,
  dark,
  scale,
  scrolled,
  props = saved,
}: {
  device: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
  /** Show the bottom of the form. */
  scrolled?: boolean;
  props?: EditServerScreenProps;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <div
          style={{ display: "contents" }}
          ref={scrolled ? scrollToBottom : undefined}
        >
          <EditServerScreen {...props} />
        </div>
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

export const LoadingCredentialsLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{
      ...saved,
      values: { ...basement, password: "" },
      isLoadingCredentials: true,
    }}
  />
);
export const ConnectionSucceededDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    scrolled
    props={{
      ...saved,
      connectionTestResult: {
        success: true,
        message: "Connection successful!",
      },
    }}
  />
);
export const TestingConnectionLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    scrolled
    props={{ ...saved, isTestingConnection: true }}
  />
);
export const NotDefaultTestFailedDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    scrolled
    props={{
      values: { ...basement, password: "wrong-password" },
      isDefault: false,
      connectionTestResult: {
        success: false,
        message: "Invalid credentials or connection failed",
      },
    }}
  />
);
export const MissingNameLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{ ...saved, values: { ...basement, name: "" } }}
  />
);
export const WifiDetectionErrorDialogLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{
      ...saved,
      dialog: "wifiDetectionError",
      wifiDetectionError: "PlatformException(PERMISSION_DENIED)",
    }}
  />
);
