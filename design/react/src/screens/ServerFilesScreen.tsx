import { Fragment } from "react";
import type { ColorValue } from "../colors";
import { CupertinoActivityIndicator } from "../primitives/CupertinoActivityIndicator";
import { CupertinoButton } from "../primitives/CupertinoButton";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import {
  CupertinoPageScaffold,
  CupertinoSearchTextField,
} from "../primitives/Forms";
import { ShellBackButton } from "../components/Navigation";
import { EmptyStateWidget, ErrorStateWidget } from "../components/States";
import { JobsBellButton, type JobsBellButtonProps } from "../components/Status";
import { formatBytes } from "../components/shared";

export interface FileItem {
  name: string;
  /** Absolute path, e.g. "/mnt/tank/media". */
  path: string;
  isDirectory: boolean;
  /** Bytes; ignored for directories. */
  size: number;
  modifiedTime: Date;
  mimeType?: string;
}

export interface ServerFilesScreenProps {
  serverName: string;
  /** The folder being shown, e.g. "/mnt/tank"; "/" is Home. */
  currentPath?: string;
  /** The folder's contents, unfiltered and unsorted - the screen filters by `searchQuery` and sorts folders first. */
  files?: FileItem[];
  searchQuery?: string;
  /** Shows a centered spinner in place of the list. */
  loading?: boolean;
  /** Shows "Could Not Load Files" with this message. */
  error?: string;
  /** Reference time for the "3d ago" captions; defaults to now. */
  now?: Date;
  jobsBell?: JobsBellButtonProps;
  onBack?: () => void;
  onRefresh?: () => void;
  onSearchChange?: (query: string) => void;
  /** Breadcrumb or folder-row taps. */
  onNavigate?: (path: string) => void;
}

/**
 * The server file browser: breadcrumbs, a folder search field, and the
 * folder's contents with folders first. Opened from the server dashboard's
 * Files entry; folder rows drill in, file rows are inert.
 */
export function ServerFilesScreen({
  serverName,
  currentPath = "/",
  files = [],
  searchQuery = "",
  loading = false,
  error,
  now = new Date(),
  jobsBell,
  onBack,
  onRefresh,
  onSearchChange,
  onNavigate,
}: ServerFilesScreenProps) {
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle="Files"
          leading={
            <ShellBackButton previousPageTitle={serverName} onClick={onBack} />
          }
          trailing={
            <>
              <JobsBellButton {...jobsBell} />
              <CupertinoButton padding={0} minSize={0} onClick={onRefresh}>
                <CupertinoIcon icon="refresh" />
              </CupertinoButton>
            </>
          }
        />
      }
    >
      <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
        <Breadcrumbs path={currentPath} onNavigate={onNavigate} />
        <div style={{ margin: "8px 16px" }}>
          <CupertinoSearchTextField
            placeholder="Search this folder"
            value={searchQuery}
            onChange={onSearchChange}
          />
        </div>
        <div style={{ flex: 1, minHeight: 0 }}>
          <FilesBody
            files={files}
            searchQuery={searchQuery}
            loading={loading}
            error={error}
            now={now}
            onRefresh={onRefresh}
            onNavigate={onNavigate}
          />
        </div>
      </div>
    </CupertinoPageScaffold>
  );
}

function Breadcrumbs({
  path,
  onNavigate,
}: {
  path: string;
  onNavigate?: (path: string) => void;
}) {
  const segments = path.split("/").filter((s) => s.length > 0);
  return (
    <div
      style={{
        height: 32,
        flexShrink: 0,
        display: "flex",
        alignItems: "center",
        padding: "0 16px",
        overflowX: "auto",
        whiteSpace: "nowrap",
      }}
    >
      <Breadcrumb
        label="Home"
        isCurrent={segments.length === 0}
        onClick={() => onNavigate?.("/")}
      />
      {segments.map((segment, i) => {
        const target = `/${segments.slice(0, i + 1).join("/")}`;
        return (
          <Fragment key={target}>
            <span style={{ display: "inline-flex", padding: "0 4px" }}>
              <CupertinoIcon
                icon="chevron_right"
                size={12}
                color="tertiaryLabel"
              />
            </span>
            <Breadcrumb
              label={segment}
              isCurrent={i === segments.length - 1}
              onClick={() => onNavigate?.(target)}
            />
          </Fragment>
        );
      })}
    </div>
  );
}

