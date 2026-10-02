import {
  AddServerScreen,
  AdaptiveNavigationScaffold,
  DeviceFrame,
  type AddServerScreenProps,
  type DeviceKind,
  type ServerFormValues,
} from "@truenas-manager/ui";

const blank: ServerFormValues = {
  name: "",
  host: "",
  port: "",
  localUrl: "",
  username: "",
  password: "",
  useHttps: true,
  allowUntrustedCertificates: false,
  trustedWifiSsids: [],
  ssidDraft: "",
};

const filled: ServerFormValues = {
  ...blank,
  name: "Office Mini",
  host: "office.example.net",
  localUrl: "http://192.168.1.40:80",
  username: "admin",
  password: "correct-horse-battery",
  allowUntrustedCertificates: true,
  trustedWifiSsids: ["Office-5G"],
};

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
  props = { values: filled },
}: {
  device: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
  /** Show the bottom of the form. */
  scrolled?: boolean;
  props?: AddServerScreenProps;
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
          <AddServerScreen {...props} />
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

export const IncompleteFormLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{ values: { ...blank, name: "Office Mini", host: "192.168.1.40" } }}
  />
);
export const ConnectionSucceededDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    scrolled
    props={{
      values: filled,
      connectionTestResult: {
        success: true,
        message: "✅ Connection successful!",
      },
    }}
  />
);
export const ConnectionFailedLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    scrolled
    props={{
      values: filled,
      connectionTestResult: {
        success: false,
        message:
          '❌ Connection failed: SSL/TLS error. Try enabling "Allow Untrusted Certificates".',
      },
    }}
  />
);
export const DetectingWifiDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{ values: { ...filled, ssidDraft: "Guest" }, isDetectingWifi: true }}
  />
);
export const CurrentWifiSuggestedLight = () => (
  <Shell
    device="phone"
    scale={0.6}
    props={{ values: filled, currentWifiSsid: "HomeNet" }}
  />
);
export const NoWifiDetectedDialogDark = () => (
  <Shell
    device="phone"
    dark
    scale={0.6}
    props={{ values: filled, dialog: "noWifiDetected" }}
  />
);
