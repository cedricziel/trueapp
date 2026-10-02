/// One row of the tray's context menu.
class TrayMenuEntry {
  const TrayMenuEntry({
    required String this.key,
    required String this.label,
    this.enabled = true,
    this.children = const [],
  });

  const TrayMenuEntry.separator()
    : key = null,
      label = null,
      enabled = false,
      children = const [];

  final String? key;
  final String? label;
  final bool enabled;
  final List<TrayMenuEntry> children;

  bool get isSeparator => label == null;
}

/// The system tray icon the app draws into.
abstract interface class TrayHost {
  void setIcon(String assetPath);

  void setTooltip(String tooltip);

  /// Replaces the context menu. [onSelected] receives the key of the clicked
  /// entry.
  void setMenu(
    List<TrayMenuEntry> entries, {
    required void Function(String key) onSelected,
  });

  void dispose();
}
