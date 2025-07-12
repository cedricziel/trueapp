import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';

part 'server_repository_interface_test_mock.dart';
part 'server_repository_interface_test_contract.dart';

void main() {
  group('ServerRepositoryInterface Contract Tests', () {
    late MockServerRepositoryImplementation repository;

    setUp(() {
      repository = MockServerRepositoryImplementation();
    });

    tearDown(() async {
      await repository.dispose();
    });

    _testRepositoryContract();
    _testServerOperations();
    _testDefaultServerManagement();
    _testStreamBehavior();
    _testSyncOperations();
  });
}