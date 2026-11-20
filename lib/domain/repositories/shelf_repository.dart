import '../entities/shelf_entity.dart';
import '../entities/shelf_item_entity.dart';

/// Abstract repository interface for Shelves and Shelf Items operations.
abstract class ShelfRepository {
  /// Watches all shelves ordered by sortOrder.
  Stream<List<ShelfEntity>> watchShelves();

  /// Retrieves all shelves once.
  Future<List<ShelfEntity>> getShelves();

  /// Inserts or updates a shelf.
  Future<void> upsertShelf(ShelfEntity shelf);

  /// Deletes a shelf.
  Future<void> deleteShelf(String shelfId);

  /// Updates the order of shelves based on ordered list of IDs.
  Future<void> updateShelfOrder(List<String> shelfIdsInOrder);

  /// Watches all items placed on a shelf.
  Stream<List<ShelfItemEntity>> watchItemsForShelf(String shelfId);

  /// Inserts or updates an item on a shelf.
  Future<void> upsertShelfItem(ShelfItemEntity item);

  /// Deletes an item from a shelf.
  Future<void> deleteShelfItem(String itemId);
}
