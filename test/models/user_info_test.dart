import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/user_info.dart';

void main() {
  group('UserInfo.fromJson', () {
    test('parses a full payload', () {
      final user = UserInfo.fromJson({
        'pw_name': 'admin',
        'pw_gecos': 'Administrator',
        'pw_dir': '/home/admin',
        'pw_shell': '/bin/bash',
        'pw_uid': 1000,
        'pw_gid': 1000,
        'source': 'LOCAL',
        'local': true,
        'grouplist': [1000, 1001],
        'attributes': {'theme': 'dark'},
        'two_factor_config': {'enabled': true},
        'privilege': {
          'allowlist': ['ADMIN'],
        },
      });

      expect(user.username, equals('admin'));
      expect(user.fullName, equals('Administrator'));
      expect(user.homeDirectory, equals('/home/admin'));
      expect(user.shell, equals('/bin/bash'));
      expect(user.uid, equals(1000));
      expect(user.gid, equals(1000));
      expect(user.source, equals('LOCAL'));
      expect(user.isLocal, isTrue);
      expect(user.groupList, equals([1000, 1001]));
      expect(user.attributes, equals({'theme': 'dark'}));
      expect(user.hasTwoFactor, isTrue);
      expect(
        user.privilege,
        equals({
          'allowlist': ['ADMIN'],
        }),
      );
    });

    test('applies defaults for missing/null optional fields', () {
      final user = UserInfo.fromJson({});

      expect(user.username, equals(''));
      expect(user.fullName, equals(''));
      expect(user.homeDirectory, equals(''));
      expect(user.shell, equals(''));
      expect(user.uid, equals(0));
      expect(user.gid, equals(0));
      expect(user.source, equals('LOCAL'));
      expect(user.isLocal, isTrue);
      expect(user.groupList, isEmpty);
      expect(user.attributes, isEmpty);
      expect(user.hasTwoFactor, isFalse);
      expect(user.privilege, isEmpty);
    });

    test('hasTwoFactor is false when two_factor_config is explicitly null', () {
      final user = UserInfo.fromJson({'two_factor_config': null});
      expect(user.hasTwoFactor, isFalse);
    });
  });

  group('UserInfo.displayName', () {
    UserInfo buildUser({String fullName = '', String username = 'admin'}) =>
        UserInfo(
          username: username,
          fullName: fullName,
          homeDirectory: '',
          shell: '',
          uid: 0,
          gid: 0,
          source: 'LOCAL',
          isLocal: true,
          groupList: const [],
          attributes: const {},
          hasTwoFactor: false,
          privilege: const {},
        );

    test('prefers fullName when present', () {
      final user = buildUser(fullName: 'Administrator');
      expect(user.displayName, equals('Administrator'));
    });

    test('falls back to username when fullName is empty', () {
      final user = buildUser(fullName: '');
      expect(user.displayName, equals('admin'));
    });
  });

  group('UserInfo.isAdministrator', () {
    UserInfo buildUser({
      int uid = 1000,
      Map<String, dynamic> privilege = const {},
    }) => UserInfo(
      username: 'user',
      fullName: '',
      homeDirectory: '',
      shell: '',
      uid: uid,
      gid: 0,
      source: 'LOCAL',
      isLocal: true,
      groupList: const [],
      attributes: const {},
      hasTwoFactor: false,
      privilege: privilege,
    );

    test('is true for root (uid 0)', () {
      final user = buildUser(uid: 0);
      expect(user.isAdministrator, isTrue);
    });

    test('is true when privilege allowlist contains ADMIN', () {
      final user = buildUser(
        privilege: {
          'allowlist': ['ADMIN'],
        },
      );
      expect(user.isAdministrator, isTrue);
    });

    test('is true when privilege web_shell is true', () {
      final user = buildUser(privilege: {'web_shell': true});
      expect(user.isAdministrator, isTrue);
    });

    test('is false for a regular non-root user with no admin privilege', () {
      final user = buildUser(uid: 1000, privilege: {});
      expect(user.isAdministrator, isFalse);
    });
  });

  group('UserInfo.sourceDisplayName', () {
    UserInfo buildUser(String source) => UserInfo(
      username: 'user',
      fullName: '',
      homeDirectory: '',
      shell: '',
      uid: 0,
      gid: 0,
      source: source,
      isLocal: true,
      groupList: const [],
      attributes: const {},
      hasTwoFactor: false,
      privilege: const {},
    );

    test('maps LOCAL to Local Account', () {
      expect(buildUser('LOCAL').sourceDisplayName, equals('Local Account'));
    });

    test('maps ACTIVEDIRECTORY to Active Directory', () {
      expect(
        buildUser('ACTIVEDIRECTORY').sourceDisplayName,
        equals('Active Directory'),
      );
    });

    test('maps LDAP to LDAP', () {
      expect(buildUser('LDAP').sourceDisplayName, equals('LDAP'));
    });

    test('is case-insensitive', () {
      expect(buildUser('local').sourceDisplayName, equals('Local Account'));
    });

    test('falls back to the raw source for unknown values', () {
      expect(buildUser('KERBEROS').sourceDisplayName, equals('KERBEROS'));
    });
  });

  group('UserInfo equality', () {
    test('two instances with same fields are equal', () {
      final a = UserInfo.fromJson({'pw_name': 'admin', 'pw_uid': 1000});
      final b = UserInfo.fromJson({'pw_name': 'admin', 'pw_uid': 1000});
      expect(a, equals(b));
    });

    test('a changed field makes instances unequal', () {
      final a = UserInfo.fromJson({'pw_name': 'admin'});
      final b = UserInfo.fromJson({'pw_name': 'other'});
      expect(a == b, isFalse);
    });
  });
}
