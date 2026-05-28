import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';


/// Dialog for adjusting stock quantities
class AdjustStockDialog extends StatefulWidget {
  final InventoryItemModel item;

  const AdjustStockDialog({super.key, required this.item});

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isAdding = true;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('adjustStock'.tr()),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Stock Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'currentStock'.tr()}: ${widget.item.quantity} ${widget.item.unit}',
                    ),
                    if (widget.item.isLowStock)
                      Row(
                        children: [
                          const Icon(Icons.warning,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'lowStock'.tr(),
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add/Remove Toggle
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('addStock'.tr()),
                    icon: const Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('removeStock'.tr()),
                    icon: const Icon(Icons.remove),
                  ),
                ],
                selected: {_isAdding},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() => _isAdding = selection.first);
                },
              ),
              const SizedBox(height: 20),

              // Quantity Input
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_isAdding ? Icons.add : Icons.remove),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'pleaseEnterQuantity'.tr();
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'invalidQuantity'.tr();
                  }
                  if (!_isAdding && quantity > widget.item.quantity) {
                    return 'insufficientStock'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reason Input
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'reason'.tr(),
                  border: const OutlineInputBorder(),
                  hintText: 'stockAdjustmentHint'.tr(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'pleaseEnterReason'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('cancel').tr(),
        ),
        ElevatedButton(
          onPressed: _adjustStock.throttle(),
          child: const Text('confirm').tr(),
        ),
      ],
    );
  }

  void _adjustStock() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(_quantityController.text);
    final quantityChange = _isAdding ? quantity : -quantity;

    context.read<InventoryBloc>().add(
          AdjustStock(
            itemId: widget.item.id!,
            quantityChange: quantityChange,
            reason: _reasonController.text.trim(),
          ),
        );

    Navigator.of(context).pop();
  }
}
