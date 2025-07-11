import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';

class AuthenticationStateWidget extends StatelessWidget {
  final Widget child;
  final Widget? lockIcon;

  const AuthenticationStateWidget({
    super.key,
    required this.child,
    this.lockIcon,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthenticationStatus>(
      stream: context.watch<ServerProvider>().authenticationStream,
      initialData: context.read<ServerProvider>().currentAuthStatus,
      builder: (context, snapshot) {
        final authStatus = snapshot.data;

        if (authStatus == null) {
          return child;
        }

        switch (authStatus.state) {
          case AuthenticationState.authenticating:
            return _buildAuthenticatingState(context);
          case AuthenticationState.required:
          case AuthenticationState.failed:
            return _buildLockedState(context, authStatus);
          case AuthenticationState.authenticated:
          case AuthenticationState.none:
            return child;
        }
      },
    );
  }

  Widget _buildAuthenticatingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 20),
          const SizedBox(height: 16),
          Text(
            'Authenticating...',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState(
    BuildContext context,
    AuthenticationStatus authStatus,
  ) {
    final isRetryable = authStatus.state == AuthenticationState.failed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lock_shield,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 24),
            Text(
              authStatus.state == AuthenticationState.required
                  ? 'Authentication Required'
                  : 'Authentication Failed',
              style: CupertinoTheme.of(
                context,
              ).textTheme.navLargeTitleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (authStatus.error != null)
              Text(
                authStatus.error!,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                context.read<ServerProvider>().retryAuthentication();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRetryable ? CupertinoIcons.refresh : CupertinoIcons.lock,
                  ),
                  const SizedBox(width: 8),
                  Text(isRetryable ? 'Retry Authentication' : 'Authenticate'),
                ],
              ),
            ),
            if (authStatus.server != null) ...[
              const SizedBox(height: 16),
              Text(
                'Server: ${authStatus.server!.name}',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
