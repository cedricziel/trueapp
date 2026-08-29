import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/screens/dataset_detail_screen.dart';

import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_surfaces.dart';

/// [DatasetDetailScreen] is a pure display widget: it takes a `server` and a
/// `dataset` map handed to it by its caller and renders sections built
/// straight from that map's keys - it never reads a provider or performs any
/// I/O itself. These tests drive it directly with hand-built dataset maps
/// covering the fully-populated case, the "missing optional field" case for
/// every section, and a long-value case for overflow coverage.
void main() {
  late NasServer testServer;

  setUp(() {
    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );
  });

  Widget createTestApp(Map<String, dynamic> dataset) {
    return CupertinoApp(
      home: DatasetDetailScreen(server: testServer, dataset: dataset),
    );
  }

  Map<String, dynamic> valueMap(String value) => {'value': value};

  group('DatasetDetailScreen - fully populated dataset', () {
    final fullDataset = <String, dynamic>{
      'name': 'tank/data',
      'type': 'FILESYSTEM',
      'mountpoint': '/mnt/tank/data',
      'pool': 'tank',
      'encrypted': true,
      'creation': valueMap('2024-01-15 10:30:00'),
      'used': valueMap('120 GiB'),
      'available': valueMap('500 GiB'),
      'usedbydataset': valueMap('100 GiB'),
      'usedbychildren': valueMap('15 GiB'),
      'usedbysnapshots': valueMap('5 GiB'),
      'quota': valueMap('1 TiB'),
      'reservation': valueMap('50 GiB'),
      'compression': valueMap('LZ4'),
      'compressratio': valueMap('1.35x'),
      'deduplication': valueMap('OFF'),
      'checksum': valueMap('SHA256'),
      'aclmode': valueMap('RESTRICTED'),
      'acltype': valueMap('POSIX'),
      'readonly': valueMap('OFF'),
      'exec': valueMap('ON'),
      'encryption_algorithm': valueMap('AES-256-GCM'),
      'recordsize': valueMap('128K'),
      'copies': valueMap('1'),
      'sync': valueMap('STANDARD'),
      'atime': valueMap('ON'),
      'casesensitivity': valueMap('SENSITIVE'),
    };

    testWidgets('uses the last path segment of the name as the nav title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(fullDataset));
      await tester.pump();

      expect(find.text('data'), findsOneWidget);
      // The full "tank/data" only shows in the General Information row, not
      // duplicated as the nav bar title.
      expect(
        find.widgetWithText(CupertinoNavigationBar, 'tank/data'),
        findsNothing,
      );
    });

    testWidgets('renders every section with its data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(fullDataset));
      await tester.pump();

      expect(find.text('General Information'), findsOneWidget);
      expect(find.text('Storage Information'), findsOneWidget);

      // General information
      expect(find.text('tank/data'), findsOneWidget);
      expect(find.text('FILESYSTEM'), findsOneWidget);
      expect(find.text('tank'), findsOneWidget);
      expect(find.text('/mnt/tank/data'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget); // Encrypted
      expect(find.text('2024-01-15 10:30:00'), findsOneWidget);

      // Storage information
      expect(find.text('120 GiB'), findsOneWidget);
      expect(find.text('500 GiB'), findsOneWidget);
      expect(find.text('100 GiB'), findsOneWidget);
      expect(find.text('15 GiB'), findsOneWidget);
      expect(find.text('5 GiB'), findsOneWidget);
      expect(find.text('1 TiB'), findsOneWidget);
      expect(find.text('50 GiB'), findsOneWidget);

      // Icons for the sections visible so far.
      expect(find.byIcon(CupertinoIcons.info_circle), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chart_pie), findsOneWidget);

      // The remaining sections are below the fold of the default 800x600
      // test surface, and `ListView`'s sliver only builds/lays out children
      // near the viewport - so they must be scrolled into view before their
      // text can be found at all (mirrors the pattern in
      // server_detail_screen_test.dart).
      await tester.scrollUntilVisible(
        find.text('Advanced Properties'),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.text('Compression & Efficiency'), findsOneWidget);
      expect(find.text('Security & Permissions'), findsOneWidget);
      expect(find.text('Advanced Properties'), findsOneWidget);

      // Compression & efficiency
      expect(find.text('LZ4'), findsOneWidget);
      expect(find.text('1.35x'), findsOneWidget);
      // deduplication and readonly are both 'OFF' in this dataset.
      expect(find.text('OFF'), findsNWidgets(2));
      expect(find.text('SHA256'), findsOneWidget);

      // Security & permissions
      expect(find.text('RESTRICTED'), findsOneWidget);
      expect(find.text('POSIX'), findsOneWidget);
      expect(find.text('AES-256-GCM'), findsOneWidget);

      // Advanced properties
      expect(find.text('128K'), findsOneWidget);
      expect(find.text('STANDARD'), findsOneWidget);
      expect(find.text('SENSITIVE'), findsOneWidget);
      // exec and atime are both 'ON' in this dataset.
      expect(find.text('ON'), findsNWidgets(2));

      expect(find.byIcon(CupertinoIcons.archivebox), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.lock_shield), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.gear), findsOneWidget);
    });

    testWidgets('tapping Back pops the route', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: Builder(
                builder: (context) => CupertinoButton(
                  child: const Text('Open'),
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => DatasetDetailScreen(
                        server: testServer,
                        dataset: fullDataset,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await settleRouteTransition(tester);

      expect(find.text('General Information'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await settleRouteTransition(tester);

      expect(find.text('General Information'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });

  group(
    'DatasetDetailScreen - minimal dataset (defaults and omitted fields)',
    () {
      testWidgets('falls back to default values for an empty dataset map', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(createTestApp(const {}));
        await tester.pump();

        // Nav title falls back to 'Unknown Dataset', last segment is the whole
        // string since there is no '/'. The Name row uses a different default
        // ('Unknown') for the missing `name` key.
        expect(find.text('Unknown Dataset'), findsOneWidget);
        expect(find.text('Unknown'), findsOneWidget);
        // General info defaults
        expect(find.text('FILESYSTEM'), findsOneWidget); // type default
        expect(find.text('No'), findsOneWidget); // encrypted default false

        // Mountpoint row is hidden entirely when empty.
        expect(find.text('Mount Point'), findsNothing);
        // Created row is hidden when creation is null.
        expect(find.text('Created'), findsNothing);

        // Every optional section's rows are omitted when their source key is
        // null, since each `_build*Info` guards with `if (x != null)`.
        expect(find.text('Used Space'), findsNothing);
        expect(find.text('Available Space'), findsNothing);
        expect(find.text('Quota'), findsNothing);
        expect(find.text('Reservation'), findsNothing);
        expect(find.text('Compression'), findsNothing);
        expect(find.text('ACL Mode'), findsNothing);
        expect(find.text('Encryption'), findsNothing);
        expect(find.text('Record Size'), findsNothing);

        // The section containers themselves still render (they always have a
        // header even with zero optional rows).
        expect(find.text('General Information'), findsOneWidget);
        expect(find.text('Storage Information'), findsOneWidget);
        expect(find.text('Compression & Efficiency'), findsOneWidget);
        expect(find.text('Security & Permissions'), findsOneWidget);
        expect(find.text('Advanced Properties'), findsOneWidget);
      });

      testWidgets(
        'shows quota/reservation rows only when their value is non-null',
        (WidgetTester tester) async {
          final dataset = <String, dynamic>{
            'name': 'tank/no-quota',
            // quota/reservation present as a map but with a null 'value',
            // exercising the extra `quota['value'] != null` guard distinct
            // from the `quota != null` guard other rows use.
            'quota': const {'value': null},
            'reservation': const {'value': null},
          };

          await tester.pumpWidget(createTestApp(dataset));
          await tester.pump();

          expect(find.text('Quota'), findsNothing);
          expect(find.text('Reservation'), findsNothing);
        },
      );

      testWidgets('shows quota/reservation rows when a value is present', (
        WidgetTester tester,
      ) async {
        final dataset = <String, dynamic>{
          'name': 'tank/quota',
          'quota': valueMap('2 TiB'),
          'reservation': valueMap('10 GiB'),
        };

        await tester.pumpWidget(createTestApp(dataset));
        await tester.pump();

        expect(find.text('Quota'), findsOneWidget);
        expect(find.text('2 TiB'), findsOneWidget);
        expect(find.text('Reservation'), findsOneWidget);
        expect(find.text('10 GiB'), findsOneWidget);
      });

      testWidgets(
        'falls back to per-field default text when a value map has no value',
        (WidgetTester tester) async {
          final dataset = <String, dynamic>{
            'name': 'tank/defaults',
            'used': const <String, dynamic>{},
            'compression': const <String, dynamic>{},
            'checksum': const <String, dynamic>{},
          };

          await tester.pumpWidget(createTestApp(dataset));
          await tester.pump();

          expect(find.text('0B'), findsOneWidget); // used default
          expect(find.text('Unknown'), findsWidgets); // compression/checksum
        },
      );
    },
  );

  group('DatasetDetailScreen - layout', () {
    testWidgets('renders every section at iPhone width without layout overflow', (
      WidgetTester tester,
    ) async {
      // `_buildSection`'s header Row (Icon + Text title) used to have no
      // Expanded/Flexible around the title, so the two longer section
      // titles - "Compression & Efficiency" and "Security & Permissions" -
      // overflowed at iPhone width unconditionally, even for a totally
      // empty dataset. Fixed by giving the title the same
      // Expanded+ellipsis treatment as ServerDetailScreen's section
      // headers (ticket #86).
      useCompactSurface(tester);

      final dataset = <String, dynamic>{
        'name':
            'tank/a-very-long-dataset-path/that/keeps/going/and/going/and/stresses/the/layout',
        'type': 'FILESYSTEM',
        'mountpoint':
            '/mnt/tank/a-very-long-dataset-path/that/keeps/going/and/going',
        'pool': 'tank',
        'encrypted': true,
        'creation': valueMap('2024-01-15 10:30:00'),
      };

      await tester.pumpWidget(createTestApp(dataset));
      await pumpUntilFound(tester, find.text('General Information'));

      await tester.scrollUntilVisible(
        find.text('Advanced Properties'),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.text('Compression & Efficiency'), findsOneWidget);
      expect(find.text('Security & Permissions'), findsOneWidget);
      expect(find.text('Advanced Properties'), findsOneWidget);
      expectNoLayoutOverflow(tester);
    });
  });
}
