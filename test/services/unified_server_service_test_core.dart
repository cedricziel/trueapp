part of 'unified_server_service_test.dart';

/// Core functionality tests following Single Responsibility Principle
void _testServerConfiguration() {
  test('should save server configuration with password', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'test-password',
    );

    final result = await service.saveServerConfig(
      server: server,
      password: 'secure-password',
    );

    expect(result, isTrue);
    expect(repository.serverCount, equals(1));
    expect(keychain.passwordCount, equals(1));
    
    final savedServer = await repository.getServer(server.id);
    expect(savedServer, isNotNull);
    expect(savedServer!.name, equals('Test Server'));
    expect(savedServer.host, equals('192.168.1.100'));
    
    final savedPassword = await keychain.getPassword(server.id);
    expect(savedPassword, equals('secure-password'));
  });

  test('should update server configuration without changing password', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final originalServer = NasServer.create(
      name: 'Original Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );

    // Save initial configuration
    await service.saveServerConfig(
      server: originalServer,
      password: 'original-password',
    );

    // Update server metadata only
    final updatedServer = originalServer.copyWith(
      name: 'Updated Server',
      host: '192.168.1.200',
    );

    final result = await service.updateServerConfig(updatedServer);

    expect(result, isTrue);
    
    final savedServer = await repository.getServer(originalServer.id);
    expect(savedServer!.name, equals('Updated Server'));
    expect(savedServer.host, equals('192.168.1.200'));
    
    // Password should remain unchanged
    final password = await keychain.getPassword(originalServer.id);
    expect(password, equals('original-password'));
  });

  test('should delete server configuration and password', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );

    // Save server first
    await service.saveServerConfig(
      server: server,
      password: 'test-password',
    );

    expect(repository.serverCount, equals(1));
    expect(keychain.passwordCount, equals(1));

    // Delete server
    final result = await service.deleteServerConfig(server.id);

    expect(result, isTrue);
    expect(repository.serverCount, equals(0));
    expect(keychain.passwordCount, equals(0));
    
    final deletedServer = await repository.getServer(server.id);
    expect(deletedServer, isNull);
    
    final deletedPassword = await keychain.getPassword(server.id);
    expect(deletedPassword, isNull);
  });

  test('should handle save failures gracefully', () async {
    final repository = MockServerRepository();
    repository.setShouldFailOperations(true);
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );

    final result = await service.saveServerConfig(
      server: server,
      password: 'test-password',
    );

    expect(result, isFalse);
    expect(repository.serverCount, equals(0));
    // Password should not be saved if server save fails
    expect(keychain.passwordCount, equals(0));
  });
}

void _testPasswordManagement() {
  test('should retrieve password for existing server', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    const serverId = 'test-server-id';
    const password = 'test-password';
    
    keychain.addPassword(serverId, password);

    final result = await service.getPassword(serverId);

    expect(result, equals(password));
  });

  test('should return null for non-existent password', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final result = await service.getPassword('non-existent-id');

    expect(result, isNull);
  });

  test('should retrieve server with password', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );
    const password = 'test-password';

    repository.addServer(server);
    keychain.addPassword(server.id, password);

    final (retrievedServer, retrievedPassword) = 
        await service.getServerWithPassword(server.id);

    expect(retrievedServer, isNotNull);
    expect(retrievedServer!.name, equals('Test Server'));
    expect(retrievedPassword, equals(password));
  });

  test('should handle missing server in getServerWithPassword', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final (server, password) = 
        await service.getServerWithPassword('non-existent-id');

    expect(server, isNull);
    expect(password, isNull);
  });

  test('should handle missing password in getServerWithPassword', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );

    repository.addServer(server);
    // No password stored in keychain

    final (retrievedServer, retrievedPassword) = 
        await service.getServerWithPassword(server.id);

    expect(retrievedServer, isNotNull);
    expect(retrievedPassword, isNull);
  });
}