import { resolveColor, withAlpha } from "../colors";
import { AppCardWidget, type TrueNASApp } from "../components/AppCardWidget";
import { ShellBackButton } from "../components/Navigation";
import {
  EmptyStateWidget,
  ErrorStateWidget,
  LoadingStateWidget,
  type ConnectionError,
} from "../components/States";
import { JobsBellButton } from "../components/Status";
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
import { CupertinoSegmentedControl } from "./internal/CupertinoSegmentedControl";

export type AppsSegment = "installed" | "available" | "favorites" | "updates";

export type CatalogError = Pick<
  ConnectionError,
  "shortMessage" | "technicalDetails"
>;

export interface ServerAppsScreenProps {
  /**
   * The apps to list for the selected segment, already filtered by
   * `searchQuery` and sorted - the screen renders them in order.
   */
  apps: TrueNASApp[];
  /** Defaults to `installed`. */
  segment?: AppsSegment;
  searchQuery?: string;
  /** Highlights the "Sort by Name" chip. Defaults to true. */
  sortByName?: boolean;
  /** The app list is loading: replaces the list with a spinner. */
  loading?: boolean;
  /** Loading the app list failed: replaces the list with an error and Retry. */
  error?: { message: string; details?: string };
  /** The Available catalog is still syncing (only shown on `available` with no apps). */
  catalogLoading?: boolean;
  /**
   * The catalog refresh failed. On `available` it shows as a full error when
   * there are no apps (and no search), otherwise as a yellow stale-catalog
   * notice above the list.
   */
  catalogError?: CatalogError;
  /** Jobs bell badge in the nav bar. */
  runningJobsCount?: number;
  /** Jobs bell red dot. */
  jobsNeedAttention?: boolean;
  onBack?: () => void;
  onJobsClick?: () => void;
  onRefresh?: () => void;
  onSegmentChange?: (segment: AppsSegment) => void;
  onSearchChange?: (query: string) => void;
  onToggleSort?: () => void;
  onAppClick?: (app: TrueNASApp) => void;
  onToggleFavorite?: (app: TrueNASApp) => void;
  onUpgrade?: (app: TrueNASApp) => void;
}

const EMPTY: Record<
  AppsSegment,
  { title: string; subtitle: string; icon: CupertinoIconName }
> = {
  installed: {
    title: "No installed apps",
    subtitle: "Install apps from the Available tab to see them here.",
    icon: "app_badge",
  },
  available: {
    title: "No available apps",
    subtitle: "Check your connection and try refreshing.",
    icon: "app",
  },
  favorites: {
    title: "No favorite apps",
    subtitle: "Mark apps as favorites to see them here.",
    icon: "heart",
  },
  updates: {
    title: "No updates available",
    subtitle: "All your apps are up to date!",
    icon: "arrow_up_circle",
  },
};

/**
 * The server's Apps screen: a search field, an Installed / Available /
 * Favorites / Updates segmented control, a sort chip, and the matching
 * `AppCardWidget` list. Reached from a server's detail screen.
 */
export function ServerAppsScreen({
  apps,
  segment = "installed",
  searchQuery = "",
  sortByName = true,
  loading = false,
  error,
  catalogLoading = false,
  catalogError,
  runningJobsCount,
  jobsNeedAttention,
  onBack,
  onJobsClick,
  onRefresh,
  onSegmentChange,
  onSearchChange,
  onToggleSort,
  onAppClick,
  onToggleFavorite,
  onUpgrade,
}: ServerAppsScreenProps) {
  const sortTint = sortByName ? "white" : "systemGrey";
  return (
    <CupertinoPageScaffold
      navigationBar={
        <CupertinoNavigationBar
          middle="Apps"
          leading={<ShellBackButton onClick={onBack} />}
          trailing={
            <>
              <JobsBellButton
                runningCount={runningJobsCount}
                needsAttention={jobsNeedAttention}
                onClick={onJobsClick}
              />
              <CupertinoButton padding={0} minSize={0} onClick={onRefresh}>
                <CupertinoIcon icon="refresh" />
              </CupertinoButton>
            </>
          }
        />
      }
    >
      <div style={{ margin: 16 }}>
        <CupertinoSearchTextField
          placeholder="Search apps..."
          value={searchQuery}
          onChange={onSearchChange}
        />
      </div>
      <div style={{ margin: "0 16px" }}>
        <CupertinoSegmentedControl
          groupValue={segment}
          onValueChanged={onSegmentChange}
          segments={[
            { value: "installed", label: "Installed" },
            { value: "available", label: "Available" },
            { value: "favorites", label: "Favorites" },
            { value: "updates", label: "Updates" },
          ]}
        />
      </div>
      <div style={{ margin: "8px 16px", display: "flex" }}>
        <CupertinoButton
          variant="filled"
          size="small"
          padding="6px 12px"
          color={sortByName ? "systemBlue" : "systemGrey4"}
          onClick={onToggleSort}
          style={{ gap: 4, fontSize: 14, color: resolveColor(sortTint) }}
        >
          <CupertinoIcon icon="sort_down" size={16} color={sortTint} />
          Sort by Name
        </CupertinoButton>
      </div>
      <div style={{ height: 16 }} />
      <AppsBody
        apps={apps}
        segment={segment}
        searchQuery={searchQuery}
        loading={loading}
        error={error}
        catalogLoading={catalogLoading}
        catalogError={segment === "available" ? catalogError : undefined}
        onRetry={onRefresh}
        onAppClick={onAppClick}
        onToggleFavorite={onToggleFavorite}
        onUpgrade={onUpgrade}
      />
    </CupertinoPageScaffold>
  );
}

