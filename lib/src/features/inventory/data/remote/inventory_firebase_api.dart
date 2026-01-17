import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/inventory/domain/models/inventory_item_model.dart';
import 'package:dr_copilot/src/features/inventory/domain/repositories/abstract_inventory_repository.dart';

/// Firebase implementation of InventoryRepository
class InventoryFirebaseApi implements AbstractInventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _itemsCollection =>
      _firestore.collection('inventory_items');

  String? get clinicId => OwnerNotifier().clinicId;

  Future<bool> _isAuthenticated() async {
    return _auth.currentUser != null;
  }

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getAllItems() async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }

      final querySnapshot = await _itemsCollection
          .where('clinicId', isEqualTo: clinicId)
          .where('deletedAt', isNull: true)
          .orderBy('name')
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return InventoryItemModel.fromJson({...data, 'id': doc.id});
      }).toList();

      return Right(items);
    } catch (e) {
      debugPrint('Error fetching inventory items: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, InventoryItemModel>> getItemById(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final doc = await _itemsCollection.doc(id).get();

      if (!doc.exists) {
        return Left(ServerFailure('Item not found', 404));
      }

      final data = doc.data() as Map<String, dynamic>;
      final item = InventoryItemModel.fromJson({...data, 'id': doc.id});

      return Right(item);
    } catch (e) {
      debugPrint('Error fetching inventory item: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, InventoryItemModel>> addItem(
    InventoryItemModel item,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }

      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not found', 401));
      }

      final now = Timestamp.now();
      final newItem = item.copyWith(
        clinicId: clinicId,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
      );

      final docRef = await _itemsCollection.add(newItem.toJson());
      final createdItem = newItem.copyWith(id: docRef.id);

      return Right(createdItem);
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, InventoryItemModel>> updateItem(
    String id,
    InventoryItemModel item,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      final updatedItem = item.copyWith(
        id: id,
        updatedAt: Timestamp.now(),
      );

      await _itemsCollection.doc(id).update(updatedItem.toJson());

      return Right(updatedItem);
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      await _itemsCollection.doc(id).update({
        'deletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return const Right(null);
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> adjustStock(
    String id,
    int quantityChange,
    String reason,
  ) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      // Use Firestore transaction for atomic update
      await _firestore.runTransaction((transaction) async {
        final docRef = _itemsCollection.doc(id);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Item not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentQuantity = data['quantity'] as int;
        final newQuantity = currentQuantity + quantityChange;

        if (newQuantity < 0) {
          throw Exception('Insufficient stock');
        }

        transaction.update(docRef, {
          'quantity': newQuantity,
          'updatedAt': Timestamp.now(),
          if (quantityChange > 0) 'lastRestockedAt': Timestamp.now(),
        });

        // Log the adjustment (optional - could create a separate collection for history)
        debugPrint(
            'Stock adjusted: Item $id, Change: $quantityChange, Reason: $reason');
      });

      return const Right(null);
    } catch (e) {
      debugPrint('Error adjusting stock: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getLowStockItems() async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }

      final querySnapshot = await _itemsCollection
          .where('clinicId', isEqualTo: clinicId)
          .where('deletedAt', isNull: true)
          .get();

      // Filter low stock items in memory (Firestore doesn't support quantity <= threshold query)
      final items = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return InventoryItemModel.fromJson({...data, 'id': doc.id});
          })
          .where((item) => item.isLowStock)
          .toList();

      return Right(items);
    } catch (e) {
      debugPrint('Error fetching low stock items: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, List<InventoryItemModel>>> getDeletedItems() async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }

      final querySnapshot = await _itemsCollection
          .where('clinicId', isEqualTo: clinicId)
          .where('deletedAt', isNull: false)
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return InventoryItemModel.fromJson({...data, 'id': doc.id});
      }).toList();

      return Right(items);
    } catch (e) {
      debugPrint('Error fetching deleted items: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> restoreItem(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      await _itemsCollection.doc(id).update({
        'deletedAt': null,
        'updatedAt': Timestamp.now(),
      });

      return const Right(null);
    } catch (e) {
      debugPrint('Error restoring inventory item: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> permanentlyDeleteItem(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }

    try {
      await _itemsCollection.doc(id).delete();
      return const Right(null);
    } catch (e) {
      debugPrint('Error permanently deleting inventory item: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
