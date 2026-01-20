import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:dr_copilot/src/features/inventory/presentation/widgets/adjust_stock_dialog.dart';

/// Main page for inventory management
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  @override
  void initState() {
    super.initState();
    // Load items on page load
    context.read<InventoryBloc>().add(const LoadInventoryItems());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('inventoryManagement').tr(),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'addItem'.tr(),
            onPressed: () => context.pushNamed('add_inventory'),
          ),
        ],
      ),
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          if (state is InventoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InventoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<InventoryBloc>()
                        .add(const LoadInventoryItems()),
                    child: const Text('retry').tr(),
                  ),
                ],
              ),
            );
          }

          if (state is InventoryLoaded) {
            final items = state.items;
            final lowStockCount = state.lowStockCount;

            return Column(
              children: [
                // Low Stock Warning Banner
                if (lowStockCount > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.shade100,
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'lowStockWarning'.tr(
                                namedArgs: {'count': lowStockCount.toString()}),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context
                              .read<InventoryBloc>()
                              .add(const LoadLowStockItems()),
                          child: Text('viewDetails'.tr()),
                        ),
                      ],
                    ),
                  ),

                // Items List
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('noItemsFound').tr(),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildItemCard(context, item);
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryItemModel item) {
    final isLowStock = item.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isLowStock ? 4 : 1,
      color: isLowStock ? Colors.orange.shade50 : Theme.of(context).cardColor,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLowStock ? Colors.orange : Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(item.category),
            color: Colors.white,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.category} • ${item.supplier ?? 'noSupplier'.tr()}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${'quantity'.tr()}: ${item.quantity} ${item.unit}',
                  style: TextStyle(
                    color: isLowStock ? Colors.orange : null,
                    fontWeight: isLowStock ? FontWeight.bold : null,
                  ),
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value, item),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline),
                  const SizedBox(width: 8),
                  const Text('adjustStock').tr(),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined),
                  const SizedBox(width: 8),
                  const Text('edit').tr(),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('delete'.tr(),
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medication':
        return Icons.medication_outlined;
      case 'equipment':
        return Icons.medical_services_outlined;
      case 'consumables':
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    InventoryItemModel item,
  ) {
    switch (action) {
      case 'adjust':
        _showAdjustStockDialog(context, item);
        break;
      case 'edit':
        context.pushNamed('edit_inventory',
            pathParameters: {'itemId': item.id!}, extra: item);
        break;
      case 'delete':
        _showDeleteConfirmation(context, item);
        break;
    }
  }

  Future<void> _showAdjustStockDialog(
    BuildContext context,
    InventoryItemModel item,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: AdjustStockDialog(item: item),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    InventoryItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('deleteItem').tr(),
        content: const Text('deleteItemConfirmation').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('cancel').tr(),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('delete').tr(),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      if (context.mounted) {
        context.read<InventoryBloc>().add(DeleteInventoryItem(item.id!));
      }
    }
  }
}
