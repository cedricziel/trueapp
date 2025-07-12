part of 'unified_server_service_test.dart';

/// Integration and advanced scenario tests
void _testDefaultServerManagement() {
  test('should set and retrieve default server', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');

    await service.saveServerConfig(server: server1, password: 'pass1');
    await service.saveServerConfig(server: server2, password: 'pass2');

    // Set server1 as default
    final setResult = await service.setDefaultServer(server1.id);
    expect(setResult, isTrue);

    final defaultServer = await service.getDefaultServer();
    expect(defaultServer, isNotNull);
    expect(defaultServer!.id, equals(server1.id));
    expect(defaultServer.isDefault, isTrue);
  });

  test('should clear default server', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(name: 'Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await service.saveServerConfig(server: server, password: 'pass');
    await service.setDefaultServer(server.id);

    final clearResult = await service.clearDefaultServer();
    expect(clearResult, isTrue);

    final defaultServer = await service.getDefaultServer();
    expect(defaultServer, isNull);
  });

  test('should only have one default server at a time', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');

    await service.saveServerConfig(server: server1, password: 'pass1');
    await service.saveServerConfig(server: server2, password: 'pass2');

    // Set server1 as default
    await service.setDefaultServer(server1.id);
    // Set server2 as default
    await service.setDefaultServer(server2.id);

    final allServers = await service.getAllServers();
    final defaultServers = allServers.where((s) => s.isDefault).toList();
    
    expect(defaultServers.length, equals(1));
    expect(defaultServers.first.id, equals(server2.id));
  });
}

void _testServerRetrieval() {
  test('should retrieve all servers', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');

    await service.saveServerConfig(server: server1, password: 'pass1');
    await service.saveServerConfig(server: server2, password: 'pass2');

    final servers = await service.getAllServers();

    expect(servers.length, equals(2));
    expect(servers.map((s) => s.name), containsAll(['Server 1', 'Server 2']));
  });

  test('should retrieve specific server by id', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await service.saveServerConfig(server: server, password: 'password');

    final retrievedServer = await service.getServer(server.id);

    expect(retrievedServer, isNotNull);
    expect(retrievedServer!.id, equals(server.id));
    expect(retrievedServer.name, equals('Test Server'));
  });

  test('should return null for non-existent server', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = await service.getServer('non-existent-id');

    expect(server, isNull);
  });
}

void _testStreamUpdates() {
  test('should expose servers stream from repository', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final stream = service.serversStream;
    
    expect(stream, isNotNull);
    expect(stream, isA<Stream<List<NasServer>>>());
  });

  test('should support sync operation', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final result = await service.sync();

    expect(result, isTrue);
  });

  test('should handle sync failures', () async {
    final repository = MockServerRepository();
    repository.setShouldFailOperations(true);
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final result = await service.sync();

    expect(result, isFalse);
  });
}

void _testErrorHandling() {
  test('should auto-initialize when operations called before explicit initialization', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    // Don't explicitly initialize

    final server = NasServer.create(name: 'Test', host: '192.168.1.100', username: 'admin', password: 'temp-password');

    // These should succeed due to auto-initialization
    final saveResult = await service.saveServerConfig(server: server, password: 'pass');
    expect(saveResult, isTrue);
    
    final servers = await service.getAllServers();
    expect(servers.length, equals(1));
    
    final retrievedServer = await service.getServer(server.id);
    expect(retrievedServer, isNotNull);
    
    // Service should now be initialized
    expect(service.isInitialized, isTrue);
  });

  test('should handle keychain failures gracefully', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    keychain.setShouldFailOperations(true);
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    final server = NasServer.create(name: 'Test', host: '192.168.1.100', username: 'admin', password: 'temp-password');

    // Should succeed even when keychain fails - server metadata is saved, password can be added later
    final result = await service.saveServerConfig(
      server: server,
      password: 'password',
    );

    expect(result, isTrue); // Metadata save succeeds
    expect(repository.serverCount, equals(1)); // Server is saved
    expect(keychain.passwordCount, equals(0)); // Password is not saved due to keychain failure
    
    // Password retrieval should return null
    final password = await service.getPassword(server.id);
    expect(password, isNull);
  });

  test('should handle repository disposal', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    await service.dispose();

    expect(repository.isInitialized, isFalse);
    expect(keychain.passwordCount, equals(0));
  });
}

void _testIntegrationScenarios() {
  test('should handle complete server lifecycle', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    // Create server
    final server = NasServer.create(
      name: 'Production Server',
      host: 'truenas.example.com',
      username: 'admin',
      password: 'temp-password',
      useHttps: true,
      port: 443,
    );

    // Save server
    final saveResult = await service.saveServerConfig(
      server: server,
      password: 'secure-password',
    );
    expect(saveResult, isTrue);

    // Set as default
    final defaultResult = await service.setDefaultServer(server.id);
    expect(defaultResult, isTrue);

    // Retrieve with password
    final (retrievedServer, password) = 
        await service.getServerWithPassword(server.id);
    expect(retrievedServer, isNotNull);
    expect(password, equals('secure-password'));
    expect(retrievedServer!.isDefault, isTrue);

    // Update server (preserve default status)
    final updatedServer = retrievedServer.copyWith(
      name: 'Updated Production Server',
      port: 8443,
    );
    final updateResult = await service.updateServerConfig(updatedServer);
    expect(updateResult, isTrue);

    // Verify update
    final finalServer = await service.getServer(server.id);
    expect(finalServer!.name, equals('Updated Production Server'));
    expect(finalServer.port, equals(8443));
    expect(finalServer.isDefault, isTrue);

    // Delete server
    final deleteResult = await service.deleteServerConfig(server.id);
    expect(deleteResult, isTrue);

    // Verify deletion
    final deletedServer = await service.getServer(server.id);
    expect(deletedServer, isNull);
    final deletedPassword = await service.getPassword(server.id);
    expect(deletedPassword, isNull);
  });

  test('should handle multiple servers with different configurations', () async {
    final repository = MockServerRepository();
    final keychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    await service.initialize();

    // Create multiple servers
    final servers = [
      NasServer.create(name: 'Home Server', host: '192.168.1.100', port: 80, username: 'admin', password: 'temp-password'),
      NasServer.create(name: 'Office Server', host: '10.0.0.100', port: 443, useHttps: true, username: 'admin', password: 'temp-password'),
      NasServer.create(name: 'Cloud Server', host: 'cloud.example.com', port: 8080, username: 'admin', password: 'temp-password'),
    ];

    // Save all servers
    for (int i = 0; i < servers.length; i++) {
      final result = await service.saveServerConfig(
        server: servers[i],
        password: 'password-$i',
      );
      expect(result, isTrue);
    }

    // Set middle server as default
    await service.setDefaultServer(servers[1].id);

    // Verify all servers exist
    final allServers = await service.getAllServers();
    expect(allServers.length, equals(3));

    // Verify default server
    final defaultServer = await service.getDefaultServer();
    expect(defaultServer!.name, equals('Office Server'));

    // Verify passwords
    for (int i = 0; i < servers.length; i++) {
      final password = await service.getPassword(servers[i].id);
      expect(password, equals('password-$i'));
    }
  });
}