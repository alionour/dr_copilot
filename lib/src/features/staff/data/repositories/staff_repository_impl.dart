import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/staff/data/remote/staff_firebase_api.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffFirebaseApi _staffFirebaseApi;

  StaffRepositoryImpl(this._staffFirebaseApi);

  @override
  Future<Either<Failure, void>> addStaff(StaffModel staff) async {
    try {
      await _staffFirebaseApi.addStaff(staff);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStaff(String staffId) async {
    try {
      await _staffFirebaseApi.deleteStaff(staffId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<StaffModel>>> getAllStaff(
      {required String clinicId}) async {
    try {
      final staff = await _staffFirebaseApi.getAllStaff(clinicId: clinicId);
      return Right(staff);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> updateStaff(
      String staffId, StaffModel staff) async {
    try {
      await _staffFirebaseApi.updateStaff(staffId, staff);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailTaken(String email,
      {required String clinicId, String? excludeId}) async {
    try {
      final result = await _staffFirebaseApi.isEmailTaken(email,
          clinicId: clinicId, excludeId: excludeId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }
}
