import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/inventory/data/remote/inventory_firebase_api.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/domain/repositories/abstract_inventory_repository.dart';

/// Repository implementation that delegates to Firebase API
class InventoryRepositoryImpl implements AbstractInventoryRepository {
  final InventoryFirebaseApi firebaseApi;

  InventoryRepositoryImpl(this.firebaseApi);

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getAllItems() {
    return firebaseApi.getAllItems();
  }

  @override
  Future<Either<Failure, InventoryItemModel>> getItemById(String id) {
    return firebaseApi.getItemById(id);
  }

  @override
  Future<Either<Failure, InventoryItemModel>> addItem(InventoryItemModel item) {
    return firebaseApi.addItem(item);
  }

  @override
  Future<Either<Failure, InventoryItemModel>> updateItem(
    String id,
    InventoryItemModel item,
  ) {
    return firebaseApi.updateItem(id, item);
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) {
    return firebaseApi.deleteItem(id);
  }

  @override
  Future<Either<Failure, void>> adjustStock(
    String id,
    int quantityChange,
    String reason,
  ) {
    return firebaseApi.adjustStock(id, quantityChange, reason);
  }

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getLowStockItems() {
    return firebaseApi.getLowStockItems();
  }

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getDeletedItems() {
    return firebaseApi.getDeletedItems();
  }

  @override
  Future<Either<Failure, void>> restoreItem(String id) {
    return firebaseApi.restoreItem(id);
  }

  @override
  Future<Either<Failure, void>> permanentlyDeleteItem(String id) {
    return firebaseApi.permanentlyDeleteItem(id);
  }
}