function AppsBody({
  apps,
  segment,
  searchQuery,
  loading,
  error,
  catalogLoading,
  catalogError,
  onRetry,
  onAppClick,
  onToggleFavorite,
  onUpgrade,
}: Required<
  Pick<
    ServerAppsScreenProps,
    "apps" | "segment" | "searchQuery" | "loading" | "catalogLoading"
  >
> &
  Pick<
    ServerAppsScreenProps,
    "error" | "catalogError" | "onAppClick" | "onToggleFavorite" | "onUpgrade"
  > & { onRetry?: () => void }) {
  if (loading) return <LoadingStateWidget message="Loading apps..." />;
  if (error) {
    return (
      <ErrorView
        title="Failed to load apps"
        error={error.message}
        details={error.details}
        onRetry={onRetry}
      />
    );
  }
  if (apps.length === 0) {
    if (segment === "available" && catalogLoading) {
      return <LoadingStateWidget message="Loading app catalog..." />;
    }
    // A search that matches nothing is still a search result, even when the
    // catalog it searched is stale.
    if (catalogError && searchQuery === "") {
      return (
        <ErrorView
          title="Failed to load app catalog"
          error={catalogError.shortMessage}
          details={catalogError.technicalDetails}
          onRetry={onRetry}
        />
      );
    }
    const empty = EMPTY[segment];
    return (
      <EmptyStateWidget
        icon={empty.icon}
        title={empty.title}
        message={searchQuery ? "No apps match your search" : empty.subtitle}
      />
    );
  }
  return (
    <div style={{ padding: "0 16px" }}>
      {catalogError && <CatalogNotice error={catalogError} />}
      {apps.map((app, i) => (
        <div key={`${app.name}-${i}`} style={{ paddingBottom: 12 }}>
          <AppCardWidget
            app={app}
            onClick={onAppClick && (() => onAppClick(app))}
            onToggleFavorite={onToggleFavorite && (() => onToggleFavorite(app))}
            onUpgrade={onUpgrade && (() => onUpgrade(app))}
          />
        </div>
      ))}
    </div>
  );
}

function ErrorView({
  title,
  error,
  details,
  onRetry,
}: {
  title: string;
  error: string;
  details?: string;
  onRetry?: () => void;
}) {
  return (
    <div style={{ whiteSpace: "pre-line" }}>
      <ErrorStateWidget
        title={title}
        message={details == null ? error : `${error}\n${details}`}
        onRetry={onRetry}
      />
    </div>
  );
}

/**
 * Shown above a stale catalog list when the catalog could not be refreshed
 * this time, so the user knows the entries may be outdated without losing them.
 */
function CatalogNotice({ error }: { error: CatalogError }) {
  return (
    <div style={{ paddingBottom: 12 }}>
      <div
        style={{
          padding: 12,
          borderRadius: 10,
          background: withAlpha("systemYellow", 0.15),
          fontSize: 13,
        }}
      >
        Catalog could not be refreshed: {error.shortMessage}. Showing the last
        synced apps.
      </div>
    </div>
  );
}
