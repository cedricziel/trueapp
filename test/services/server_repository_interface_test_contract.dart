part of 'server_repository_interface_test.dart';

/// Contract tests that any ServerRepositoryInterface implementation should pass
void _testRepositoryContract() {
  test('should initialize successfully', () async {
    final repository = MockServerRepositoryImplementation();
    
    final result = await repository.initialize();
    
    expect(result, isTrue);
    expect(repository.isInitialized, isTrue);
  });

  test('should fail operations when not initialized', () async {
    final repository = MockServerRepositoryImplementation();
    
    expect(
      () => repository.getAllServers(),
      throwsA(isA<StateError>()),
    );
    
    expect(
      () => repository.getServer('test'),
      throwsA(isA<StateError>()),
    );
  });

  test('should handle initialization failure', () async {
    final repository = MockServerRepositoryImplementation();
    repository.setShouldFailOperations(true);
    
    final result = await repository.initialize();
    
    expect(result, isFalse);
  });

  test('should provide capability information', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    expect(repository.supportsOfflineAccess, isA<bool>());
    expect(repository.supportsAutoSync, isA<bool>());
  });
}

void _testServerOperations() {
  test('should save and retrieve servers', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'temp-password',
    );
    
    final saveResult = await repository.saveServer(server);
    expect(saveResult, isTrue);
    
    final retrievedServer = await repository.getServer(server.id);
    expect(retrievedServer, isNotNull);
    expect(retrievedServer!.name, equals('Test Server'));
    expect(retrievedServer.host, equals('192.168.1.100'));
  });

  test('should return null for non-existent server', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = await repository.getServer('non-existent');
    
    expect(server, isNull);
  });

  test('should get all servers', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');
    
    await repository.saveServer(server1);
    await repository.saveServer(server2);
    
    final servers = await repository.getAllServers();
    
    expect(servers.length, equals(2));
    expect(servers.map((s) => s.name), containsAll(['Server 1', 'Server 2']));
  });

  test('should delete servers', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await repository.saveServer(server);
    
    final deleteResult = await repository.deleteServer(server.id);
    expect(deleteResult, isTrue);
    
    final retrievedServer = await repository.getServer(server.id);
    expect(retrievedServer, isNull);
    
    final allServers = await repository.getAllServers();
    expect(allServers, isEmpty);
  });

  test('should return false when deleting non-existent server', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final result = await repository.deleteServer('non-existent');
    
    expect(result, isFalse);
  });
}

void _testDefaultServerManagement() {
  test('should set and get default server', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = NasServer.create(name: 'Default Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await repository.saveServer(server);
    
    final setResult = await repository.setDefaultServer(server.id);
    expect(setResult, isTrue);
    
    final defaultServer = await repository.getDefaultServer();
    expect(defaultServer, isNotNull);
    expect(defaultServer!.id, equals(server.id));
    expect(defaultServer.isDefault, isTrue);
  });

  test('should return null when no default server set', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final defaultServer = await repository.getDefaultServer();
    
    expect(defaultServer, isNull);
  });

  test('should clear default server', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await repository.saveServer(server);
    await repository.setDefaultServer(server.id);
    
    final clearResult = await repository.clearDefaultServer();
    expect(clearResult, isTrue);
    
    final defaultServer = await repository.getDefaultServer();
    expect(defaultServer, isNull);
  });

  test('should only allow one default server', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');
    
    await repository.saveServer(server1);
    await repository.saveServer(server2);
    
    await repository.setDefaultServer(server1.id);
    await repository.setDefaultServer(server2.id);
    
    final defaultServer = await repository.getDefaultServer();
    expect(defaultServer!.id, equals(server2.id));
    
    final allServers = await repository.getAllServers();
    final defaultServers = allServers.where((s) => s.isDefault).toList();
    expect(defaultServers.length, equals(1));
  });

  test('should clear default when default server is deleted', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await repository.saveServer(server);
    await repository.setDefaultServer(server.id);
    
    await repository.deleteServer(server.id);
    
    final defaultServer = await repository.getDefaultServer();
    expect(defaultServer, isNull);
  });
}

void _testStreamBehavior() {
  test('should provide servers stream', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final stream = repository.serversStream;
    
    expect(stream, isA<Stream<List<NasServer>>>());
  });

  test('should emit servers on stream when servers change', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final streamEvents = <List<NasServer>>[];
    final subscription = repository.serversStream.listen(streamEvents.add);
    
    // Wait for initial empty list
    await Future.delayed(const Duration(milliseconds: 10));
    
    final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
    await repository.saveServer(server);
    
    // Wait for stream event
    await Future.delayed(const Duration(milliseconds: 10));
    
    expect(streamEvents.length, greaterThanOrEqualTo(1));
    expect(streamEvents.last.length, equals(1));
    expect(streamEvents.last.first.name, equals('Test Server'));
    
    await subscription.cancel();
  });
}

void _testSyncOperations() {
  test('should support sync operation', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    
    final result = await repository.sync();
    
    expect(result, isA<bool>());
  });

  test('should handle sync failures', () async {
    final repository = MockServerRepositoryImplementation();
    await repository.initialize();
    repository.setShouldFailOperations(true);
    
    final result = await repository.sync();
    
    expect(result, isFalse);
  });
}