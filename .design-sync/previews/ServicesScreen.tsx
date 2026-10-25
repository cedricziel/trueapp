import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServicesScreen,
  type ConnectionError,
  type DeviceKind,
  type ServiceStatus,
  type ServicesScreenProps,
} from "@truenas-manager/ui";

const services: ServiceStatus[] = [
  { id: "cifs", isRunning: true, isEnabled: true },
  { id: "nfs", isRunning: true, isEnabled: true },
  { id: "ssh", isRunning: false, isEnabled: false },
  { id: "iscsitarget", isRunning: false, isEnabled: true },
  { id: "smartd", isRunning: true, isEnabled: true },
  { id: "snmp", isRunning: false, isEnabled: false },
  { id: "ups", isRunning: false, isEnabled: false },
  { id: "docker", isRunning: true, isEnabled: true },
];

const unreachable: ConnectionError = {
  type: "networkUnreachable",
  shortMessage: "Server not reachable",
  userFriendlyMessage:
    "Cannot reach the server. Check the IP address or hostname, your network connection, and that the server is powered on.",
  isRetryable: true,
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
} & Partial<ServicesScreenProps>) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <ServicesScreen
          serverName="Basement NAS"
          services={services}
          onBack={() => {}}
          onJobs={() => {}}
          onRetry={() => {}}
          onSettings={() => {}}
          onAction={() => {}}
          onDismissActionError={() => {}}
          {...props}
        />
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

export const BusyServiceLight = () => <Shell busyServiceIds={["nfs"]} />;
export const ActionErrorDark = () => (
  <Shell
    dark
    actionError="Failed to start iSCSI: [EFAULT] Failed to start iscsitarget: no targets are configured."
  />
);
export const StopRestartSheetLight = () => (
  <Shell actionSheetServiceId="cifs" />
);
export const StartSheetDark = () => <Shell dark actionSheetServiceId="ssh" />;
export const LoadingLight = () => <Shell loading services={[]} />;
export const EmptyDark = () => <Shell dark services={[]} />;
export const LoadErrorLight = () => (
  <Shell connectionError={unreachable} services={[]} />
);
