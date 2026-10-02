export { CupertinoColors, resolveColor, withAlpha } from "./colors";
export type { ColorValue, CupertinoColorName } from "./colors";

export { CupertinoApp } from "./primitives/CupertinoApp";
export type { CupertinoAppProps } from "./primitives/CupertinoApp";
export { CupertinoIcon } from "./primitives/CupertinoIcon";
export type {
  CupertinoIconName,
  CupertinoIconProps,
} from "./primitives/CupertinoIcon";
export { CupertinoButton } from "./primitives/CupertinoButton";
export type {
  CupertinoButtonProps,
  CupertinoButtonSize,
} from "./primitives/CupertinoButton";
export { CupertinoActivityIndicator } from "./primitives/CupertinoActivityIndicator";
export type { CupertinoActivityIndicatorProps } from "./primitives/CupertinoActivityIndicator";
export {
  CupertinoAlertDialog,
  CupertinoDialogAction,
} from "./primitives/CupertinoAlertDialog";
export type {
  CupertinoAlertDialogProps,
  CupertinoDialogActionProps,
} from "./primitives/CupertinoAlertDialog";
export { CupertinoNavigationBar } from "./primitives/CupertinoNavigationBar";
export type { CupertinoNavigationBarProps } from "./primitives/CupertinoNavigationBar";

export { SectionCard, InfoRow, StatusPill } from "./components/SectionCard";
export type {
  SectionCardProps,
  InfoRowProps,
  StatusPillProps,
} from "./components/SectionCard";
export {
  SectionHeader,
  FormRowLabel,
  ResponsiveRow,
} from "./components/Layout";
export type {
  SectionHeaderProps,
  FormRowLabelProps,
  ResponsiveRowProps,
} from "./components/Layout";
export {
  UsageBar,
  StorageMetricWidget,
  TrendSparkline,
  MemorySegmentedBar,
} from "./components/Metrics";
export type {
  UsageBarProps,
  StorageMetricWidgetProps,
  TrendSparklineProps,
  MemoryStats,
  MemorySegmentedBarProps,
} from "./components/Metrics";
export {
  LoadingStateWidget,
  EmptyStateWidget,
  ErrorStateWidget,
  ConnectionErrorWidget,
  CompactConnectionErrorWidget,
  AuthenticationStateWidget,
} from "./components/States";
export type {
  LoadingStateWidgetProps,
  EmptyStateWidgetProps,
  ErrorStateWidgetProps,
  ConnectionError,
  ConnectionErrorType,
  ConnectionErrorWidgetProps,
  CompactConnectionErrorWidgetProps,
  AuthenticationState,
  AuthenticationStateWidgetProps,
} from "./components/States";
export {
  AppLogo,
  ConnectionStatusWidget,
  ConnectionStatusTitleWidget,
  JobsBellButton,
  SessionIndicatorWidget,
} from "./components/Status";
export type {
  AppLogoProps,
  TrueNASConnectionState,
  ConnectionStatusWidgetProps,
  ConnectionStatusTitleWidgetProps,
  JobsBellButtonProps,
  SessionIndicatorWidgetProps,
} from "./components/Status";
export { PoolCardWidget } from "./components/PoolCardWidget";
export type { Pool, PoolCardWidgetProps } from "./components/PoolCardWidget";
export { AppIcon, AppCardWidget } from "./components/AppCardWidget";
export type {
  TrueNASApp,
  AppPort,
  AppResourceUsage,
  AppIconProps,
  AppCardWidgetProps,
} from "./components/AppCardWidget";
export { JobCardWidget } from "./components/JobCardWidget";
export type {
  Job,
  JobState,
  JobCardWidgetProps,
} from "./components/JobCardWidget";
export { ServerListTile } from "./components/ServerListTile";
export type {
  NasServer,
  FleetServerConnectivity,
  FleetServerStatus,
  ServerListTileProps,
} from "./components/ServerListTile";
export {
  CpuStatsCard,
  MemoryStatsCard,
  DiskStatsCard,
  NetworkStatsCard,
  SystemStatsWidget,
} from "./components/SystemStats";
export type {
  CpuStatsCardProps,
  MemoryStatsCardProps,
  DiskStats,
  NetworkInterfaceStats,
  SystemStatsWidgetProps,
} from "./components/SystemStats";
export {
  APP_DESTINATIONS,
  NAVIGATION_BREAKPOINT,
  CupertinoTabBar,
  CupertinoSidebar,
  AdaptiveNavigationScaffold,
  ShellBackButton,
  DeviceFrame,
} from "./components/Navigation";
export type {
  NavigationDestination,
  CupertinoTabBarProps,
  CupertinoSidebarProps,
  AdaptiveNavigationScaffoldProps,
  ShellBackButtonProps,
  DeviceKind,
  DeviceFrameProps,
} from "./components/Navigation";
export {
  CupertinoPageScaffold,
  CupertinoFormSection,
  CupertinoFormRow,
  CupertinoTextFormFieldRow,
  CupertinoTextField,
  CupertinoSearchTextField,
  CupertinoSwitch,
  CupertinoActionSheet,
  CupertinoActionSheetAction,
} from "./primitives/Forms";
export type {
  CupertinoPageScaffoldProps,
  CupertinoFormSectionProps,
  CupertinoFormRowProps,
  CupertinoTextFormFieldRowProps,
  CupertinoTextFieldProps,
  CupertinoSearchTextFieldProps,
  CupertinoSwitchProps,
  CupertinoActionSheetProps,
  CupertinoActionSheetActionProps,
} from "./primitives/Forms";
export * from "./screens/HomeScreen";
export * from "./screens/SettingsScreen";
export * from "./screens/AddServerScreen";
export * from "./screens/EditServerScreen";
export * from "./screens/ServerDetailScreen";
export * from "./screens/ServerHealthScreen";
export * from "./screens/UserProfileScreen";
export * from "./screens/ServerPoolsScreen";
export * from "./screens/PoolDetailScreen";
export * from "./screens/DatasetDetailScreen";
export * from "./screens/ServerFilesScreen";
export * from "./screens/ServerAppsScreen";
export * from "./screens/AppDetailScreen";
export * from "./screens/AppConfigurationScreen";
export * from "./screens/ServerJobsScreen";
