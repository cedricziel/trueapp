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