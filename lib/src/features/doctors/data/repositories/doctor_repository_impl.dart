import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/doctors/data/remote/doctor_firebase_api.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/domain/repositories/doctor_repository.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorFirebaseApi _doctorFirebaseApi;

  DoctorRepositoryImpl(this._doctorFirebaseApi);

  @override
  Future<Either<Failure, void>> addDoctor(DoctorModel doctor) async {
    try {
      await _doctorFirebaseApi.addDoctor(doctor);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, DoctorModel>> getDoctor(String doctorId) async {
    try {
      final doctor = await _doctorFirebaseApi.getDoctor(doctorId);
      return Right(doctor);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<DoctorModel>>> getDoctors(
      {String? clinicId}) async {
    try {
      final doctors = await _doctorFirebaseApi.getDoctors(clinicId: clinicId);
      return Right(doctors);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> updateDoctor(
      String doctorId, DoctorModel doctor) async {
    try {
      await _doctorFirebaseApi.updateDoctor(doctorId, doctor);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDoctor(String doctorId) async {
    try {
      await _doctorFirebaseApi.deleteDoctor(doctorId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }
}

