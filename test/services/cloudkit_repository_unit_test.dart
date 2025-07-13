import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/cloudkit_server_repository.dart';
import '../helpers/mock_cloudkit_service_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CloudKitServerRepository Unit Tests', () {
    late CloudKitServerRepository repository;
    late MockCloudKitServiceAdapter mockCloudKitService;

    setUp(() {
      mockCloudKitService = MockCloudKitServiceAdapter();
      repository = CloudKitServerRepository(
        cloudKitService: mockCloudKitService,
      );
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('should report correct capabilities', () {
      expect(repository.supportsOfflineAccess, isTrue);
      expect(repository.supportsAutoSync, isTrue);
    });

    test('should provide servers stream', () {
      final stream = repository.serversStream;
      expect(stream, isA<Stream<List<dynamic>>>());
    });

    test('should handle initialization attempt', () async {
      // CloudKit initialization will fail in test environment
      // but should not throw exceptions
      final result = await repository.initialize();
      expect(result, isA<bool>());
    });

    test('should handle sync operation', () async {
      // Sync should return a boolean result
      final result = await repository.sync();
      expect(result, isA<bool>());
    });
  });
}
