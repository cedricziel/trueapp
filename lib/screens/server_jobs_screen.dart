import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/job_card_widget.dart';

enum _JobsTab { running, waiting, history }

/// The Jobs view: running/queued/finished TrueNAS jobs for [server], live via
/// [JobsProvider]. The provider's subscription is owned by
/// [ServerDetailScreen] (started in its `initState`, stopped in its
/// `dispose`) so it keeps running - and the nav bar bell keeps working -
/// while this screen and its siblings are pushed and popped on top of it.
class ServerJobsScreen extends StatefulWidget {
  final NasServer server;

  const ServerJobsScreen({super.key, required this.server});

  @override
  State<ServerJobsScreen> createState() => _ServerJobsScreenState();
}

class _ServerJobsScreenState extends State<ServerJobsScreen> {
  _JobsTab _tab = _JobsTab.running;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Jobs'),
        previousPageTitle: widget.server.name,
        trailing: Consumer<JobsProvider>(
          builder: (context, jobsProvider, child) {
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: jobsProvider.refreshJobs,
              child: const Icon(CupertinoIcons.refresh),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Consumer<JobsProvider>(
          builder: (context, jobsProvider, child) {
            if (jobsProvider.isLoading && !jobsProvider.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (jobsProvider.error != null && !jobsProvider.hasData) {
              return ErrorStateWidget(
                title: 'Jobs Error',
                message: jobsProvider.error!,
                onRetry: jobsProvider.refreshJobs,
              );
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _JobsOverviewCard(jobsProvider: jobsProvider),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoSegmentedControl<_JobsTab>(
                    groupValue: _tab,
                    onValueChanged: (value) => setState(() => _tab = value),
                    children: {
                      _JobsTab.running: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text('Running ${jobsProvider.runningCount}'),
                      ),
                      _JobsTab.waiting: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text('Waiting ${jobsProvider.waitingCount}'),
                      ),
                      _JobsTab.history: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Text('History'),
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildList(jobsProvider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(JobsProvider jobsProvider) {
    final List<Job> jobs = switch (_tab) {
      _JobsTab.running => jobsProvider.runningJobs,
      _JobsTab.waiting => jobsProvider.waitingJobs,
      _JobsTab.history => jobsProvider.historyJobs,
    };

    if (jobs.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: JobCardWidget(
            job: job,
            onCancel: job.isRunning
                ? () => context.read<JobsProvider>().abortJob(job.id)
                : null,
            onRetry: job.isFailed
                ? () => context.read<JobsProvider>().rerunJob(job)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    final (title, message) = switch (_tab) {
      _JobsTab.running => (
        'Nothing running',
        'Jobs in progress will appear here.',
      ),
      _JobsTab.waiting => (
        'Nothing queued',
        'Jobs waiting to start will appear here.',
      ),
      _JobsTab.history => (
        'No finished jobs',
        'Completed, failed, and aborted jobs will appear here.',
      ),
    };

    return EmptyStateWidget(
      icon: CupertinoIcons.clock,
      title: title,
      message: message,
    );
  }
}

class _JobsOverviewCard extends StatelessWidget {
  final JobsProvider jobsProvider;

  const _JobsOverviewCard({required this.jobsProvider});

  @override
  Widget build(BuildContext context) {
    final failedRecently = jobsProvider.recentFailures.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Row(
        children: [
          _Stat(
            count: jobsProvider.runningCount,
            label: 'Running',
            color: CupertinoColors.systemBlue,
          ),
          _Stat(
            count: jobsProvider.waitingCount,
            label: 'Waiting',
            color: CupertinoColors.systemGrey,
          ),
          _Stat(
            count: failedRecently,
            label: 'Failed 24h',
            color: failedRecently > 0
                ? CupertinoColors.systemRed
                : CupertinoColors.systemGrey,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _Stat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
