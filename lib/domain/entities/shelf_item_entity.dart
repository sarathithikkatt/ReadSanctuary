/// Pure Dart domain entity representing a physical item positioned on a 3D shelf.
class ShelfItemEntity {
  final String id;
  final String shelfId;
  final String itemType; // 'book', 'prop', 'gap'
  final String? bookId;
  final String? propAssetId;
  final String displayMode; // 'spine', 'cover_out', 'stacked'
  final int positionIndex;

  const ShelfItemEntity({
    required this.id,
    required this.shelfId,
    required this.itemType,
    this.bookId,
    this.propAssetId,
    this.displayMode = 'spine',
    required this.positionIndex,
  });

  bool get isBook => itemType == 'book' && bookId != null;
  bool get isProp => itemType == 'prop' && propAssetId != null;
  bool get isGap => itemType == 'gap';

  ShelfItemEntity copyWith({
    String? id,
    String? shelfId,
    String? itemType,
    String? bookId,
    String? propAssetId,
    String? displayMode,
    int? positionIndex,
  }) {
    return ShelfItemEntity(
      id: id ?? this.id,
      shelfId: shelfId ?? this.shelfId,
      itemType: itemType ?? this.itemType,
      bookId: bookId ?? this.bookId,
      propAssetId: propAssetId ?? this.propAssetId,
      displayMode: displayMode ?? this.displayMode,
      positionIndex: positionIndex ?? this.positionIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShelfItemEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          shelfId == other.shelfId &&
          positionIndex == other.positionIndex;

  @override
  int get hashCode => id.hashCode ^ shelfId.hashCode ^ positionIndex.hashCode;
}
