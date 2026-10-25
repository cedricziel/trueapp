import { CupertinoButton } from "../primitives/CupertinoButton";
import { CupertinoNavigationBar } from "../primitives/CupertinoNavigationBar";
import { CupertinoPageScaffold } from "../primitives/Forms";
import {
  ServiceActionErrorBanner,
  ServiceTile,
  type ServiceAction,
  type ServiceStatus,
} from "../components/Services";
import {
  ConnectionErrorWidget,
  EmptyStateWidget,
  LoadingStateWidget,
  type ConnectionError,
} from "../components/States";
import { JobsBellButton } from "../components/Status";

export interface ServicesScreenProps {
  serverName: string;
  services?: ServiceStatus[];
  /** Ids of services with a start, stop or restart in flight. */
  busyServiceIds?: string[];
  /** Message of the last failed action; shows the dismissible red banner above the list. */
  actionError?: string;
  /** First load in progress: a spinner with "Loading services..." replaces the list. */
  loading?: boolean;
  /** The load failed: the connection-error view with Try Again / Check Settings replaces the list. */
  connectionError?: ConnectionError;
  /** Opens this service's Start / Stop / Restart action sheet. */
  actionSheetServiceId?: string;
  jobsRunningCount?: number;
  /** A recent job failed: red dot on the bell. */
  jobsNeedAttention?: boolean;
  onBack?: () => void;
  onJobs?: () => void;
  onRetry?: () => void;
  onSettings?: () => void;
  onAction?: (serviceId: string, action: ServiceAction) => void;
  onDismissActionError?: () => void;
  onActionSheetChange?: (serviceId: string | undefined) => void;
}

/**
 * The server's Services screen: one `ServiceTile` per TrueNAS service, with
 * start / stop / restart from each tile's action sheet. A failed action
 * shows a `ServiceActionErrorBanner` above the list.
 */
export function ServicesScreen({
  serverName,
  services = [],
  busyServiceIds = [],
  actionError,
  loading = false,
  connectionError,
  actionSheetServiceId,
  jobsRunningCount = 0,
  jobsNeedAttention = false,
  onBack,
  onJobs,
  onRetry,
  onSettings,
  onAction,
  onDismissActionError,
  onActionSheetChange,
}: ServicesScreenProps) {
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle={`${serverName} - Services`}
          leading={
            <CupertinoButton padding={0} minSize={0} onClick={onBack}>
              Back
            </CupertinoButton>
          }
          trailing={
            <JobsBellButton
              runningCount={jobsRunningCount}
              needsAttention={jobsNeedAttention}
              onClick={onJobs}
            />
          }
        />
      }
    >
      {loading && connectionError == null ? (
        <LoadingStateWidget message="Loading services..." />
      ) : connectionError != null ? (
        <div
          style={{
            height: "100%",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <ConnectionErrorWidget
            error={connectionError}
            onRetry={onRetry}
            onSettings={onSettings}
          />
        </div>
      ) : services.length === 0 ? (
        <EmptyStateWidget
          icon="gear"
          title="No services found"
          message="Services running on this server will appear here."
        />
      ) : (
        <div style={{ padding: 16 }}>
          {actionError != null && (
            <ServiceActionErrorBanner
              message={actionError}
              onDismiss={onDismissActionError}
            />
          )}
          {services.map((service) => (
            <ServiceTile
              key={service.id}
              service={service}
              isBusy={busyServiceIds.includes(service.id)}
              onAction={(action) => onAction?.(service.id, action)}
              sheetOpen={
                actionSheetServiceId === undefined
                  ? undefined
                  : actionSheetServiceId === service.id
              }
              onSheetOpenChange={(open) =>
                onActionSheetChange?.(open ? service.id : undefined)
              }
            />
          ))}
        </div>
      )}
    </CupertinoPageScaffold>
  );
}
