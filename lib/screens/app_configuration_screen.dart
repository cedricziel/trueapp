import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/screens/app_configuration/port_edit_modal.dart';
import 'package:truehub/screens/app_configuration/port_list_row.dart';
import 'package:url_launcher/url_launcher.dart';

class AppConfigurationScreen extends StatefulWidget {
  final AppConfig appConfig;

  const AppConfigurationScreen({super.key, required this.appConfig});

  @override
  State<AppConfigurationScreen> createState() => _AppConfigurationScreenState();
}

class _AppConfigurationScreenState extends State<AppConfigurationScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _primaryUrlController;
  late AppConfig _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.appConfig;
    _displayNameController = TextEditingController(
      text: _currentConfig.displayName ?? _currentConfig.appName,
    );
    _primaryUrlController = TextEditingController(
      text: _currentConfig.primaryPort?.customUrl ?? '',
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _primaryUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Configure ${_currentConfig.appName}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveConfiguration,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAppInfoSection(),
            const SizedBox(height: 24),
            _buildPortsSection(),
            const SizedBox(height: 24),
            _buildAddPortSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return CupertinoFormSection(
      header: const Text('App Information'),
      children: [
        CupertinoFormRow(
          prefix: const Text('Display Name'),
          child: CupertinoTextFormFieldRow(
            controller: _displayNameController,
            placeholder: _currentConfig.appName,
            onChanged: (value) {
              setState(() {
                _currentConfig = _currentConfig.copyWith(
                  displayName: value.isEmpty ? null : value,
                  clearDisplayName: value.isEmpty,
                );
              });
            },
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Enabled'),
          child: CupertinoSwitch(
            value: _currentConfig.isEnabled,
            onChanged: (value) {
              setState(() {
                _currentConfig = _currentConfig.copyWith(isEnabled: value);
              });
            },
          ),
        ),
        CupertinoFormRow(
          prefix: const Text('Primary URL'),
          child: CupertinoTextFormFieldRow(
            controller: _primaryUrlController,
            placeholder: 'https://example.com:8080',
            onChanged: (value) {
              _updatePrimaryCustomUrl(value.isEmpty ? null : value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPortsSection() {
    if (_currentConfig.ports.isEmpty) {
      return CupertinoFormSection(
        header: const Text('Ports'),
        children: [
          CupertinoFormRow(
            child: Center(
              child: Text(
                'No ports configured',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return CupertinoFormSection(
      header: const Text('Ports'),
      children: _currentConfig.ports
          .map(
            (port) => PortListRow(
              port: port,
              onOpen: () => _openUrl(port.effectiveUrl),
              onEdit: () => _editPort(port),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAddPortSection() {
    return CupertinoFormSection(
      children: [
        CupertinoFormRow(
          child: CupertinoButton(
            onPressed: _addNewPort,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.add),
                SizedBox(width: 8),
                Text('Add Port'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _editPort(AppPortConfig port) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => PortEditModal(
        port: port,
        onSave: (updatedPort) => _updatePort(port, updatedPort),
        onDelete: () => _deletePort(port),
        onSetPrimary: () => _setPrimaryPort(port),
      ),
    );
  }

  void _addNewPort() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => PortEditModal(
        port: const AppPortConfig(portNumber: 80),
        onSave: (newPort) => _addPort(newPort),
        isNewPort: true,
      ),
    );
  }

  void _updatePort(AppPortConfig originalPort, AppPortConfig updatedPort) {
    final updatedPorts = _currentConfig.ports.map((port) {
      return port.id == originalPort.id ? updatedPort : port;
    }).toList();

    setState(() {
      _currentConfig = _currentConfig.copyWith(ports: updatedPorts);
    });
  }

  void _addPort(AppPortConfig newPort) {
    setState(() {
      _currentConfig = _currentConfig.copyWith(
        ports: [..._currentConfig.ports, newPort],
      );
    });
  }

  void _deletePort(AppPortConfig port) {
    setState(() {
      _currentConfig = _currentConfig.copyWith(
        ports: _currentConfig.ports.where((p) => p.id != port.id).toList(),
      );
    });
  }

  void _setPrimaryPort(AppPortConfig port) {
    final updatedPorts = _currentConfig.ports.map((p) {
      return p.copyWith(isPrimary: p.id == port.id);
    }).toList();

    setState(() {
      _currentConfig = _currentConfig.copyWith(ports: updatedPorts);
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _updatePrimaryCustomUrl(String? customUrl) {
    setState(() {
      final ports = List<AppPortConfig>.from(_currentConfig.ports);

      if (ports.isEmpty) {
        // Create a new primary port if none exist
        if (customUrl != null) {
          final newPort = AppPortConfig(
            portNumber: 80, // Default port
            protocol: 'http',
            serviceName: 'Web Interface',
            customUrl: customUrl,
            isPrimary: true,
            isEnabled: true,
          );
          ports.add(newPort);
        }
      } else {
        // Find the primary port or use the first one
        var primaryPortIndex = ports.indexWhere((port) => port.isPrimary);
        if (primaryPortIndex == -1) {
          primaryPortIndex = 0;
          // Make the first port primary
          ports[0] = ports[0].copyWith(isPrimary: true);
        }

        // Update the primary port's custom URL
        ports[primaryPortIndex] = ports[primaryPortIndex].copyWith(
          customUrl: customUrl,
          clearCustomUrl: customUrl == null,
        );
      }

      _currentConfig = _currentConfig.copyWith(ports: ports);
    });
  }

  Future<void> _saveConfiguration() async {
    final provider = context.read<AppProvider>();

    // AppProvider handles both config and ports together
    await provider.updateAppConfig(_currentConfig);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
