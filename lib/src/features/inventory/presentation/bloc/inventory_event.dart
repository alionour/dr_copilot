part of 'inventory_bloc.dart';

/// Base class for inventory BLoC events
abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load all inventory items
class LoadInventoryItems extends InventoryEvent {
  const LoadInventoryItems();
}

/// Load only low stock items
class LoadLowStockItems extends InventoryEvent {
  const LoadLowStockItems();
}

/// Add a new inventory item
class AddInventoryItem extends InventoryEvent {
  final InventoryItemModel item;

  const AddInventoryItem(this.item);

  @override
  List<Object?> get props => [item];
}

/// Update an existing inventory item
class UpdateInventoryItem extends InventoryEvent {
  final String id;
  final InventoryItemModel item;

  const UpdateInventoryItem(this.id, this.item);

  @override
  List<Object?> get props => [id, item];
}

/// Delete an inventory item
class DeleteInventoryItem extends InventoryEvent {
  final String id;

  const DeleteInventoryItem(this.id);

  @override
  List<Object?> get props => [id];
}

/// Adjust stock quantity
class AdjustStock extends InventoryEvent {
  final String itemId;
  final int quantityChange;
  final String reason;

  const AdjustStock({
    required this.itemId,
    required this.quantityChange,
    required this.reason,
  });

  @override
  List<Object?> get props => [itemId, quantityChange, reason];
}
