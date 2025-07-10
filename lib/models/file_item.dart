import 'package:equatable/equatable.dart';

class FileItem extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime modifiedTime;
  final String? mimeType;
  final String permissions;
  final String owner;
  final String group;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.modifiedTime,
    this.mimeType,
    required this.permissions,
    required this.owner,
    required this.group,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      path: json['path'] as String,
      isDirectory: json['type'] == 'DIRECTORY',
      size: json['size'] as int? ?? 0,
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(
        (json['modified'] as int? ?? 0) * 1000,
      ),
      mimeType: json['mime_type'] as String?,
      permissions: json['mode'] as String? ?? '',
      owner: json['uid'] as String? ?? '',
      group: json['gid'] as String? ?? '',
    );
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [
    name,
    path,
    isDirectory,
    size,
    modifiedTime,
    mimeType,
    permissions,
    owner,
    group,
  ];
}
