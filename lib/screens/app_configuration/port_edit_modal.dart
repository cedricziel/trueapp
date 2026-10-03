import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:truehub/models/app_config.dart';

class PortEditModal extends StatefulWidget {
  final AppPortConfig port;
  final Function(AppPortConfig) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;
  final bool isNewPort;

  const PortEditModal({
    super.key,
    required this.port,
    required this.onSave,
    this.onDelete,
    this.onSetPrimary,
    this.isNewPort = false,
  });

  @override
  State<PortEditModal> createState() => PortEditModalState();
}

class PortEditModalState extends State<PortEditModal> {
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
      clearServiceName: _serviceNameController.text.isEmpty,
      customUrl: _customUrlController.text.isEmpty
          ? null
          : _customUrlController.text,
      clearCustomUrl: _customUrlController.text.isEmpty,
      isEnabled: _isEnabled,
    );

    widget.onSave(updatedPort);
    Navigator.of(context).pop();
  }
}
