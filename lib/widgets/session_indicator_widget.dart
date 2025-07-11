import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:truenas_manager/services/authentication_session_service.dart';

class SessionIndicatorWidget extends StatefulWidget {
  const SessionIndicatorWidget({super.key});

  @override
  State<SessionIndicatorWidget> createState() => _SessionIndicatorWidgetState();
}

class _SessionIndicatorWidgetState extends State<SessionIndicatorWidget> {
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    // Update every 10 seconds to show session countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final session = AuthenticationSessionService.instance;
    final isValid = session.isSessionValid;
    final remaining = session.remainingSessionTime;
    
    if (!isValid || remaining == null) {
      return const SizedBox.shrink();
    }
    
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.lock_open,
            size: 16,
            color: minutes < 5 
                ? CupertinoColors.systemOrange 
                : CupertinoColors.systemGreen,
          ),
          if (kDebugMode) ...[
            const SizedBox(width: 4),
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')}',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontSize: 12,
                color: minutes < 5 
                    ? CupertinoColors.systemOrange 
                    : CupertinoColors.systemGreen,
              ),
            ),
          ],
        ],
      ),
      onPressed: () {
        // Show session info dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Authentication Session'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  isValid 
                      ? 'Session is active. Time remaining: $minutes minutes' 
                      : 'No active session',
                ),
                const SizedBox(height: 8),
                const Text(
                  'The session will automatically expire after 30 minutes of inactivity.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              if (isValid)
                CupertinoDialogAction(
                  onPressed: () {
                    AuthenticationSessionService.instance.invalidateSession();
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                  child: const Text('Lock Now'),
                ),
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}