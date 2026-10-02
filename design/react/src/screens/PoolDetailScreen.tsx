import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoIcon } from "../primitives/CupertinoIcon";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { InfoRow, SectionCard } from "../components/SectionCard";
import {
  EmptyStateWidget,
  ErrorStateWidget,
  LoadingStateWidget,
} from "../components/States";
import { JobsBellButton, type JobsBellButtonProps } from "../components/Status";

export interface PoolDetailPool {
  name: string;
  /** ZFS status, e.g. "ONLINE". */
  status: string;
  healthy: boolean;
  topologyDescription: string;
}

export interface DatasetListItem {
  /** Full ZFS path, e.g. "tank/media/photos"; its depth sets the indent. */
  name: string;
  /** "FILESYSTEM" (folder icon) or "VOLUME" (cube icon). Defaults to "FILESYSTEM". */
  type?: string;
  mountpoint?: string;
  /** Pre-formatted, e.g. "1.2T". Defaults to "0B". */
  used?: string;
  /** Pre-formatted, e.g. "3.4T". Defaults to "0B". */
  available?: string;
}

export interface PoolDetailScreenProps {
  pool: PoolDetailPool;
  /** The datasets of this pool only, in ZFS path order. */
  datasets?: DatasetListItem[];
  /** Shows "Loading datasets..." under the Datasets header. */
  loading?: boolean;
  /** Shows "Error loading datasets" with this message. */
  error?: string;
  jobsBell?: JobsBellButtonProps;
  onBack?: () => void;
  onRetry?: () => void;
  onDatasetClick?: (dataset: DatasetListItem) => void;
}

/**
 * A storage pool's detail page: a Pool Information card followed by the
 * pool's datasets as an indented tree. Pushed from `ServerPoolsScreen`;
 * tapping a dataset opens `DatasetDetailScreen`.
 */
export function PoolDetailScreen({
  pool,
  datasets = [],
  loading = false,
  error,
  jobsBell,
  onBack,
  onRetry,
  onDatasetClick,
}: PoolDetailScreenProps) {
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={pool.name}
          leading={
            <CupertinoButton padding={0} minSize={0} onClick={onBack}>
              Back
            </CupertinoButton>
          }
          trailing={<JobsBellButton {...jobsBell} />}
        />
      }
    >
      <div style={{ margin: 16 }}>
        <SectionCard
          title="Pool Information"
          icon="square_stack_3d_down_right"
          iconColor={pool.healthy ? "systemGreen" : "systemRed"}
        >
          <InfoRow label="Status" value={pool.status} />
          <InfoRow
            label="Health"
            value={pool.healthy ? "Healthy" : "Degraded"}
          />
          <InfoRow label="Configuration" value={pool.topologyDescription} />
        </SectionCard>
      </div>
      <div
        style={{
          padding: "0 16px 8px",
          fontSize: 20,
          fontWeight: 600,
        }}
      >
        Datasets
      </div>
      {loading ? (
        <LoadingStateWidget message="Loading datasets..." />
      ) : error != null ? (
        <ErrorStateWidget
          title="Error loading datasets"
          message={error}
          onRetry={onRetry}
        />
      ) : datasets.length === 0 ? (
        <EmptyStateWidget
          icon="folder"
          title="No datasets found"
          message="Datasets created in this pool will appear here."
        />
      ) : (
        datasets.map((dataset) => (
          <DatasetTile
            key={dataset.name}
            dataset={dataset}
            onClick={onDatasetClick && (() => onDatasetClick(dataset))}
          />
        ))
      )}
    </CupertinoPageScaffold>
  );
}

function DatasetTile({
  dataset,
  onClick,
}: {
  dataset: DatasetListItem;
  onClick?: () => void;
}) {
  const pathParts = dataset.name.split("/");
  const indentWidth = (pathParts.length - 1) * 20;
  const type = dataset.type ?? "FILESYSTEM";
  return (
    <div
      className="cupertino-button"
      onClick={onClick}
      style={{
        margin: "0 16px 8px",
        padding: `12px 16px 12px ${16 + indentWidth}px`,
        display: "flex",
        alignItems: "center",
        background: "var(--cupertino-system-background)",
        borderRadius: 8,
        border: "0.5px solid var(--cupertino-separator)",
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <CupertinoIcon
        icon={type === "FILESYSTEM" ? "folder" : "cube"}
        color="activeBlue"
        size={20}
      />
      <div style={{ flex: 1, minWidth: 0, marginLeft: 12 }}>
        <div
          style={{
            fontSize: 14,
            fontWeight: 500,
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}
        >
          {pathParts[pathParts.length - 1]}
        </div>
        {dataset.mountpoint && (
          <div
            style={{
              marginTop: 2,
              fontSize: 12,
              color: "var(--cupertino-system-grey)",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {dataset.mountpoint}
          </div>
        )}
      </div>
      <div style={{ textAlign: "right", marginLeft: 8, flexShrink: 0 }}>
        <div style={{ fontSize: 12, fontWeight: 500 }}>
          {dataset.used ?? "0B"}
        </div>
        <div style={{ fontSize: 10, color: "var(--cupertino-system-grey)" }}>
          of {dataset.available ?? "0B"}
        </div>
      </div>
      <div style={{ width: 8, flexShrink: 0 }} />
      <CupertinoIcon icon="chevron_right" color="systemGrey3" size={14} />
    </div>
  );
}
