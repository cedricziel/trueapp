part of 'unified_server_service_test.dart';

/// Test setup and utility functions following DRY principle
void _testInitialization() {
  test('should initialize successfully with valid dependencies', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );

    final result = await service.initialize();
    
    expect(result, isTrue);
    expect(service.isInitialized, isTrue);
  });

  test('should fail initialization when repository fails', () async {
    final repository = MockServerRepository();
    repository.setShouldFailOperations(true);
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );

    final result = await service.initialize();
    
    expect(result, isFalse);
    expect(service.isInitialized, isFalse);
  });

  test('should handle multiple initialization calls gracefully', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );

    // Initialize multiple times
    final result1 = await service.initialize();
    final result2 = await service.initialize();
    final result3 = await service.initialize();
    
    expect(result1, isTrue);
    expect(result2, isTrue);
    expect(result3, isTrue);
    expect(service.isInitialized, isTrue);
  });

  test('should expose correct capability flags', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );

    await service.initialize();
    
    expect(service.supportsOfflineAccess, isTrue);
    expect(service.supportsAutoSync, isFalse);
  });
}