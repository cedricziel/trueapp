import 'package:flutter/cupertino.dart';
import 'package:truehub/models/connection_error.dart';

class ConnectionErrorWidget extends StatelessWidget {
  final ConnectionError error;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;

  const ConnectionErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error icon
          Icon(_getErrorIcon(), size: 64, color: CupertinoColors.systemRed),
          const SizedBox(height: 16),

          // Error title
          Text(
            error.shortMessage,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // User-friendly error message
          Text(
            error.userFriendlyMessage,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (error.isRetryable && onRetry != null) ...[
                CupertinoButton.filled(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
              ],
              if (onSettings != null)
                CupertinoButton(
                  onPressed: onSettings,
                  child: const Text('Check Settings'),
                ),
            ],
          ),

          // Technical details (expandable)
          if (error.technicalDetails != null) ...[
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: () => _showTechnicalDetails(context),
              child: const Text(
                'Show Technical Details',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ConnectionErrorType.networkUnreachable:
        return CupertinoIcons.wifi_slash;
      case ConnectionErrorType.connectionTimeout:
        return CupertinoIcons.time;
      case ConnectionErrorType.authenticationFailed:
      case ConnectionErrorType.invalidCredentials:
        return CupertinoIcons.lock_slash;
      case ConnectionErrorType.permissionDenied:
        return CupertinoIcons.exclamationmark_shield;
      case ConnectionErrorType.serverError:
        return CupertinoIcons.exclamationmark_triangle;
      case ConnectionErrorType.invalidResponse:
        return CupertinoIcons.exclamationmark_bubble;
      case ConnectionErrorType.unknown:
        return CupertinoIcons.question_circle;
    }
  }

  void _showTechnicalDetails(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Technical Details'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            error.technicalDetails!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// A compact version for showing errors in lists or smaller spaces
class CompactConnectionErrorWidget extends StatelessWidget {
  final ConnectionError error;
  final VoidCallback? onRetry;

  const CompactConnectionErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.shortMessage,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (error.isRetryable && onRetry != null) ...[
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }
}
