import 'package:truehub/services/tray/tray_host.dart';
import 'package:truehub/services/tray_service.dart';

/// Records what the app draws into the tray and lets a test click menu
/// entries.
class FakeTrayHost implements TrayHost {
  final icons = <String>[];
  final tooltips = <String>[];
  final menus = <List<TrayMenuEntry>>[];
  bool disposed = false;

  /// Thrown from [setIcon] when set, the way an unloadable asset fails.
  Object? setIconError;

  void Function(String key)? _onSelected;

  List<TrayMenuEntry> get lastMenu => menus.last;

  /// Every entry of [lastMenu], with submenu entries flattened in.
  Iterable<TrayMenuEntry> get lastMenuEntries sync* {
    Iterable<TrayMenuEntry> walk(List<TrayMenuEntry> entries) sync* {
      for (final entry in entries) {
        yield entry;
        yield* walk(entry.children);
      }
    }

    yield* walk(lastMenu);
  }

  void select(String key) => _onSelected!(key);

  @override
  void setIcon(String assetPath) {
    if (setIconError case final error?) throw error;
    icons.add(assetPath);
  }

  @override
  void setTooltip(String tooltip) => tooltips.add(tooltip);

  @override
  void setMenu(
    List<TrayMenuEntry> entries, {
    required void Function(String key) onSelected,
  }) {
    menus.add(entries);
    _onSelected = onSelected;
  }

  @override
  void dispose() => disposed = true;
}

/// A [TrayService] that never touches the native tray.
TrayService fakeTrayService([FakeTrayHost? host]) {
  final tray = host ?? FakeTrayHost();
  return TrayService(createHost: () => tray);
}
