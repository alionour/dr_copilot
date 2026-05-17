import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

/// Page for adding or editing inventory items
class AddEditInventoryPage extends StatefulWidget {
  final InventoryItemModel? item;

  const AddEditInventoryPage({super.key, this.item});

  @override
  State<AddEditInventoryPage> createState() => _AddEditInventoryPageState();
}

class _AddEditInventoryPageState extends State<AddEditInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _thresholdController;
  late TextEditingController _supplierController;
  late TextEditingController _contactController;
  late TextEditingController _costController;

  String _selectedCategory = 'Consumables';
  final List<String> _categories = ['Consumables', 'Medication', 'Equipment'];

  @override
  void initState() {
    super.initState();
    final item = widget.item;

    _nameController = TextEditingController(text: item?.name);
    _quantityController =
        TextEditingController(text: item?.quantity.toString());
    _unitController = TextEditingController(text: item?.unit ?? 'pieces');
    _thresholdController =
        TextEditingController(text: item?.lowStockThreshold.toString());
    _supplierController = TextEditingController(text: item?.supplier);
    _contactController = TextEditingController(text: item?.supplierContact);
    _costController =
        TextEditingController(text: item?.costPerUnit?.toString());

    if (item != null) {
      _selectedCategory = item.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _thresholdController.dispose();
    _supplierController.dispose();
    _contactController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'editItem'.tr() : 'addItem'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'itemName'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'pleaseEnterItemName'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'category'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'quantity'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'pleaseEnterQuantity'.tr();
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'invalidQuantity'.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'unit'.tr(),
                        border: const OutlineInputBorder(),
                        hintText: 'pieces, boxes, vials',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'pleaseEnterUnit'.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                decoration: InputDecoration(
                  labelText: 'lowStockThreshold'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'pleaseEnterThreshold'.tr();
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'thresholdMustBePositive'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _supplierController,
                decoration: InputDecoration(
                  labelText: '${'supplier'.tr()} (${'optional'.tr()})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: '${'supplierContact'.tr()} (${'optional'.tr()})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: '${'costPerUnit'.tr()} (${'optional'.tr()})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                child: Text(isEdit ? 'save'.tr() : 'add'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = Timestamp.now();
    final user = FirebaseAuth.instance.currentUser;
    final clinicId = OwnerNotifier().clinicId;

    if (user == null || clinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectionArea(child: Text('Authentication error'))),
      );
      return;
    }

    final item = InventoryItemModel(
      id: widget.item?.id,
      clinicId: clinicId,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      quantity: int.parse(_quantityController.text),
      unit: _unitController.text.trim(),
      lowStockThreshold: int.parse(_thresholdController.text),
      supplier: _supplierController.text.trim().isNotEmpty
          ? _supplierController.text.trim()
          : null,
      supplierContact: _contactController.text.trim().isNotEmpty
          ? _contactController.text.trim()
          : null,
      costPerUnit: _costController.text.isNotEmpty
          ? double.tryParse(_costController.text)
          : null,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.item?.createdBy ?? user.uid,
    );

    if (widget.item != null && widget.item!.id != null) {
      context
          .read<InventoryBloc>()
          .add(UpdateInventoryItem(widget.item!.id!, item));
    } else {
      context.read<InventoryBloc>().add(AddInventoryItem(item));
    }

    context.pop();
  }
}
