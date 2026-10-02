import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/services_provider.dart';
import 'package:truehub/widgets/connection_error_widget.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/service_action_error_banner.dart';
import 'package:truehub/widgets/service_tile.dart';

class ServicesScreen extends StatefulWidget {
  final NasServer server;

  const ServicesScreen({super.key, required this.server});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ServicesProvider>().loadServices(),
    );
  }

  Future<void> _perform(
    ServicesProvider provider,
    String serviceId,
    ServiceAction action,
  ) {
    return switch (action) {
      ServiceAction.start => provider.startService(serviceId),
      ServiceAction.stop => provider.stopService(serviceId),
      ServiceAction.restart => provider.restartService(serviceId),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.server.name} - Services'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: JobsBellButton(server: widget.server),
      ),
      child: SafeArea(
        child: Consumer<ServicesProvider>(
          builder: (context, provider, child) {
            if (!provider.hasLoaded && provider.connectionError == null) {
              return const LoadingStateWidget(message: 'Loading services...');
            }

            if (provider.connectionError != null) {
              return Center(
                child: ConnectionErrorWidget(
                  error: provider.connectionError!,
                  onRetry: provider.loadServices,
                  onSettings: () => Navigator.pop(context),
                ),
              );
            }

            if (provider.services.isEmpty) {
              return const EmptyStateWidget(
                icon: CupertinoIcons.gear,
                title: 'No services found',
                message: 'Services running on this server will appear here.',
              );
            }

            final actionError = provider.actionError;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (actionError != null)
                  ServiceActionErrorBanner(
                    key: const Key('services-action-error'),
                    message: actionError,
                    onDismiss: provider.clearActionError,
                  ),
                for (final service in provider.services)
                  ServiceTile(
                    service: service,
                    isBusy: provider.isBusy(service.id),
                    onAction: (action) =>
                        _perform(provider, service.id, action),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
