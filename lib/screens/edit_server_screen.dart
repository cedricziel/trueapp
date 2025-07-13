import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/network_service.dart';
import 'package:truehub/services/unified_server_service.dart';

class EditServerScreen extends StatefulWidget {
  final NasServer server;

  const EditServerScreen({super.key, required this.server});

  @override
  State<EditServerScreen> createState() => _EditServerScreenState();
}

class _EditServerScreenState extends State<EditServerScreen> {
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _localUrlController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _wifiSsidController;
  late bool _useHttps;
  late bool _allowUntrustedCertificates;
  late bool _isDefault;
  bool _isTestingConnection = false;
  String? _connectionTestResult;
  late List<String> _trustedWifiSsids;
  String? _currentWifiSsid;
  bool _isLoadingCurrentSsid = false;
  bool _isLoadingCredentials = false;
  final NetworkService _networkService = NetworkService();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.server.name);
    _hostController = TextEditingController(text: widget.server.host);
    _localUrlController = TextEditingController(
      text: widget.server.localUrl ?? '',
    );
    _portController = TextEditingController(
      text: widget.server.port?.toString() ?? '',
    );
    _usernameController = TextEditingController(text: widget.server.username);
    _passwordController =
        TextEditingController(); // Will be loaded from keychain
    _wifiSsidController = TextEditingController();
    _useHttps = widget.server.useHttps;
    _allowUntrustedCertificates = widget.server.allowUntrustedCertificates;
    _isDefault = widget.server.isDefault;
    _trustedWifiSsids = List.from(widget.server.trustedWifiSsids);

    // Schedule credential loading after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadExistingCredentials();
      }
    });
  }

  Future<void> _loadExistingCredentials() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCredentials = true;
    });

    try {
      final serverService = context.read<UnifiedServerService>();

      // Load username from server service
      final server = await serverService.getServer(widget.server.id);
      if (mounted && server != null && server.username.isNotEmpty) {
        setState(() {
          _usernameController.text = server.username;
        });
        if (kDebugMode) {
          print(
            'EditServer: Loaded username ${server.username} for ${widget.server.id}',
          );
        }
      }

      // Load password from keychain
      final password = await serverService.getPassword(widget.server.id);
      if (mounted && password != null) {
        setState(() {
          _passwordController.text = password;
        });
        if (kDebugMode) {
          print('EditServer: Loaded existing password for ${widget.server.id}');
        }
      } else {
        if (kDebugMode) {
          print(
            'EditServer: No existing password found for ${widget.server.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('EditServer: Error loading existing credentials: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

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
        _usernameController.text.isNotEmpty;
    // Note: Password not required for editing if it exists in keychain
  }

  void _addWifiSsid() {
    final ssid = _wifiSsidController.text.trim();
    if (ssid.isNotEmpty && !_trustedWifiSsids.contains(ssid)) {
      if (mounted) {
        setState(() {
          _trustedWifiSsids.add(ssid);
          _wifiSsidController.clear();
        });
      }
    }
  }

  void _removeWifiSsid(String ssid) {
    if (mounted) {
      setState(() {
        _trustedWifiSsids.remove(ssid);
      });
    }
  }

  Future<void> _loadCurrentWifiSsid() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCurrentSsid = true;
      _currentWifiSsid = null; // Reset previous result
    });

    try {
      final ssid = await _networkService.getCurrentWifiSsidWithPermission();
      if (mounted) {
        setState(() {
          _currentWifiSsid = ssid;
        });
      }

      // Show feedback if no Wi-Fi was detected
      if (mounted && ssid == null) {
        if (context.mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('No Wi-Fi Detected'),
              content: const Text(
                'Unable to detect current Wi-Fi network. This could be due to:\n\n'
                '• Not connected to Wi-Fi\n'
                '• Location permission not granted\n'
                '• Platform restrictions (macOS/iOS)\n\n'
                'You can still manually enter network names.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Wi-Fi Detection Error'),
            content: Text(
              'Failed to detect Wi-Fi network: ${e.toString()}\n\n'
              'You can still manually enter network names.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentSsid = false;
        });
      }
    }
  }

  void _addCurrentWifiSsid() {
    if (_currentWifiSsid != null &&
        !_trustedWifiSsids.contains(_currentWifiSsid!)) {
      if (mounted) {
        setState(() {
          _trustedWifiSsids.add(_currentWifiSsid!);
        });
      }
    }
  }

  Future<void> _testConnection() async {
    // For connection test, we need username and password in the fields
    if (_nameController.text.isEmpty ||
        _hostController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _connectionTestResult =
              '❌ Please fill in all fields to test connection';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    final server = widget.server.copyWith(
      name: _nameController.text,
      host: _hostController.text,
      localUrl: _localUrlController.text.isNotEmpty
          ? _localUrlController.text
          : null,
      clearLocalUrl: _localUrlController.text.isEmpty,
      trustedWifiSsids: _trustedWifiSsids,
      port: _portController.text.isNotEmpty
          ? int.tryParse(_portController.text)
          : null,
      clearPort: _portController.text.isEmpty,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
      allowUntrustedCertificates: _allowUntrustedCertificates,
    );

    try {
      final isValid = await context
          .read<ServerProvider>()
          .validateServerCredentials(server);
      if (mounted) {
        setState(() {
          _connectionTestResult = isValid
              ? 'Connection successful!'
              : 'Invalid credentials or connection failed';
          _isTestingConnection = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionTestResult = 'Connection failed: ${e.toString()}';
          _isTestingConnection = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_isValid) return;

    // Debug logging for save operation

    final updatedServer = widget.server.copyWith(
      name: _nameController.text,
      host: _hostController.text,
      localUrl: _localUrlController.text.isNotEmpty
          ? _localUrlController.text
          : null,
      clearLocalUrl: _localUrlController.text.isEmpty,
      trustedWifiSsids: _trustedWifiSsids,
      port: _portController.text.isNotEmpty
          ? int.tryParse(_portController.text)
          : null,
      clearPort: _portController.text.isEmpty,
      username: _usernameController.text,
      password: _passwordController.text,
      useHttps: _useHttps,
      allowUntrustedCertificates: _allowUntrustedCertificates,
      isDefault: _isDefault,
    );

    if (_localUrlController.text.isEmpty && widget.server.localUrl != null) {}

    // Check if password changed
    String? passwordUpdate;
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != widget.server.password) {
      passwordUpdate = _passwordController.text;
    }

    // If setting this server as default, handle the database update
    if (_isDefault && !widget.server.isDefault) {
      await context.read<ServerProvider>().setDefaultServer(widget.server.id);
    } else if (!_isDefault && widget.server.isDefault) {
      await context.read<ServerProvider>().clearDefaultServer();
    } else {
      await context.read<ServerProvider>().updateServer(
        updatedServer,
        password: passwordUpdate,
      );
    }

    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate changes were made
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
        child: AutofillGroup(
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
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CupertinoFormSection(
                header: const Text('TRUSTED WI-FI NETWORKS'),
                children: [
                  // Current Wi-Fi suggestion
                  if (_currentWifiSsid != null &&
                      !_trustedWifiSsids.contains(_currentWifiSsid!))
                    CupertinoFormRow(
                      prefix: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Network'),
                          Text(
                            _currentWifiSsid!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _addCurrentWifiSsid,
                        child: const Text('Add Current'),
                      ),
                    ),
                  if (_currentWifiSsid == null && !_isLoadingCurrentSsid)
                    CupertinoFormRow(
                      prefix: const Text('Current Network'),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _loadCurrentWifiSsid,
                        child: const Text('Detect'),
                      ),
                    ),
                  if (_isLoadingCurrentSsid)
                    const CupertinoFormRow(
                      prefix: Text('Current Network'),
                      child: CupertinoActivityIndicator(),
                    ),
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
                    keyboardType: TextInputType.text,
                    autofillHints: const [AutofillHints.username],
                    onChanged: (_) => setState(() {}),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _passwordController,
                    placeholder: _isLoadingCredentials
                        ? 'Loading...'
                        : 'Password',
                    prefix: const Text('Password'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) => setState(() {}),
                    onEditingComplete: () {
                      // Trigger save password prompt on iOS
                      TextInput.finishAutofillContext();
                    },
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
                  CupertinoFormRow(
                    prefix: const Text('Allow Untrusted Certificates'),
                    child: CupertinoSwitch(
                      value: _allowUntrustedCertificates,
                      onChanged: (value) {
                        setState(() {
                          _allowUntrustedCertificates = value;
                        });
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text('Set as Default Server'),
                    child: CupertinoSwitch(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value;
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
                      onPressed: !_isTestingConnection ? _testConnection : null,
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
      ),
    );
  }
}
