import {
  AdaptiveNavigationScaffold,
  DeviceFrame,
  ServerFilesScreen,
  type DeviceKind,
  type FileItem,
  type ServerFilesScreenProps,
} from "@truenas-manager/ui";

const now = new Date("2026-10-02T12:00:00Z");
const ago = (hours: number) => new Date(now.getTime() - hours * 3_600_000);

function file(
  dir: string,
  name: string,
  hoursAgo: number,
  size = 0,
  mimeType?: string,
): FileItem {
  return {
    name,
    path: `${dir}/${name}`,
    isDirectory: mimeType == null && size === 0,
    size,
    modifiedTime: ago(hoursAgo),
    mimeType,
  };
}

const tank = "/mnt/tank";
const files: FileItem[] = [
  file(
    tank,
    "media.iso",
    24 * 90,
    4_700_000_000,
    "application/x-iso9660-image",
  ),
  file(tank, "Photos", 5),
  file(tank, "backup.tar.gz", 24 * 3, 1_288_490_188, "application/gzip"),
  file(tank, "Documents", 24 * 12),
  file(tank, "Music", 24 * 400),
  file(tank, "holiday-2025.mp4", 24 * 45, 892_340_224, "video/mp4"),
  file(tank, "cover.jpg", 2, 2_412_544, "image/jpeg"),
  file(tank, "notes.txt", 0.2, 3_180, "text/plain"),
  file(tank, "theme.flac", 24 * 200, 31_457_280, "audio/flac"),
];

const summer = "/mnt/tank/Photos/2026/Summer";
const photos: FileItem[] = [
  file(summer, "IMG_2041.HEIC", 24 * 70, 3_145_728, "image/heic"),
  file(summer, "IMG_2042.HEIC", 24 * 70, 2_936_012, "image/heic"),
  file(summer, "Lake", 24 * 68),
  file(summer, "beach.mov", 24 * 66, 412_090_368, "video/quicktime"),
];

const noop = () => {};

function Shell({
  device = "phone",
  orientation,
  dark,
  scale = 0.6,
  ...props
}: Partial<ServerFilesScreenProps> & {
  device?: DeviceKind;
  orientation?: "portrait" | "landscape";
  dark?: boolean;
  scale?: number;
}) {
  return (
    <DeviceFrame
      device={device}
      orientation={orientation}
      brightness={dark ? "dark" : "light"}
      scale={scale}
    >
      <AdaptiveNavigationScaffold selectedIndex={0}>
        <ServerFilesScreen
          serverName="Basement NAS"
          currentPath={tank}
          files={files}
          now={now}
          onBack={noop}
          onRefresh={noop}
          onSearchChange={noop}
          onNavigate={noop}
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
export const NestedPath = () => (
  <Shell dark currentPath={summer} files={photos} />
);
export const SearchNoMatches = () => <Shell searchQuery="invoice" />;
export const EmptyFolder = () => (
  <Shell dark currentPath="/mnt/tank/Documents" files={[]} />
);
export const Loading = () => <Shell loading />;
export const LoadFailed = () => (
  <Shell dark error="filesystem.listdir: [EACCES] Permission denied" />
);
