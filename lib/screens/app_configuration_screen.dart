import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/app_config.dart';
import 'package:truenas_manager/providers/app_config_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppConfigurationScreen extends StatefulWidget {
  final AppConfig appConfig;

  const AppConfigurationScreen({super.key, required this.appConfig});

  @override
  State<AppConfigurationScreen> createState() => _AppConfigurationScreenState();
}

class _AppConfigurationScreenState extends State<AppConfigurationScreen> {
  late TextEditingController _displayNameController;
  late AppConfig _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.appConfig;
    _displayNameController = TextEditingController(
      text: _currentConfig.displayName ?? _currentConfig.appName,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
          .map((port) => _buildPortRow(port))
          .toList(),
    );
  }

  Widget _buildPortRow(AppPortConfig port) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      port.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      port.effectiveUrl,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (port.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openUrl(port.effectiveUrl),
                child: const Icon(CupertinoIcons.link, size: 20),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _editPort(port),
                child: const Icon(CupertinoIcons.pencil, size: 20),
              ),
            ],
          ),
        ],
      ),
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
      builder: (context) => _PortEditModal(
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
      builder: (context) => _PortEditModal(
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

  Future<void> _saveConfiguration() async {
    final provider = context.read<AppConfigProvider>();

    await provider.updateAppConfig(_currentConfig);

    for (final port in _currentConfig.ports) {
      if (port.id != null) {
        await provider.updatePortConfig(_currentConfig.id!, port);
      } else {
        await provider.addPortConfig(_currentConfig.id!, port);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PortEditModal extends StatefulWidget {
  final AppPortConfig port;
  final Function(AppPortConfig) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;
  final bool isNewPort;

  const _PortEditModal({
    required this.port,
    required this.onSave,
    this.onDelete,
    this.onSetPrimary,
    this.isNewPort = false,
  });

  @override
  State<_PortEditModal> createState() => _PortEditModalState();
}

class _PortEditModalState extends State<_PortEditModal> {
  late TextEditingController _portController;
  late TextEditingController _serviceNameController;
  late TextEditingController _customUrlController;
  late String _protocol;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(
      text: widget.port.portNumber.toString(),
    );
    _serviceNameController = TextEditingController(
      text: widget.port.serviceName ?? '',
    );
    _customUrlController = TextEditingController(
      text: widget.port.customUrl ?? '',
    );
    _protocol = widget.port.protocol;
    _isEnabled = widget.port.isEnabled;
  }

  @override
  void dispose() {
    _portController.dispose();
    _serviceNameController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        middle: Text(widget.isNewPort ? 'Add Port' : 'Edit Port'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _savePort,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CupertinoFormSection(
              children: [
                CupertinoFormRow(
                  prefix: const Text('Port'),
                  child: CupertinoTextFormFieldRow(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Protocol'),
                  child: CupertinoSegmentedControl<String>(
                    groupValue: _protocol,
                    onValueChanged: (value) {
                      setState(() {
                        _protocol = value;
                      });
                    },
                    children: const {
                      'http': Text('HTTP'),
                      'https': Text('HTTPS'),
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Service Name'),
                  child: CupertinoTextFormFieldRow(
                    controller: _serviceNameController,
                    placeholder: 'e.g., Web UI, API',
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Custom URL'),
                  child: CupertinoTextFormFieldRow(
                    controller: _customUrlController,
                    placeholder: 'Leave empty for default',
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Enabled'),
                  child: CupertinoSwitch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (!widget.isNewPort) ...[
              const SizedBox(height: 24),
              CupertinoFormSection(
                children: [
                  if (widget.onSetPrimary != null)
                    CupertinoFormRow(
                      child: CupertinoButton(
                        onPressed: () {
                          widget.onSetPrimary!();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Set as Primary'),
                      ),
                    ),
                  if (widget.onDelete != null)
                    CupertinoFormRow(
                      child: CupertinoButton(
                        onPressed: () {
                          widget.onDelete?.call();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Delete Port',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _savePort() {
    final portNumber = int.tryParse(_portController.text);
    if (portNumber == null) return;

    final updatedPort = widget.port.copyWith(
      portNumber: portNumber,
      protocol: _protocol,
      serviceName: _serviceNameController.text.isEmpty
          ? null
          : _serviceNameController.text,
      customUrl: _customUrlController.text.isEmpty
          ? null
          : _customUrlController.text,
      isEnabled: _isEnabled,
    );

    widget.onSave(updatedPort);
    Navigator.of(context).pop();
  }
}
