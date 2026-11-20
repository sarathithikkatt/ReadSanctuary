import 'dart:async';
import '../../domain/entities/shelf_entity.dart';
import '../../domain/entities/shelf_item_entity.dart';
import '../../domain/repositories/shelf_repository.dart';
import '../local/daos/shelf_dao.dart';
import '../local/mappers/entity_mappers.dart';

/// Concrete ShelfRepository delegating to Drift ShelfDao.
class ShelfRepositoryImpl implements ShelfRepository {
  final ShelfDao _shelfDao;

  ShelfRepositoryImpl({required ShelfDao shelfDao}) : _shelfDao = shelfDao;

  @override
  Stream<List<ShelfEntity>> watchShelves() {
    return _shelfDao.watchAllShelves().map(
          (shelves) => shelves.map((s) => s.toEntity()).toList(),
        );
  }

  @override
  Future<List<ShelfEntity>> getShelves() async {
    final list = await _shelfDao.getAllShelves();
    return list.map((s) => s.toEntity()).toList();
  }

  @override
  Future<void> upsertShelf(ShelfEntity shelf) async {
    final existing = await _shelfDao.getShelfById(shelf.id);
    if (existing == null) {
      await _shelfDao.insertShelf(shelf.toCompanion());
    } else {
      await _shelfDao.updateShelf(shelf.toCompanion());
    }
  }

  @override
  Future<void> deleteShelf(String shelfId) async {
    await _shelfDao.deleteShelf(shelfId);
  }

  @override
  Future<void> updateShelfOrder(List<String> shelfIdsInOrder) async {
    await _shelfDao.reorderShelves(shelfIdsInOrder);
  }

  @override
  Stream<List<ShelfItemEntity>> watchItemsForShelf(String shelfId) {
    return _shelfDao.watchItemsForShelf(shelfId).map(
          (items) => items.map((i) => i.toEntity()).toList(),
        );
  }

  @override
  Future<void> upsertShelfItem(ShelfItemEntity item) async {
    await _shelfDao.upsertShelfItem(item.toCompanion());
  }

  @override
  Future<void> deleteShelfItem(String itemId) async {
    await _shelfDao.deleteShelfItem(itemId);
  }
}
