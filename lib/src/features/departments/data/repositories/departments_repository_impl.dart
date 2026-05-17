import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';

class DepartmentsRepositoryImpl implements AbstractDepartmentsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<DepartmentModel>>> getDepartments(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('departments')
          .orderBy('name')
          .get();
          
      final departments = snapshot.docs.map((doc) {
        return DepartmentModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
      
      return Right(departments);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, DepartmentModel>> addDepartment(DepartmentModel department) async {
    try {
      if (department.id.isNotEmpty) {
        await _firestore
            .collection('clinics')
            .doc(department.clinicId)
            .collection('departments')
            .doc(department.id)
            .set(department.toJson());
        return Right(department);
      } else {
        final docRef = await _firestore
            .collection('clinics')
            .doc(department.clinicId)
            .collection('departments')
            .add(department.toJson());
            
        return Right(department.copyWith(id: docRef.id));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDepartment(String id, String clinicId) async {
    try {
      await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('departments')
          .doc(id)
          .delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}

extension on DepartmentModel {
  DepartmentModel copyWith({String? id}) {
    return DepartmentModel(
      id: id ?? this.id,
      clinicId: clinicId,
      name: name,
      description: description,
      createdAt: createdAt,
    );
  }
}
