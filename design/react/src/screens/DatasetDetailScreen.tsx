import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import { InfoRow, SectionCard } from "../components/SectionCard";

/**
 * A ZFS dataset's properties as the app reads them from `pool.dataset.query`,
 * flattened to their display strings. An omitted property hides its row
 * (except Name, Type, Pool and Encrypted, which always show).
 */
export interface DatasetDetails {
  /** Full ZFS path, e.g. "tank/media". Defaults to "Unknown". */
  name?: string;
  /** Defaults to "FILESYSTEM". */
  type?: string;
  pool?: string;
  mountpoint?: string;
  encrypted?: boolean;
  created?: string;
  used?: string;
  available?: string;
  usedByDataset?: string;
  usedByChildren?: string;
  usedBySnapshots?: string;
  quota?: string;
  reservation?: string;
  compression?: string;
  compressRatio?: string;
  deduplication?: string;
  checksum?: string;
  aclMode?: string;
  aclType?: string;
  readOnly?: string;
  exec?: string;
  encryptionAlgorithm?: string;
  recordSize?: string;
  copies?: string;
  sync?: string;
  atime?: string;
  caseSensitivity?: string;
}

export interface DatasetDetailScreenProps {
  dataset: DatasetDetails;
  onBack?: () => void;
}

/**
 * A dataset's read-only property inspector: General, Storage, Compression,
 * Security and Advanced sections of label/value rows. Pushed from
 * `PoolDetailScreen` when a dataset is tapped.
 */
export function DatasetDetailScreen({
  dataset: d,
  onBack,
}: DatasetDetailScreenProps) {
  const name = d.name ?? "Unknown Dataset";
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={name.split("/").pop()}
          leading={
            <CupertinoButton padding={0} minSize={0} onClick={onBack}>
              Back
            </CupertinoButton>
          }
        />
      }
    >
      <div
        style={{
          padding: 16,
          display: "flex",
          flexDirection: "column",
          gap: 16,
        }}
      >
        <SectionCard title="General Information" icon="info_circle">
          <InfoRow label="Name" value={d.name ?? "Unknown"} />
          <InfoRow label="Type" value={d.type ?? "FILESYSTEM"} />
          <InfoRow label="Pool" value={d.pool ?? ""} />
          <OptionalRow label="Mount Point" value={d.mountpoint || undefined} />
          <InfoRow label="Encrypted" value={d.encrypted ? "Yes" : "No"} />
          <OptionalRow label="Created" value={d.created} />
        </SectionCard>
        <SectionCard title="Storage Information" icon="chart_pie">
          <OptionalRow label="Used Space" value={d.used} />
          <OptionalRow label="Available Space" value={d.available} />
          <OptionalRow label="Used by Dataset" value={d.usedByDataset} />
          <OptionalRow label="Used by Children" value={d.usedByChildren} />
          <OptionalRow label="Used by Snapshots" value={d.usedBySnapshots} />
          <OptionalRow label="Quota" value={d.quota} />
          <OptionalRow label="Reservation" value={d.reservation} />
        </SectionCard>
        <SectionCard title="Compression & Efficiency" icon="archivebox">
          <OptionalRow label="Compression" value={d.compression} />
          <OptionalRow label="Compression Ratio" value={d.compressRatio} />
          <OptionalRow label="Deduplication" value={d.deduplication} />
          <OptionalRow label="Checksum" value={d.checksum} />
        </SectionCard>
        <SectionCard title="Security & Permissions" icon="lock_shield">
          <OptionalRow label="ACL Mode" value={d.aclMode} />
          <OptionalRow label="ACL Type" value={d.aclType} />
          <OptionalRow label="Read Only" value={d.readOnly} />
          <OptionalRow label="Execute" value={d.exec} />
          <OptionalRow label="Encryption" value={d.encryptionAlgorithm} />
        </SectionCard>
        <SectionCard title="Advanced Properties" icon="gear">
          <OptionalRow label="Record Size" value={d.recordSize} />
          <OptionalRow label="Copies" value={d.copies} />
          <OptionalRow label="Sync" value={d.sync} />
          <OptionalRow label="Access Time" value={d.atime} />
          <OptionalRow label="Case Sensitivity" value={d.caseSensitivity} />
        </SectionCard>
      </div>
    </CupertinoPageScaffold>
  );
}

function OptionalRow({ label, value }: { label: string; value?: string }) {
  return value == null ? null : <InfoRow label={label} value={value} />;
}
