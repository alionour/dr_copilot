import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';

abstract class DoctorRepository {
  Future<Either<Failure, void>> addDoctor(DoctorModel doctor);
  Future<Either<Failure, DoctorModel>> getDoctor(String doctorId);
  Future<Either<Failure, List<DoctorModel>>> getDoctors({String? clinicId});
  Future<Either<Failure, void>> updateDoctor(String doctorId, DoctorModel doctor);
  Future<Either<Failure, void>> deleteDoctor(String doctorId);
}
