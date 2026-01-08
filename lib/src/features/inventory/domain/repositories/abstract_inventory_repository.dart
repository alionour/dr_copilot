import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';

/// Abstract repository for inventory operations
abstract class AbstractInventoryRepository {
  /// Get all inventory items for the current clinic
  Future<Either<Failure, List<InventoryItemModel>>> getAllItems();

  /// Get a specific inventory item by ID
  Future<Either<Failure, InventoryItemModel>> getItemById(String id);

  /// Add a new inventory item
  Future<Either<Failure, InventoryItemModel>> addItem(InventoryItemModel item);

  /// Update an existing inventory item
  Future<Either<Failure, InventoryItemModel>> updateItem(
    String id,
    InventoryItemModel item,
  );

  /// Soft delete an inventory item
  Future<Either<Failure, void>> deleteItem(String id);

  /// Adjust stock quantity (add or remove)
  /// quantityChange can be positive (add) or negative (remove)
  Future<Either<Failure, void>> adjustStock(
    String id,
    int quantityChange,
    String reason,
  );

  /// Get items that are low on stock
  Future<Either<Failure, List<InventoryItemModel>>> getLowStockItems();

  /// Get deleted items (for recycle bin)
  Future<Either<Failure, List<InventoryItemModel>>> getDeletedItems();

  /// Restore a deleted item
  Future<Either<Failure, void>> restoreItem(String id);

  /// Permanently delete an item
  Future<Either<Failure, void>> permanentlyDeleteItem(String id);
}
