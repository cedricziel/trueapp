import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:truehub/services/tray/tray_host.dart';

class NativeTrayHost implements TrayHost {
  NativeTrayHost._(this._icon) {
    if (Platform.isMacOS) {
      _icon.setContextMenuTrigger(ContextMenuTrigger.clicked);
      _icon.addListener((event) {
        if (event is TrayIconRightClickedEvent) _icon.openContextMenu();
      });
    } else {
      _icon.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
    }
    _icon.setVisible(true);
  }

  /// Returns null when the platform cannot create a tray icon.
  static NativeTrayHost? create() {
    final icon = TrayIcon.create();
    return icon == null ? null : NativeTrayHost._(icon);
  }

  final TrayIcon _icon;

  // Held so the attached menu and its click listeners stay reachable.
  // ignore: unused_field
  Menu? _menu;

  @override
  void setIcon(String assetPath) {
    final image = ImageAsset.fromAsset(assetPath);
    if (image == null) {
      throw ArgumentError.value(assetPath, 'assetPath', 'cannot be loaded');
    }
    _icon.icon = image;
  }

  @override
  void setTooltip(String tooltip) => _icon.setTooltip(tooltip);

  @override
  void setMenu(
    List<TrayMenuEntry> entries, {
    required void Function(String key) onSelected,
  }) {
    final menu = _buildMenu(entries, onSelected);
    _icon.setContextMenu(menu);
    _menu = menu;
  }

  Menu _buildMenu(
    List<TrayMenuEntry> entries,
    void Function(String key) onSelected,
  ) {
    final menu = Menu.create();
    if (menu == null) throw StateError('Could not create a tray menu');

    for (final entry in entries) {
      if (entry.isSeparator) {
        menu.addSeparator();
        continue;
      }

      final item = MenuItem.createWithLabelAndType(
        entry.label!,
        entry.children.isEmpty ? MenuItemType.normal : MenuItemType.submenu,
      );
      if (item == null) throw StateError('Could not create a tray menu item');

      item.isEnabled = entry.enabled;
      if (entry.children.isNotEmpty) {
        item.submenu = _buildMenu(entry.children, onSelected);
      }
      final key = entry.key!;
      item.addListener((event) {
        if (event is MenuItemClickedEvent) onSelected(key);
      });
      menu.addItem(item);
    }
    return menu;
  }

  @override
  void dispose() => _icon.dispose();
}
