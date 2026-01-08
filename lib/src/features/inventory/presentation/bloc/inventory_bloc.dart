import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/domain/usecases/inventory_usecase.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

/// BLoC for managing inventory state
class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final InventoryUseCase useCase;

  InventoryBloc(this.useCase) : super(InventoryInitial()) {
    on<LoadInventoryItems>(_onLoadInventoryItems);
    on<LoadLowStockItems>(_onLoadLowStockItems);
    on<AddInventoryItem>(_onAddInventoryItem);
    on<UpdateInventoryItem>(_onUpdateInventoryItem);
    on<DeleteInventoryItem>(_onDeleteInventoryItem);
    on<AdjustStock>(_onAdjustStock);
  }

  Future<void> _onLoadInventoryItems(
    LoadInventoryItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.getAllItems();

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (items) => emit(InventoryLoaded(items)),
    );
  }

  Future<void> _onLoadLowStockItems(
    LoadLowStockItems event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.getLowStockItems();

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (items) => emit(InventoryLoaded(items, isLowStockFilter: true)),
    );
  }

  Future<void> _onAddInventoryItem(
    AddInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.addItem(event.item);

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (_) {
        // Reload items after successful add
        add(LoadInventoryItems());
      },
    );
  }

  Future<void> _onUpdateInventoryItem(
    UpdateInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.updateItem(event.id, event.item);

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (_) {
        // Reload items after successful update
        add(LoadInventoryItems());
      },
    );
  }

  Future<void> _onDeleteInventoryItem(
    DeleteInventoryItem event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.deleteItem(event.id);

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (_) {
        // Reload items after successful delete
        add(LoadInventoryItems());
      },
    );
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());

    final result = await useCase.adjustStock(
      event.itemId,
      event.quantityChange,
      event.reason,
    );

    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (_) {
        // Reload items after successful adjustment
        add(LoadInventoryItems());
      },
    );
  }
}
