import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';

class EditServerScreen extends StatefulWidget {
  final NasServer server;

  const EditServerScreen({
    super.key,
    required this.server,
  });

  @override
  State<EditServerScreen> createState() => _EditServerScreenState();
}

class _EditServerScreenState extends State<EditServerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late bool _useHttps;
  bool _isTestingConnection = false;
  String? _connectionTestResult;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server.name);
    _hostController = TextEditingController(text: widget.server.host);
    _portController = TextEditingController(text: widget.server.port.toString());
    _usernameController = TextEditingController(text: widget.server.username);
    _passwordController = TextEditingController(text: widget.server.password);
    _useHttps = widget.server.useHttps;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _nameController.text.isNotEmpty &&
        _hostController.text.isNotEmpty &&
        _portController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _testConnection() async {
    if (!_isValid) return;

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final server = widget.server.copyWith(
      name: _nameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 443,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
    );

    try {
      final isValid = await context.read<ServerProvider>().validateServerCredentials(server);
      setState(() {
        _connectionTestResult = isValid ? 'Connection successful!' : 'Invalid credentials or connection failed';
        _isTestingConnection = false;
      });
    } catch (e) {
      setState(() {
        _connectionTestResult = 'Connection failed: ${e.toString()}';
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_isValid) return;

    final updatedServer = widget.server.copyWith(
      name: _nameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 443,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
    );

    await context.read<ServerProvider>().updateServer(updatedServer);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Server'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isValid ? _saveChanges : null,
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
                  placeholder: '443',
                  prefix: const Text('Port'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
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
                        _portController.text = value ? '443' : '80';
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
                    onPressed: _isValid && !_isTestingConnection ? _testConnection : null,
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
                        color: _connectionTestResult!.startsWith('Connection successful')
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