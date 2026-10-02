import {
  DeviceFrame,
  InfoRow,
  ResponsiveRow,
  SectionCard,
  SectionHeader,
  StorageMetricWidget,
  type DeviceKind,
} from "@truenas-manager/ui";

function Dashboard() {
  return (
    <div
      style={{
        padding: 16,
        display: "flex",
        flexDirection: "column",
        gap: 16,
      }}
    >
      <SectionHeader title="Basement NAS" />
      <ResponsiveRow>
        <SectionCard title="CPU" icon="speedometer">
          <InfoRow label="Usage" value="34%" />
          <InfoRow label="Load average" value="1.12 · 0.98 · 0.87" />
          <InfoRow label="Temperature" value="52 °C" valueColor="systemGreen" />
        </SectionCard>
        <SectionCard title="Memory" icon="memories" iconColor="systemPurple">
          <InfoRow label="Physical" value="32 GiB" />
          <InfoRow label="ZFS ARC" value="10.6 GiB" />
          <InfoRow label="Apps & Services" value="7.2 GiB" />
        </SectionCard>
      </ResponsiveRow>
      <SectionHeader title="Storage" />
      <ResponsiveRow>
        <SectionCard title="tank" icon="square_stack_3d_down_right">
          <ResponsiveRow spacing={8} breakpoint={240}>
            <StorageMetricWidget
              label="Used"
              value="3.1TB"
              color="systemBlue"
            />
            <StorageMetricWidget
              label="Available"
              value="7.6TB"
              color="systemGreen"
            />
            <StorageMetricWidget label="Total" value="10.7TB" color="label" />
          </ResponsiveRow>
        </SectionCard>
        <SectionCard
          title="backup"
          icon="square_stack_3d_down_right"
          iconColor="systemOrange"
        >
          <ResponsiveRow spacing={8} breakpoint={240}>
            <StorageMetricWidget label="Used" value="3.4TB" color="systemRed" />
            <StorageMetricWidget
              label="Available"
              value="186.2GB"
              color="systemOrange"
            />
            <StorageMetricWidget label="Total" value="3.6TB" color="label" />
          </ResponsiveRow>
        </SectionCard>
      </ResponsiveRow>
      <SectionHeader title="Services" />
      <ResponsiveRow>
        <SectionCard title="SMB" icon="globe" iconColor="systemTeal">
          <InfoRow label="State" value="Running" valueColor="systemGreen" />
          <InfoRow label="Shares" value="4" />
        </SectionCard>
        <SectionCard title="SSH" icon="lock_shield" iconColor="systemIndigo">
          <InfoRow label="State" value="Stopped" valueColor="systemGrey" />
          <InfoRow label="Port" value="22" />
        </SectionCard>
      </ResponsiveRow>
    </div>
  );
}

function Frame({
  device,
  orientation,
  dark,
  scale,
}: {
  device: DeviceKind;
  orientation: "portrait" | "landscape";
  dark?: boolean;
  scale: number;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <Dashboard />
    </DeviceFrame>
  );
}

export const PhonePortraitStackedLight = () => (
  <Frame device="phone" orientation="portrait" scale={0.6} />
);

export const PhonePortraitStackedDark = () => (
  <Frame device="phone" orientation="portrait" dark scale={0.6} />
);

export const PhoneLandscapeLight = () => (
  <Frame device="phone" orientation="landscape" scale={0.5} />
);

export const PhoneLandscapeDark = () => (
  <Frame device="phone" orientation="landscape" dark scale={0.5} />
);

export const TabletPortraitLight = () => (
  <Frame device="tablet" orientation="portrait" scale={0.4} />
);

export const TabletPortraitDark = () => (
  <Frame device="tablet" orientation="portrait" dark scale={0.4} />
);

export const DesktopLight = () => (
  <Frame device="desktop" orientation="landscape" scale={0.4} />
);

export const DesktopDark = () => (
  <Frame device="desktop" orientation="landscape" dark scale={0.4} />
);
