import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/domain/repositories/abstract_inventory_repository.dart';

/// Use case for inventory operations
class InventoryUseCase {
  final AbstractInventoryRepository repository;

  InventoryUseCase(this.repository);

  /// Get all inventory items
  Future<Either<Failure, List<InventoryItemModel>>> getAllItems() {
    return repository.getAllItems();
  }

  /// Get a specific item by ID
  Future<Either<Failure, InventoryItemModel>> getItemById(String id) {
    return repository.getItemById(id);
  }

  /// Add a new item with validation
  Future<Either<Failure, InventoryItemModel>> addItem(
    InventoryItemModel item,
  ) {
    // Business validation
    if (item.quantity < 0) {
      return Future.value(
        Left(ValidationFailure('Quantity cannot be negative')),
      );
    }
    if (item.lowStockThreshold <= 0) {
      return Future.value(
        Left(ValidationFailure('Low stock threshold must be greater than 0')),
      );
    }
    return repository.addItem(item);
  }

  /// Update an item with validation
  Future<Either<Failure, InventoryItemModel>> updateItem(
    String id,
    InventoryItemModel item,
  ) {
    // Business validation
    if (item.quantity < 0) {
      return Future.value(
        Left(ValidationFailure('Quantity cannot be negative')),
      );
    }
    if (item.lowStockThreshold <= 0) {
      return Future.value(
        Left(ValidationFailure('Low stock threshold must be greater than 0')),
      );
    }
    return repository.updateItem(id, item);
  }

  /// Delete an item
  Future<Either<Failure, void>> deleteItem(String id) {
    return repository.deleteItem(id);
  }

  /// Adjust stock with validation
  Future<Either<Failure, void>> adjustStock(
    String id,
    int quantityChange,
    String reason,
  ) async {
    // Validate reason is provided
    if (reason.trim().isEmpty) {
      return Left(
          ValidationFailure('Please provide a reason for stock adjustment'));
    }

    // For removals, check if sufficient stock exists
    if (quantityChange < 0) {
      final itemResult = await repository.getItemById(id);
      return itemResult.fold(
        (failure) => Left(failure),
        (item) {
          if (item.quantity + quantityChange < 0) {
            return Left(ValidationFailure(
              'Insufficient stock. Available: ${item.quantity}, Requested: ${-quantityChange}',
            ));
          }
          return repository.adjustStock(id, quantityChange, reason);
        },
      );
    }

    return repository.adjustStock(id, quantityChange, reason);
  }

  /// Get low stock items
  Future<Either<Failure, List<InventoryItemModel>>> getLowStockItems() {
    return repository.getLowStockItems();
  }

  /// Get deleted items
  Future<Either<Failure, List<InventoryItemModel>>> getDeletedItems() {
    return repository.getDeletedItems();
  }

  /// Restore a deleted item
  Future<Either<Failure, void>> restoreItem(String id) {
    return repository.restoreItem(id);
  }

  /// Permanently delete an item
  Future<Either<Failure, void>> permanentlyDeleteItem(String id) {
    return repository.permanentlyDeleteItem(id);
  }
}
