import 'package:bloc_test/bloc_test.dart';

import 'package:dartz/dartz.dart';

import 'package:dr_copilot/src/core/error/failures.dart';

import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';

import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';

import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';

class MockStaffUseCase extends Mock implements StaffUseCases {}

void main() {
  group('StaffBloc', () {
    late StaffBloc staffBloc;

    late MockStaffUseCase mockStaffUseCase;

    setUp(() {
      mockStaffUseCase = MockStaffUseCase();

      staffBloc = StaffBloc(mockStaffUseCase);
    });

    test('initial state is StaffInitial', () {
      expect(staffBloc.state, const StaffInitial([]));
    });

    group('GetStaff', () {
      final tStaffList = [
        const StaffModel(
            id: '1', name: 'Test Staff', role: 'Doctor', clinicId: '1'),
      ];

      const tClinicId = '1';

      blocTest<StaffBloc, StaffState>(
        'emits [StaffLoading, StaffLoaded] when GetStaff is added.',
        build: () {
          when(mockStaffUseCase.getAllStaff(clinicId: tClinicId))
              .thenAnswer((_) async => Right(tStaffList));

          return staffBloc;
        },
        act: (bloc) => bloc.add(const GetStaff(clinicId: tClinicId)),
        expect: () => [
          const StaffLoading([]),
          StaffLoaded(tStaffList),
        ],
      );

      blocTest<StaffBloc, StaffState>(
        'emits [StaffLoading, StaffError] when GetStaff fails.',
        build: () {
          when(mockStaffUseCase.getAllStaff(clinicId: tClinicId))
              .thenAnswer((_) async => Left(ServerFailure('Error', 500)));

          return staffBloc;
        },
        act: (bloc) => bloc.add(const GetStaff(clinicId: tClinicId)),
        expect: () => [
          const StaffLoading([]),
          const StaffError([], message: 'Server Failure: Error'),
        ],
      );
    });
  });
}
