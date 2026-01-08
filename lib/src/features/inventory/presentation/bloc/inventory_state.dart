part of 'inventory_bloc.dart';

/// Base class for inventory BLoC states
abstract class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class InventoryInitial extends InventoryState {}

/// Loading state
class InventoryLoading extends InventoryState {}

/// Loaded state with items
class InventoryLoaded extends InventoryState {
  final List<InventoryItemModel> items;
  final bool isLowStockFilter;

  const InventoryLoaded(this.items, {this.isLowStockFilter = false});

  /// Get count of low stock items
  int get lowStockCount => items.where((item) => item.isLowStock).length;

  @override
  List<Object?> get props => [items, isLowStockFilter];
}

/// Error state
class InventoryError extends InventoryState {
  final String message;

  const InventoryError(this.message);

  @override
  List<Object?> get props => [message];
}
