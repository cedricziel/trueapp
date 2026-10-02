import 'package:flutter_test/flutter_test.dart';

import '../helpers/repo_files.dart';

/// The keychain plugins store passwords with `kSecAttrSynchronizable = true`
/// (iCloud Keychain sync). Apple's keychain matching EXCLUDES synchronizable
/// items from any query that does not itself carry a `kSecAttrSynchronizable`
/// key, so every read, update or delete query in the plugin must pass
/// `kSecAttrSynchronizableAny` — otherwise a just-saved password is invisible
/// (errSecItemNotFound) and the app dead-ends on "Authentication Required".
///
/// iOS and macOS share this one source file (`sharedDarwinSource`).
void main() {
  final repo = LocalRepoFileReader();

  const plugins = [
    'packages/truenas_native_plugins/darwin/truenas_native_plugins/Sources/truenas_native_plugins/KeychainPlugin.swift',
  ];

  for (final path in plugins) {
    group(path, () {
      test(
        'every SecItemCopyMatching/SecItemUpdate/SecItemDelete query handles synchronizable items',
        () {
          final source = repo.read(path);
          final callSites = RegExp(
            r'SecItem(CopyMatching|Update|Delete)\(',
          ).allMatches(source).toList();
          expect(
            callSites,
            isNotEmpty,
            reason: 'expected keychain read/update/delete call sites in $path',
          );

          for (final call in callSites) {
            // The query dictionary is declared immediately above its use in
            // this file's style; the preceding window must carry the
            // synchronizable-agnostic match key.
            final windowStart = call.start < 900 ? 0 : call.start - 900;
            final window = source.substring(windowStart, call.start);
            expect(
              window,
              contains('kSecAttrSynchronizableAny'),
              reason:
                  'query for ${call.group(0)} at offset ${call.start} in '
                  '$path does not match synchronizable items — a password '
                  'stored with kSecAttrSynchronizable=true will not be found',
            );
          }
        },
      );
    });
  }
}
