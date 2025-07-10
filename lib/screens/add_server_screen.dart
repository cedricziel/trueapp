import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  final _localUrlController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _wifiSsidController = TextEditingController();
  bool _useHttps = true;
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  final List<String> _trustedWifiSsids = [];

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _localUrlController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _wifiSsidController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _nameController.text.isNotEmpty &&
        _hostController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  void _addWifiSsid() {
    final ssid = _wifiSsidController.text.trim();
    if (ssid.isNotEmpty && !_trustedWifiSsids.contains(ssid)) {
      setState(() {
        _trustedWifiSsids.add(ssid);
        _wifiSsidController.clear();
      });
    }
  }

  void _removeWifiSsid(String ssid) {
    setState(() {
      _trustedWifiSsids.remove(ssid);
    });
  }

  Future<void> _testConnection() async {
    if (!_isValid) return;

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final server = NasServer.create(
      name: _nameController.text,
      host: _hostController.text,
      localUrl: _localUrlController.text.isNotEmpty
          ? _localUrlController.text
          : null,
      trustedWifiSsids: _trustedWifiSsids,
      port: _portController.text.isNotEmpty
          ? int.tryParse(_portController.text)
          : null,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
    );

    try {
      final isValid = await context
          .read<ServerProvider>()
          .validateServerCredentials(server);
      setState(() {
        _connectionTestResult = isValid
            ? 'Connection successful!'
            : 'Invalid credentials or connection failed';
        _isTestingConnection = false;
      });
    } catch (e) {
      setState(() {
        _connectionTestResult = 'Connection failed: ${e.toString()}';
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveServer() async {
    if (!_isValid) return;

    final server = NasServer.create(
      name: _nameController.text,
      host: _hostController.text,
      localUrl: _localUrlController.text.isNotEmpty
          ? _localUrlController.text
          : null,
      trustedWifiSsids: _trustedWifiSsids,
      port: _portController.text.isNotEmpty
          ? int.tryParse(_portController.text)
          : null,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
    );

    await context.read<ServerProvider>().addServer(server);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Server'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isValid ? _saveServer : null,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CupertinoFormSection(
              header: const Text('SERVER DETAILS'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _nameController,
                  placeholder: 'My TrueNAS Server',
                  prefix: const Text('Name'),
                  onChanged: (_) => setState(() {}),
                ),
                CupertinoTextFormFieldRow(
                  controller: _hostController,
                  placeholder: '192.168.1.100',
                  prefix: const Text('Host'),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
                CupertinoTextFormFieldRow(
                  controller: _portController,
                  placeholder: 'Default port (443 for HTTPS, 80 for HTTP)',
                  prefix: const Text('Port'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection(
              header: const Text('LOCAL NETWORK (OPTIONAL)'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _localUrlController,
                  placeholder: 'http://192.168.1.100:80',
                  prefix: const Text('Local URL'),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection(
              header: const Text('TRUSTED WI-FI NETWORKS'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Add SSID'),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _wifiSsidController,
                          placeholder: 'Wi-Fi network name',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _addWifiSsid,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                ..._trustedWifiSsids.map(
                  (ssid) => CupertinoFormRow(
                    prefix: Text(ssid),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _removeWifiSsid(ssid),
                      child: const Text('Remove'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection(
              header: const Text('AUTHENTICATION'),
              children: [
                CupertinoTextFormFieldRow(
                  controller: _usernameController,
                  placeholder: 'admin',
                  prefix: const Text('Username'),
                  onChanged: (_) => setState(() {}),
                ),
                CupertinoTextFormFieldRow(
                  controller: _passwordController,
                  placeholder: 'Password',
                  prefix: const Text('Password'),
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection(
              children: [
                CupertinoFormRow(
                  prefix: const Text('Use HTTPS'),
                  child: CupertinoSwitch(
                    value: _useHttps,
                    onChanged: (value) {
                      setState(() {
                        _useHttps = value;
                        // Clear port to use default
                        _portController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoFormSection(
              header: const Text('CONNECTION TEST'),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Test Connection'),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: _isValid && !_isTestingConnection
                        ? _testConnection
                        : null,
                    child: _isTestingConnection
                        ? const CupertinoActivityIndicator()
                        : const Text('Test'),
                  ),
                ),
                if (_connectionTestResult != null)
                  CupertinoFormRow(
                    prefix: const Text('Result'),
                    child: Text(
                      _connectionTestResult!,
                      style: TextStyle(
                        color:
                            _connectionTestResult!.startsWith(
                              'Connection successful',
                            )
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
