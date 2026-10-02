import {
  AdaptiveNavigationScaffold,
  DatasetDetailScreen,
  DeviceFrame,
  type DatasetDetails,
  type DeviceKind,
} from "@truenas-manager/ui";

const media: DatasetDetails = {
  name: "tank/media",
  type: "FILESYSTEM",
  pool: "tank",
  mountpoint: "/mnt/tank/media",
  encrypted: false,
  created: "Sat Mar 16 14:02 2024",
  used: "5.1T",
  available: "3.9T",
  usedByDataset: "1.2T",
  usedByChildren: "3.7T",
  usedBySnapshots: "214G",
  compression: "LZ4",
  compressRatio: "1.04x",
  deduplication: "OFF",
  checksum: "ON",
  aclMode: "DISCARD",
  aclType: "POSIX",
  readOnly: "OFF",
  exec: "ON",
  recordSize: "1M",
  copies: "1",
  sync: "STANDARD",
  atime: "OFF",
  caseSensitivity: "SENSITIVE",
};

const vmDisk: DatasetDetails = {
  name: "tank/vm-disk",
  type: "VOLUME",
  pool: "tank",
  encrypted: true,
  created: "Tue Jun 03 09:41 2025",
  used: "120G",
  available: "3.9T",
  usedByDataset: "96.4G",
  usedBySnapshots: "23.6G",
  reservation: "120G",
  compression: "ZSTD",
  compressRatio: "1.31x",
  deduplication: "OFF",
  checksum: "ON",
  readOnly: "OFF",
  encryptionAlgorithm: "AES-256-GCM",
  copies: "1",
  sync: "ALWAYS",
};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  dataset = media,
}: {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
  dataset?: DatasetDetails;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <DatasetDetailScreen dataset={dataset} />
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
export const EncryptedZvol = () => <Shell dark dataset={vmDisk} />;
