import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/widgets/section_header.dart';
import 'package:truehub/widgets/system_stats_widget.dart';

class ServerSystemStatsSection extends StatelessWidget {
  const ServerSystemStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'System Stats',
            action: Consumer<SystemStatsProvider>(
              builder: (context, statsProvider, child) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (statsProvider.isSubscribed) {
                      statsProvider.unsubscribeFromStats();
                    } else {
                      statsProvider.subscribeToStats();
                    }
                  },
                  child: Icon(
                    statsProvider.isSubscribed
                        ? CupertinoIcons.pause_circle
                        : CupertinoIcons.play_circle,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const SystemStatsWidget(),
        ],
      ),
    );
  }
}