function Breadcrumb({
  label,
  isCurrent,
  onClick,
}: {
  label: string;
  isCurrent: boolean;
  onClick: () => void;
}) {
  return (
    <span
      onClick={isCurrent ? undefined : onClick}
      style={{
        fontSize: 14,
        fontWeight: isCurrent ? 600 : 400,
        color: isCurrent
          ? "var(--cupertino-label)"
          : "var(--cupertino-system-blue)",
        cursor: isCurrent ? undefined : "pointer",
        flexShrink: 0,
      }}
    >
      {label}
    </span>
  );
}

function FilesBody({
  files,
  searchQuery,
  loading,
  error,
  now,
  onRefresh,
  onNavigate,
}: {
  files: FileItem[];
  searchQuery: string;
  loading: boolean;
  error?: string;
  now: Date;
  onRefresh?: () => void;
  onNavigate?: (path: string) => void;
}) {
  if (loading) {
    return (
      <div
        style={{
          height: "100%",
          minHeight: 120,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <CupertinoActivityIndicator />
      </div>
    );
  }

  if (error != null) {
    return (
      <ErrorStateWidget
        title="Could Not Load Files"
        message={error}
        onRetry={onRefresh}
      />
    );
  }

  const query = searchQuery.toLowerCase();
  const filtered =
    query.length === 0
      ? files
      : files.filter((f) => f.name.toLowerCase().includes(query));

  if (filtered.length === 0) {
    return (
      <EmptyStateWidget
        icon="folder"
        title={searchQuery.length === 0 ? "Empty Folder" : "No Matches"}
        message={
          searchQuery.length === 0
            ? "This folder has no files or subfolders"
            : `No files match "${searchQuery}"`
        }
      />
    );
  }

  const sorted = [...filtered].sort((a, b) => {
    if (a.isDirectory !== b.isDirectory) return a.isDirectory ? -1 : 1;
    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
  });

  return (
    <div>
      {sorted.map((file, i) => (
        <Fragment key={file.path}>
          {i > 0 && (
            <div
              style={{
                marginLeft: 56,
                height: 0.5,
                background: "var(--cupertino-separator)",
              }}
            />
          )}
          <FileRow
            file={file}
            now={now}
            onClick={
              file.isDirectory && onNavigate
                ? () => onNavigate(file.path)
                : undefined
            }
          />
        </Fragment>
      ))}
    </div>
  );
}

function FileRow({
  file,
  now,
  onClick,
}: {
  file: FileItem;
  now: Date;
  onClick?: () => void;
}) {
  const { icon, color } = fileIcon(file);
  return (
    <div
      className={onClick ? "cupertino-button" : undefined}
      onClick={onClick}
      style={{
        display: "flex",
        alignItems: "center",
        padding: "10px 16px",
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <CupertinoIcon icon={icon} size={26} color={color} />
      <div style={{ flex: 1, minWidth: 0, marginLeft: 12 }}>
        <div
          style={{
            fontSize: 15,
            fontWeight: 500,
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {file.name}
        </div>
        <div
          style={{
            marginTop: 2,
            fontSize: 12,
            color: "var(--cupertino-system-grey)",
          }}
        >
          {subtitleFor(file, now)}
        </div>
      </div>
      {file.isDirectory && (
        <CupertinoIcon icon="chevron_right" size={16} color="tertiaryLabel" />
      )}
    </div>
  );
}

function subtitleFor(file: FileItem, now: Date): string {
  const modified = formatModified(file.modifiedTime, now);
  if (file.isDirectory) return `Folder · ${modified}`;
  return `${formatBytes(file.size)} · ${modified}`;
}

function formatModified(dateTime: Date, now: Date): string {
  const hours = Math.floor((now.getTime() - dateTime.getTime()) / 3_600_000);
  const days = Math.floor(hours / 24);
  if (days > 365) return `${Math.floor(days / 365)}y ago`;
  if (days > 30) return `${Math.floor(days / 30)}mo ago`;
  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  return "Just now";
}

function fileIcon(file: FileItem): {
  icon: CupertinoIconName;
  color: ColorValue;
} {
  if (file.isDirectory) return { icon: "folder_fill", color: "activeBlue" };
  const mime = file.mimeType ?? "";
  if (mime.startsWith("image/"))
    return { icon: "photo_fill", color: "systemPurple" };
  if (mime.startsWith("video/"))
    return { icon: "film_fill", color: "systemGreen" };
  if (mime.startsWith("audio/"))
    return { icon: "music_note", color: "systemOrange" };
  if (mime.startsWith("text/"))
    return { icon: "doc_text_fill", color: "systemGrey" };
  return { icon: "doc_fill", color: "systemGrey" };
}
