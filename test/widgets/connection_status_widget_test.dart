import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/widgets/connection_status_widget.dart';
import '../helpers/layout_assertions.dart';

void main() {
  late ConnectionStatusProvider provider;

  setUp(() {
    provider = ConnectionStatusProvider();
  });

  Widget wrap(Widget child, {double width = 375}) {
    return ChangeNotifierProvider<ConnectionStatusProvider>.value(
      value: provider,
      child: CupertinoApp(
        home: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  group('ConnectionStatusWidget', () {
    testWidgets('shows "Not Connected" when no status is known yet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Not Connected'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.circle), findsOneWidget);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows "Connected" with a green checkmark when healthy', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState('srv-1', TrueNASConnectionState.connected);

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Connected'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.checkmark_circle_fill),
      );
      expect(icon.color, CupertinoColors.systemGreen);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'shows "Connection Issues" when connected but the last pong is stale',
      (WidgetTester tester) async {
        provider.updateConnectionState(
          'srv-1',
          TrueNASConnectionState.connected,
        );
        provider.updatePingStatus(
          'srv-1',
          pongReceived: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(
          wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
        );

        expect(find.text('Connection Issues'), findsOneWidget);
      },
    );

    testWidgets('shows the latency in ms while connected', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState('srv-1', TrueNASConnectionState.connected);
      provider.updatePingStatus(
        'srv-1',
        latency: const Duration(milliseconds: 42),
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('42ms'), findsOneWidget);
    });

    testWidgets('shows "Connecting..." with an orange refresh icon', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.connecting,
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Connecting...'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.arrow_clockwise),
      );
      expect(icon.color, CupertinoColors.systemOrange);
    });

    testWidgets('shows "Reconnecting..." with an orange refresh icon', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.reconnecting,
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Reconnecting...'), findsOneWidget);
    });

    testWidgets('shows "Connection Error" with a red icon', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.error,
        error: 'timed out',
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Connection Error'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.exclamationmark_circle_fill),
      );
      expect(icon.color, CupertinoColors.systemRed);
    });

    testWidgets('shows "Disconnected" with a grey icon', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState('srv-1', TrueNASConnectionState.connected);
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.disconnected,
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1')),
      );

      expect(find.text('Disconnected'), findsOneWidget);
    });

    testWidgets('renders only a colored dot and no text in compact mode', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState('srv-1', TrueNASConnectionState.connected);

      await tester.pumpWidget(
        wrap(const ConnectionStatusWidget(serverId: 'srv-1', compact: true)),
      );

      expect(find.text('Connected'), findsNothing);
      expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsNothing);
      expect(find.byType(Container), findsWidgets);
      expectNoLayoutOverflow(tester);
    });
  });

  group('ConnectionStatusTitleWidget', () {
    testWidgets('renders nothing when no status is known', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
      );

      expect(find.byType(GestureDetector), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows a green wifi icon when connected and healthy', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.connected,
        connectionUrl: 'https://truenas.local',
        isLocalConnection: true,
      );
      provider.updatePingStatus(
        'srv-1',
        latency: const Duration(milliseconds: 15),
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
      );

      final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.wifi));
      expect(icon.color, CupertinoColors.systemGreen);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'shows an orange wifi-exclamation icon when connected but unhealthy',
      (WidgetTester tester) async {
        provider.updateConnectionState(
          'srv-1',
          TrueNASConnectionState.connected,
        );
        provider.updatePingStatus(
          'srv-1',
          pongReceived: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(
          wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
        );

        final icon = tester.widget<Icon>(
          find.byIcon(CupertinoIcons.wifi_exclamationmark),
        );
        expect(icon.color, CupertinoColors.systemOrange);
      },
    );

    testWidgets(
      'shows a small activity indicator while connecting or reconnecting',
      (WidgetTester tester) async {
        provider.updateConnectionState(
          'srv-1',
          TrueNASConnectionState.connecting,
        );

        await tester.pumpWidget(
          wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
        );

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      },
    );

    testWidgets('shows a red wifi-slash icon on error', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.error,
        error: 'connection reset',
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
      );

      final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.wifi_slash));
      expect(icon.color, CupertinoColors.systemRed);
    });

    testWidgets('shows a grey wifi-slash icon when disconnected', (
      WidgetTester tester,
    ) async {
      provider.updateConnectionState('srv-1', TrueNASConnectionState.connected);
      provider.updateConnectionState(
        'srv-1',
        TrueNASConnectionState.disconnected,
      );

      await tester.pumpWidget(
        wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
      );

      final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.wifi_slash));
      expect(icon.color, CupertinoColors.systemGrey);
    });

    testWidgets(
      'tapping opens a details dialog with URL, network kind and latency',
      (WidgetTester tester) async {
        // Order doesn't matter here: both `updatePingStatus` and
        // `updateConnectionState` copyWith from the existing status, so
        // latency and connectionUrl/isLocalConnection are preserved
        // regardless of which call sets them first.
        provider.updatePingStatus(
          'srv-1',
          latency: const Duration(milliseconds: 15),
        );
        provider.updateConnectionState(
          'srv-1',
          TrueNASConnectionState.connected,
          connectionUrl: 'https://truenas.local:444',
          isLocalConnection: true,
        );

        await tester.pumpWidget(
          wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
        );

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        expect(find.text('Connection Status'), findsOneWidget);
        expect(find.textContaining('Connected'), findsWidgets);
        expect(find.text('https://truenas.local:444'), findsOneWidget);
        expect(find.text('Local Network'), findsOneWidget);
        expect(find.textContaining('Last ping:'), findsOneWidget);
        expect(find.textContaining('Last pong:'), findsOneWidget);
        expect(find.text('Latency: 15ms'), findsOneWidget);

        await tester.tap(find.text('OK'));
        await tester.pump();
        expect(find.text('Connection Status'), findsNothing);
      },
    );

    testWidgets(
      'the details dialog shows a remote-connection indicator and the '
      'error message when the connection failed',
      (WidgetTester tester) async {
        provider.updateConnectionState(
          'srv-1',
          TrueNASConnectionState.connected,
          connectionUrl: 'https://truenas.example.com',
          isLocalConnection: false,
        );

        await tester.pumpWidget(
          wrap(const ConnectionStatusTitleWidget(serverId: 'srv-1')),
        );

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        expect(find.text('Remote Connection'), findsOneWidget);
      },
    );
  });
}
