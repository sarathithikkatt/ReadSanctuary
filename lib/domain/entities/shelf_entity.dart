/// Pure Dart domain entity representing a Shelf in ReadSanctuary.
class ShelfEntity {
  final String id;
  final String name;
  final String woodThemeId;
  final String wallThemeId;
  final int sortOrder;
  final int createdAt; // Unix epoch ms
  final int updatedAt; // Unix epoch ms
  final int? deletedAt; // Unix epoch ms for soft delete

  const ShelfEntity({
    required this.id,
    required this.name,
    this.woodThemeId = 'oak',
    this.wallThemeId = 'warm_cream',
    required this.sortOrder,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  ShelfEntity copyWith({
    String? id,
    String? name,
    String? woodThemeId,
    String? wallThemeId,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
  }) {
    return ShelfEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      woodThemeId: woodThemeId ?? this.woodThemeId,
      wallThemeId: wallThemeId ?? this.wallThemeId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelfEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sortOrder == other.sortOrder &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ sortOrder.hashCode ^ updatedAt.hashCode;
}
