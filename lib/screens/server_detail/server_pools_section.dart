import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/pool_card_widget.dart';
import 'package:truehub/widgets/section_header.dart';

class ServerPoolsSection extends StatelessWidget {
  final NasServer server;

  const ServerPoolsSection({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Consumer<PoolProvider>(
      builder: (context, poolProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Storage Pools',
                action: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/server/${server.id}/pools', extra: server);
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              if (poolProvider.isLoading)
                const LoadingStateWidget(message: 'Loading pools...')
              else if (poolProvider.error != null)
                ErrorStateWidget(
                  title: 'Pool Error',
                  message: 'Failed to load pools: ${poolProvider.error}',
                )
              else if (poolProvider.pools.isEmpty)
                const EmptyStateWidget(
                  icon: CupertinoIcons.square_stack_3d_down_right,
                  title: 'No Pools',
                  message: 'No storage pools found',
                )
              else
                Column(
                  children: poolProvider.pools.map((pool) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PoolCardWidget(pool: pool, server: server),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
