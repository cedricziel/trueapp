import {
  CupertinoApp,
  InfoRow,
  SectionCard,
  SectionHeader,
} from "@truenas-manager/ui";

function ServerSummary() {
  return (
    <>
      <div style={{ fontSize: 28, fontWeight: 700, marginBottom: 4 }}>
        Basement NAS
      </div>
      <div
        style={{
          fontSize: 15,
          color: "var(--cupertino-secondary-label)",
          marginBottom: 16,
        }}
      >
        https://nas.local · TrueNAS SCALE 25.04
      </div>
      <SectionCard title="Storage" icon="square_stack_3d_down_right">
        <InfoRow label="Pool" value="tank" />
        <InfoRow label="Status" value="ONLINE" valueColor="systemGreen" />
      </SectionCard>
    </>
  );
}

function SettingsGroup() {
  return (
    <>
      <SectionHeader title="Settings" />
      <SectionCard title="Appearance" icon="settings">
        <InfoRow label="Theme" value="System" />
        <InfoRow label="Refresh interval" value="30 s" />
      </SectionCard>
    </>
  );
}

export const SystemBackgroundLight = () => (
  <CupertinoApp brightness="light" style={{ padding: 16, width: 360 }}>
    <ServerSummary />
  </CupertinoApp>
);

export const SystemBackgroundDark = () => (
  <CupertinoApp brightness="dark" style={{ padding: 16, width: 360 }}>
    <ServerSummary />
  </CupertinoApp>
);

export const GroupedBackgroundLight = () => (
  <CupertinoApp
    brightness="light"
    background="systemGroupedBackground"
    style={{ padding: 16, width: 360 }}
  >
    <SettingsGroup />
  </CupertinoApp>
);

export const GroupedBackgroundDark = () => (
  <CupertinoApp
    brightness="dark"
    background="systemGroupedBackground"
    style={{ padding: 16, width: 360 }}
  >
    <SettingsGroup />
  </CupertinoApp>
);
