import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';

class UserProfileScreen extends StatefulWidget {
  final NasServer server;

  const UserProfileScreen({super.key, required this.server});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
  }

  Future<void> _loadUserInfo() async {
    final provider = context.read<ServerProvider>();
    if (provider.selectedServer?.id == widget.server.id) {
      await provider.loadCurrentUser();
    } else {
      await provider.selectServer(widget.server);
      await provider.loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('User Profile'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Consumer<ServerProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildUserHeader(provider),
                const SizedBox(height: 20),
                _buildUserDetails(provider),
                const SizedBox(height: 20),
                _buildSecurityInfo(provider),
                const SizedBox(height: 20),
                _buildSystemInfo(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserHeader(ServerProvider provider) {
    if (provider.isLoadingUser) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (provider.userError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemRed,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Failed to load user information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemRed,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.userError!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadUserInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.person_circle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'No user information available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _loadUserInfo,
              child: const Text('Load User Info'),
            ),
          ],
        ),
      );
    }

    final user = provider.currentUser!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 40,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName.isNotEmpty ? user.fullName : user.username,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (user.fullName.isNotEmpty && user.fullName != user.username) ...[
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (user.isAdministrator) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        size: 14,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (user.hasTwoFactor) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.lock_shield_fill,
                        size: 14,
                        color: CupertinoColors.systemGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '2FA Enabled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(ServerProvider provider) {
    if (provider.currentUser == null) return const SizedBox.shrink();

    final user = provider.currentUser!;
    return _buildSection(
      title: 'Account Details',
      icon: CupertinoIcons.person_circle,
      children: [
        _buildInfoRow('Username', user.username),
        if (user.fullName.isNotEmpty) _buildInfoRow('Full Name', user.fullName),
        _buildInfoRow('User ID', user.uid.toString()),
        _buildInfoRow('Group ID', user.gid.toString()),
        _buildInfoRow('Home Directory', user.homeDirectory),
        _buildInfoRow('Shell', user.shell),
        _buildInfoRow('Account Source', user.sourceDisplayName),
        _buildInfoRow('Local Account', user.isLocal ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildSecurityInfo(ServerProvider provider) {
    if (provider.currentUser == null) return const SizedBox.shrink();

    final user = provider.currentUser!;
    return _buildSection(
      title: 'Security & Permissions',
      icon: CupertinoIcons.lock_shield,
      children: [
        _buildInfoRow(
          'Administrator',
          user.isAdministrator ? 'Yes' : 'No',
          valueColor: user.isAdministrator
              ? CupertinoColors.systemOrange
              : CupertinoColors.systemGrey,
        ),
        _buildInfoRow(
          'Two-Factor Authentication',
          user.hasTwoFactor ? 'Enabled' : 'Disabled',
          valueColor: user.hasTwoFactor
              ? CupertinoColors.systemGreen
              : CupertinoColors.systemGrey,
        ),
        if (user.groupList.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Groups',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.groupList.map((group) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemInfo(ServerProvider provider) {
    return _buildSection(
      title: 'Server Information',
      icon: CupertinoIcons.cube_box,
      children: [
        _buildInfoRow('Server Name', widget.server.name),
        _buildInfoRow('Host', widget.server.host),
        _buildInfoRow('Port', widget.server.port.toString()),
        _buildInfoRow('Protocol', widget.server.useHttps ? 'HTTPS' : 'HTTP'),
        if (widget.server.lastConnected != null)
          _buildInfoRow(
            'Last Connected',
            _formatLastConnected(widget.server.lastConnected!),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CupertinoColors.activeBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastConnected(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
