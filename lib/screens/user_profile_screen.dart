import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/widgets/section_card.dart';

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
          color: CupertinoColors.systemRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.systemRed.withValues(alpha: 0.3),
          ),
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
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
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
          // Wrap rather than Row: two badges side by side can be wider than
          // a narrow phone screen, and a Row has no way to shrink fixed-size
          // badge chips - wrapping to a second line keeps both visible
          // instead of overflowing.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.isAdministrator) ...[
                const StatusPill(
                  label: 'Administrator',
                  color: CupertinoColors.systemOrange,
                  icon: CupertinoIcons.star_fill,
                ),
                const SizedBox(width: 8),
              ],
              if (user.hasTwoFactor)
                const StatusPill(
                  label: '2FA Enabled',
                  color: CupertinoColors.systemGreen,
                  icon: CupertinoIcons.lock_shield_fill,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(ServerProvider provider) {
    if (provider.currentUser == null) return const SizedBox.shrink();

    final user = provider.currentUser!;
    return SectionCard(
      title: 'Account Details',
      icon: CupertinoIcons.person_circle,
      children: [
        InfoRow('Username', user.username),
        if (user.fullName.isNotEmpty) InfoRow('Full Name', user.fullName),
        InfoRow('User ID', user.uid.toString()),
        InfoRow('Group ID', user.gid.toString()),
        InfoRow('Home Directory', user.homeDirectory),
        InfoRow('Shell', user.shell),
        InfoRow('Account Source', user.sourceDisplayName),
        InfoRow('Local Account', user.isLocal ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildSecurityInfo(ServerProvider provider) {
    if (provider.currentUser == null) return const SizedBox.shrink();

    final user = provider.currentUser!;
    return SectionCard(
      title: 'Security & Permissions',
      icon: CupertinoIcons.lock_shield,
      children: [
        InfoRow(
          'Administrator',
          user.isAdministrator ? 'Yes' : 'No',
          valueColor: user.isAdministrator
              ? CupertinoColors.systemOrange
              : CupertinoColors.systemGrey,
        ),
        InfoRow(
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
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
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
    return SectionCard(
      title: 'Server Information',
      icon: CupertinoIcons.cube_box,
      children: [
        InfoRow('Server Name', widget.server.name),
        InfoRow('Host', widget.server.host),
        InfoRow('Port', widget.server.port.toString()),
        InfoRow('Protocol', widget.server.useHttps ? 'HTTPS' : 'HTTP'),
        if (widget.server.lastConnected != null)
          InfoRow(
            'Last Connected',
            _formatLastConnected(widget.server.lastConnected!),
          ),
      ],
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
