import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Domain model representing an inventory item
class InventoryItemModel extends Equatable {
  final String? id;
  final String clinicId;
  final String name;
  final String category;
  final int quantity;
  final String unit;
  final int lowStockThreshold;
  final String? supplier;
  final String? supplierContact;
  final double? costPerUnit;
  final Timestamp? lastRestockedAt;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String createdBy;
  final Timestamp? deletedAt;

  const InventoryItemModel({
    this.id,
    required this.clinicId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    this.supplier,
    this.supplierContact,
    this.costPerUnit,
    this.lastRestockedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.deletedAt,
  });

  /// Check if this item is low on stock
  bool get isLowStock => quantity <= lowStockThreshold;

  /// Create from Firestore document
  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as String?,
      clinicId: json['clinicId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String,
      lowStockThreshold: json['lowStockThreshold'] as int,
      supplier: json['supplier'] as String?,
      supplierContact: json['supplierContact'] as String?,
      costPerUnit: json['costPerUnit'] != null
          ? (json['costPerUnit'] as num).toDouble()
          : null,
      lastRestockedAt: json['lastRestockedAt'] as Timestamp?,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
      createdBy: json['createdBy'] as String,
      deletedAt: json['deletedAt'] as Timestamp?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'clinicId': clinicId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
      'supplier': supplier,
      'supplierContact': supplierContact,
      'costPerUnit': costPerUnit,
      'lastRestockedAt': lastRestockedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'deletedAt': deletedAt,
    };
  }

  /// Copy with modification
  InventoryItemModel copyWith({
    String? id,
    String? clinicId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    int? lowStockThreshold,
    String? supplier,
    String? supplierContact,
    double? costPerUnit,
    Timestamp? lastRestockedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
    Timestamp? deletedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      supplier: supplier ?? this.supplier,
      supplierContact: supplierContact ?? this.supplierContact,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clinicId,
        name,
        category,
        quantity,
        unit,
        lowStockThreshold,
        supplier,
        supplierContact,
        costPerUnit,
        lastRestockedAt,
        createdAt,
        updatedAt,
        createdBy,
        deletedAt,
      ];
}
