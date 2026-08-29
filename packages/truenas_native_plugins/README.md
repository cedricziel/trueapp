# truenas_native_plugins

Native iOS/macOS plugins for the TrueNAS Manager app, providing Keychain
password storage and CloudKit metadata sync behind Dart interfaces. Extracted
from the app in [#53](https://github.com/cedricziel/trueapp/issues/53) so the
native layer could be reused, tested, and possibly published independently.

The package follows Apple's two-layer storage pattern: server **passwords**
live in the Keychain (`KeychainServiceInterface`), while non-secret server
**metadata** — host, port, display name, and the rest of
[`ServerConfigDTO`](#serverconfigdto) — syncs across a user's devices via
CloudKit (`CloudKitServiceInterface`). The two are joined by the server's
UUID: it is both the Keychain account and the CloudKit record ID.

## Installation

Add it as a path dependency:

```yaml
dependencies:
  truenas_native_plugins:
    path: packages/truenas_native_plugins
```

Requirements (from the package's own `pubspec.yaml`):

- Dart `>=3.0.0 <4.0.0`, Flutter `>=3.10.0`
- Current package version: `0.1.0`

Supported platforms (from the podspecs): iOS 12.0+ and macOS 10.14+. The
TrueNAS Manager host app itself targets a higher floor, iOS 16.6, set in its
own `Podfile` — that is a decision the app makes, not a constraint imposed by
this package.

Plugin registration is automatic: `pubspec.yaml`'s `flutter: plugin:
platforms:` block registers `TruenasNativePlugins` as the `pluginClass` for
both `ios` and `macos`, which wires up the native `CloudKitPlugin` and
`KeychainPlugin` implementations. No manual registration step is needed.

## Usage — Keychain

`KeychainServiceInterface` declares six methods:

```dart
abstract class KeychainServiceInterface {
  Future<bool> storePassword({required String serverId, required String password});
  Future<String?> getPassword({required String serverId});
  Future<bool> deletePassword({required String serverId});
  Future<bool> hasPassword({required String serverId});
  Future<List<String>> getAllServerIds();
  Future<bool> deleteAllPasswords();
}
```

`NativeKeychainService` implements it over Apple's Security framework via a
`MethodChannel` named `<channelPrefix>/keychain` (default channel prefix
`com.cedricziel.truehub`, so `com.cedricziel.truehub/keychain`):

```dart
import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;

// Or use the shared singleton: plugins.NativeKeychainService.instance
final keychain = plugins.NativeKeychainService(
  channelPrefix: 'com.cedricziel.truehub', // default
  serviceIdentifier: 'com.cedricziel.truehub.server', // default
);

final stored = await keychain.storePassword(serverId: server.id, password: password);
final password = await keychain.getPassword(serverId: server.id);
```

Behaviour worth knowing before you rely on it:

- Every method short-circuits to a falsy result (`false`, `null`, or `[]`) on
  any platform other than iOS/macOS — there is no native implementation
  elsewhere, and this is intentional rather than an error.
- Every method catches its own errors internally and converts them to the
  same falsy result. **None of these methods throw.**
- Items are stored as `kSecClassGenericPassword`, keyed by service (the
  `serviceIdentifier`) and account (`serverId` — the same UUID used as the
  CloudKit record ID). They are written with `kSecAttrSynchronizable = true`
  and `kSecAttrAccessibleWhenUnlocked` so they ride iCloud Keychain and stay
  unavailable before the device is unlocked.

## Usage — CloudKit

`CloudKitServiceInterface`:

```dart
abstract class CloudKitServiceInterface {
  Stream<List<ServerConfigDTO>> get serverConfigsStream;
  bool get isInitialized;
  Future<bool> initialize();
  Future<bool> isAvailable();
  Future<bool> saveServerConfig(ServerConfigDTO config);
  Future<bool> updateServerConfig(ServerConfigDTO config);
  Future<List<ServerConfigDTO>> fetchServerConfigs();
  Future<bool> deleteServerConfig(String serverId);
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  void dispose();
}
```

`NativeCloudKitService` implements it using a `MethodChannel` named
`<channelPrefix>/cloudkit` and an `EventChannel` named
`<channelPrefix>/cloudkit_events` (default prefix `com.cedricziel.truehub`,
so `com.cedricziel.truehub/cloudkit` and
`com.cedricziel.truehub/cloudkit_events`), against the CKContainer
`iCloud.com.cedricziel.truehub`.

**`initialize()` must be awaited before anything else works.** Every other
method returns `false` (or `[]` for `fetchServerConfigs`) while
`isInitialized` is `false`; `initialize()` itself returns `false` on a
non-Apple platform without throwing.

```dart
final cloudKit = plugins.NativeCloudKitService(); // or .instance

if (await cloudKit.initialize()) {
  final subscription = cloudKit.serverConfigsStream.listen((configs) {
    // reacts to remote changes pushed by the serverConfigsUpdated event
  });

  await cloudKit.startMonitoring();
  await cloudKit.saveServerConfig(config);

  // ...later, when you're done with the service:
  await cloudKit.stopMonitoring();
  await subscription.cancel();
  cloudKit.dispose();
}
```

`serverConfigsStream` is a broadcast stream that emits whenever the native
side reports a `serverConfigsUpdated` event on the underlying event channel.
A `syncError` event is logged (in debug mode) but does **not** appear on the
stream as an error — the stream only carries successful config lists.
`dispose()` cancels the native event subscription, closes the stream
controller, and stops monitoring; call it when you are done with the
service, mirroring the `StreamSubscription.cancel()` obligation above it.

## ServerConfigDTO

`ServerConfigDTO` carries only non-secret server metadata — **it never
carries a password**; that is the Keychain's job, keyed by the same `id`:

```dart
class ServerConfigDTO {
  final String id; // UUID, shared with the Keychain account
  final String displayName;
  final String hostName;
  final String userName;
  final bool useHttps;
  final bool allowUntrustedCertificates;
  final int? port;
  final String? localUrl;
  final List<String> trustedWifiSsids;
  final DateTime? lastConnected;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ...
}
```

It provides `toJson()` / `ServerConfigDTO.fromJson()` for the CloudKit wire
format, and `copyWith()` for building updated copies.

## Testing

`MockKeychainService` and `MockCloudKitService` implement the same
interfaces as their native counterparts, so any code written against
`KeychainServiceInterface` / `CloudKitServiceInterface` can take a mock via
constructor injection in tests, with no platform channel involved:

```dart
final keychain = plugins.MockKeychainService()
  ..addPassword('server-1', 's3cret');

expect(await keychain.hasPassword(serverId: 'server-1'), isTrue);
```

Control knobs on the mocks:

- `MockKeychainService`: `setShouldFailOperations(bool)`,
  `setOperationDelay(int ms)`, `addPassword(String, String)`,
  `clearPasswords()`, `passwordCount`, `hasStoredPassword(String)`,
  `getStoredPassword(String)`, `allPasswords`.
- `MockCloudKitService`: `setShouldFailOperations(bool)`,
  `setIsAvailable(bool)`, `setOperationDelay(int ms)`,
  `addMockConfig(ServerConfigDTO)`, `clearMockConfigs()`,
  `simulateRemoteUpdate(List<ServerConfigDTO>)`,
  `simulateSyncError(String)`, `mockConfigCount`, `isMonitoring`.

`TruenasPluginTestHelpers` offers two levels of test double:

```dart
// Pre-configured mock instances (no platform channel involved):
final keychain = TruenasPluginTestHelpers.createMockKeychainService(
  shouldFailOperations: false,
  operationDelay: 0,
  initialPasswords: {'server-1': 's3cret'},
);
final cloudKit = TruenasPluginTestHelpers.createMockCloudKitService(
  isInitialized: true,
  isAvailable: true,
);

// Or, to exercise the real NativeKeychainService / NativeCloudKitService
// over a faked platform channel instead of a mock class:
TruenasPluginTestHelpers.setupMethodChannelMocks(
  channelPrefix: 'com.cedricziel.truehub',
  keychainResponses: {'storePassword': true},
  cloudKitResponses: {'initialize': true},
);
// ... run the test against NativeKeychainService()/NativeCloudKitService() ...
TruenasPluginTestHelpers.tearDownMethodChannelMocks();
```

**Caveat:** the mocks and `TruenasPluginTestHelpers` live under
`lib/src/test_utils/` and are exported from the package's main entrypoint
(`lib/truenas_native_plugins.dart`), which is the reason `flutter_test` is a
regular `dependencies` entry in this package's `pubspec.yaml` rather than a
`dev_dependencies` one. That is a real cost for anyone consuming this package
purely as a production dependency (and a blocker if it is ever published to
pub.dev, where `flutter_test` cannot resolve as a runtime dependency of a
published package). A follow-up to split the test utilities into a separate
entrypoint or companion package would remove it.

The package's own test suite lives under `packages/truenas_native_plugins/test/`
and is run from within the package directory:

```sh
cd packages/truenas_native_plugins
flutter test
```

It is **not** currently exercised by the root `flutter test` command or by
CI — only tests under the repository's top-level `test/` directory are.

## Entitlements

Neither platform's native code sets `kSecAttrAccessGroup` on Keychain items,
so items always land in the app's default keychain access group regardless
of what is declared below — the entitlements exist for the CloudKit
container grant, not to establish a shared Keychain group between processes.

**iOS** (`ios/Runner/Runner.entitlements`, see the host app for a worked
example):

- `com.apple.developer.icloud-container-identifiers`:
  `["iCloud.com.cedricziel.truehub"]`
- `com.apple.developer.icloud-services`: `["CloudKit"]`
- `keychain-access-groups`

**macOS** (`macos/Runner/DebugProfile.entitlements` and
`Release.entitlements`), the same two iCloud keys, plus (under App Sandbox):

- `com.apple.security.app-sandbox`
- `com.apple.security.network.client`
- `com.apple.security.application-groups`:
  `["$(AppIdentifierPrefix)com.cedricziel.truehub.shared"]`
- `keychain-access-groups`

## Migration notes (for code written before #53)

Before the extraction, Keychain and CloudKit access lived directly in the
app. After it:

- `lib/services/native_keychain_service.dart` and
  `lib/services/cloudkit_service.dart` in the app are now thin facades that
  delegate to `plugins.NativeKeychainService` and
  `plugins.NativeCloudKitService` from this package.
- The app keeps its own `ServerConfigDTO`
  (`lib/models/server_config_dto.dart`) and bridges it to this package's DTO
  with `ServerConfigDTO.toPlugin()` / `ServerConfigDTO.fromPlugin()` — the
  two types share a name but are not the same class.
- Because of that name collision, app code imports this package with an `as
  plugins` prefix (see `native_keychain_service.dart` and
  `cloudkit_service.dart` above for the pattern).
- Tests bridge this package's `MockCloudKitService` to the app's own
  `CloudKitServiceInterface` via
  `test/helpers/mock_cloudkit_service_adapter.dart` in the app's test suite.
- `NativeKeychainService.debugGetPasswordWithOldPattern` on the app-side
  facade is a stub that always returns `null` — it existed to check for
  passwords under the pre-extraction `flutter_secure_storage` key pattern,
  and that lookup did not survive the extraction.

## License

AGPL-3.0, at [`LICENSE`](./LICENSE) in this package's root, referenced by
both `ios/truenas_native_plugins.podspec` and
`macos/truenas_native_plugins.podspec` via `s.license = { :file =>
'../LICENSE' }`.
