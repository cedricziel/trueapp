import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/database.dart';

import '../../helpers/test_database.dart';

void main() {
  group('AppDatabaseHolder', () {
    late int opened;
    late AppDatabaseHolder holder;

    setUp(() {
      opened = 0;
      holder = AppDatabaseHolder(
        open: () {
          opened++;
          return createTestDatabase();
        },
      );
    });

    test('opens lazily and reuses the database', () {
      expect(opened, 0);

      final first = holder.current;

      expect(identical(holder.current, first), isTrue);
      expect(opened, 1);
    });

    test('exposes the DAOs of the current database', () {
      expect(identical(holder.serversDao, holder.current.serversDao), isTrue);
      expect(
        identical(holder.appConfigsDao, holder.current.appConfigsDao),
        isTrue,
      );
    });

    test(
      'dispose closes the database and the next access reopens it',
      () async {
        final first = holder.current;
        final firstServersDao = holder.serversDao;

        await holder.dispose();

        expect(identical(holder.current, first), isFalse);
        expect(identical(holder.serversDao, firstServersDao), isFalse);
        expect(opened, 2);
      },
    );

    test('dispose without an open database is a no-op', () async {
      await holder.dispose();

      expect(opened, 0);
    });
  });
}
