import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/file_item.dart';

void main() {
  group('FileItem.fromJson', () {
    test('parses a full directory payload', () {
      final item = FileItem.fromJson({
        'name': 'documents',
        'path': '/mnt/pool/documents',
        'type': 'DIRECTORY',
        'size': 4096,
        'modified': 1700000000,
        'mime_type': 'inode/directory',
        'mode': '0755',
        'uid': 'root',
        'gid': 'wheel',
      });

      expect(item.name, equals('documents'));
      expect(item.path, equals('/mnt/pool/documents'));
      expect(item.isDirectory, isTrue);
      expect(item.size, equals(4096));
      expect(
        item.modifiedTime,
        equals(DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000)),
      );
      expect(item.mimeType, equals('inode/directory'));
      expect(item.permissions, equals('0755'));
      expect(item.owner, equals('root'));
      expect(item.group, equals('wheel'));
    });

    test('isDirectory is false for a non-DIRECTORY type', () {
      final item = FileItem.fromJson({
        'name': 'file.txt',
        'path': '/mnt/pool/file.txt',
        'type': 'FILE',
      });
      expect(item.isDirectory, isFalse);
    });

    test('applies defaults for missing optional fields', () {
      final item = FileItem.fromJson({
        'name': 'file.txt',
        'path': '/mnt/pool/file.txt',
      });

      expect(item.isDirectory, isFalse);
      expect(item.size, equals(0));
      expect(item.modifiedTime, equals(DateTime.fromMillisecondsSinceEpoch(0)));
      expect(item.mimeType, isNull);
      expect(item.permissions, equals(''));
      expect(item.owner, equals(''));
      expect(item.group, equals(''));
    });
  });

  group('FileItem.formattedSize', () {
    DateTime epoch() => DateTime.fromMillisecondsSinceEpoch(0);

    FileItem withSize(int size) => FileItem(
      name: 'f',
      path: '/f',
      isDirectory: false,
      size: size,
      modifiedTime: epoch(),
      permissions: '',
      owner: '',
      group: '',
    );

    test('formats bytes below 1024 as B', () {
      expect(withSize(500).formattedSize, equals('500 B'));
    });

    test('formats sizes below 1 MB as KB', () {
      expect(withSize(2048).formattedSize, equals('2.0 KB'));
    });

    test('formats sizes below 1 GB as MB', () {
      expect(withSize(5 * 1024 * 1024).formattedSize, equals('5.0 MB'));
    });

    test('formats sizes at or above 1 GB as GB', () {
      expect(withSize(3 * 1024 * 1024 * 1024).formattedSize, equals('3.0 GB'));
    });

    test('boundary at exactly 1024 bytes rolls over to KB', () {
      expect(withSize(1024).formattedSize, equals('1.0 KB'));
    });

    test('boundary at exactly 1 MB rolls over to MB', () {
      expect(withSize(1024 * 1024).formattedSize, equals('1.0 MB'));
    });

    test('boundary at exactly 1 GB rolls over to GB', () {
      expect(withSize(1024 * 1024 * 1024).formattedSize, equals('1.0 GB'));
    });
  });

  group('FileItem equality', () {
    test('two instances with identical fields are equal', () {
      final a = FileItem.fromJson({
        'name': 'f',
        'path': '/f',
        'type': 'FILE',
        'size': 10,
        'modified': 1000,
      });
      final b = FileItem.fromJson({
        'name': 'f',
        'path': '/f',
        'type': 'FILE',
        'size': 10,
        'modified': 1000,
      });
      expect(a, equals(b));
    });

    test('a changed field makes instances unequal', () {
      final a = FileItem.fromJson({
        'name': 'f',
        'path': '/f',
        'type': 'FILE',
        'size': 10,
      });
      final b = FileItem.fromJson({
        'name': 'f',
        'path': '/f',
        'type': 'FILE',
        'size': 20,
      });
      expect(a == b, isFalse);
    });
  });
}
