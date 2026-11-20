/// Data Transfer Object representing a portable, versioned ReadSanctuary backup snapshot.
class BackupSnapshotDto {
  final int schemaVersion;
  final String appVersion;
  final int exportedAt;
  final String deviceId;
  final Map<String, dynamic> data;

  const BackupSnapshotDto({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.deviceId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'app_version': appVersion,
        'exported_at': exportedAt,
        'device_id': deviceId,
        'data': data,
      };

  factory BackupSnapshotDto.fromJson(Map<String, dynamic> json) {
    return BackupSnapshotDto(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      appVersion: json['app_version']?.toString() ?? '1.2.0',
      exportedAt: (json['exported_at'] as num?)?.toInt() ?? 0,
      deviceId: json['device_id']?.toString() ?? 'unknown-device',
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  List<Map<String, dynamic>> get books =>
      ((data['books'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get shelves =>
      ((data['shelves'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get shelfItems =>
      ((data['shelf_items'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get bookShelves =>
      ((data['book_shelves'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get readingSessions =>
      ((data['reading_sessions'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get bookNotes =>
      ((data['book_notes'] as List<dynamic>?) ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
}
