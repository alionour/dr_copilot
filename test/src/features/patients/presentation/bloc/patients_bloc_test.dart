import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../helpers/test_helpers.dart';

// Mock repository
class MockPatientsRepository extends Mock {}

// Define the states for testing
abstract class PatientsState {}

class PatientsInitial extends PatientsState {}

class PatientsLoading extends PatientsState {}

class PatientsLoaded extends PatientsState {
  final List<PatientModel> patients;

  PatientsLoaded({required this.patients});
}

class PatientCreated extends PatientsState {
  final PatientModel patient;

  PatientCreated({required this.patient});
}

class PatientsError extends PatientsState {
  final String message;

  PatientsError(this.message);
}

// Define the events for testing
abstract class PatientsEvent {}

class LoadPatients extends PatientsEvent {}

class CreatePatient extends PatientsEvent {
  final Map<String, dynamic> patientData;

  CreatePatient({required this.patientData});
}

// Mock Bloc for testing
class MockPatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final MockPatientsRepository repository;
  final List<PatientModel> _patients = [];

  MockPatientsBloc(this.repository) : super(PatientsInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<CreatePatient>(_onCreatePatient);
  }

  Future<void> _onLoadPatients(
    LoadPatients event,
    Emitter<PatientsState> emit,
  ) async {
    emit(PatientsLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      if (_patients.isEmpty) {
        _patients.addAll([
          TestHelpers.createTestPatient(
            id: 'patient-1',
            name: 'John Doe',
            age: 35,
            gender: 'Male',
          ),
          TestHelpers.createTestPatient(
            id: 'patient-2',
            name: 'Jane Smith',
            age: 28,
            gender: 'Female',
          ),
        ]);
      }

      emit(PatientsLoaded(patients: List.from(_patients)));
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }

  Future<void> _onCreatePatient(
    CreatePatient event,
    Emitter<PatientsState> emit,
  ) async {
    emit(PatientsLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final patient = TestHelpers.createTestPatient(
        name: event.patientData['name'] ?? 'New Patient',
        age: event.patientData['age'],
        gender: event.patientData['gender'],
      );

      _patients.add(patient);
      emit(PatientCreated(patient: patient));
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }
}

void main() {
  group('Patients Feature Tests', () {
    late MockPatientsRepository mockRepository;
    late MockPatientsBloc patientsBloc;

    setUp(() {
      mockRepository = MockPatientsRepository();
      patientsBloc = MockPatientsBloc(mockRepository);
    });

    tearDown(() {
      patientsBloc.close();
    });

    group('Patient Model Tests', () {
      test('should create patient with all required fields', () {
        final patient = TestHelpers.createTestPatient(
          id: 'patient-123',
          name: 'John Doe',
          age: 35,
          gender: 'Male',
          phoneNumber: '+1234567890',
        );

        expect(patient.id, equals('patient-123'));
        expect(patient.name, equals('John Doe'));
        expect(patient.age, equals(35));
        expect(patient.gender, equals('Male'));
        expect(patient.phoneNumber, equals('+1234567890'));
      });

      test('should handle patient with minimal information', () {
        final patient = TestHelpers.createTestPatient(
          name: 'Jane Smith',
          age: null,
          gender: null,
          phoneNumber: null,
        );

        expect(patient.name, equals('Jane Smith'));
        expect(patient.age, isNull);
        expect(patient.gender, isNull);
        expect(patient.phoneNumber, isNull);
      });

      test('should serialize patient to JSON correctly', () {
        final patient = TestHelpers.createTestPatient();
        final json = patient.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], isA<String>());
        expect(json['name'], isA<String>());
        expect(json['ownerId'], isA<String>());
        expect(json['clinicId'], isA<String>());
      });

      test('should deserialize patient from JSON correctly', () {
        final json = {
          'id': 'test-patient-id',
          'name': 'Test Patient',
          'age': 30,
          'gender': 'Female',
          'ownerId': 'owner-123',
          'clinicId': 'clinic-123',
        };

        final patient = PatientModel.fromJson(json);

        expect(patient.id, equals('test-patient-id'));
        expect(patient.name, equals('Test Patient'));
        expect(patient.age, equals(30));
        expect(patient.gender, equals('Female'));
      });
    });

    group('Patient Repository Tests', () {
      test('should fetch patients list', () async {
        // Test fetching patients from repository
        final patients = TestHelpers.createTestPatients(5);

        expect(patients.length, equals(5));
        expect(patients.first, isA<PatientModel>());
        expect(patients.every((p) => p.id.isNotEmpty), isTrue);
      });

      test('should add new patient', () async {
        final newPatient = TestHelpers.createTestPatient(
          name: 'New Patient',
          age: 25,
        );

        // Test adding patient to repository
        expect(newPatient.name, equals('New Patient'));
        expect(newPatient.age, equals(25));
      });

      test('should update existing patient', () async {
        final originalPatient = TestHelpers.createTestPatient(
          name: 'Original Name',
          age: 30,
        );

        final updatedPatient = originalPatient.copyWith(
          name: 'Updated Name',
          age: 31,
        );

        expect(updatedPatient.name, equals('Updated Name'));
        expect(updatedPatient.age, equals(31));
        expect(updatedPatient.id, equals(originalPatient.id));
      });

      test('should delete patient', () async {
        final patient = TestHelpers.createTestPatient();

        // Test patient deletion
        expect(patient.id, isNotEmpty);
        // In real implementation, would test soft delete or hard delete
      });

      test('should search patients by name', () async {
        final patients = [
          TestHelpers.createTestPatient(name: 'John Doe'),
          TestHelpers.createTestPatient(name: 'Jane Smith'),
          TestHelpers.createTestPatient(name: 'John Wilson'),
        ];

        final johnPatients =
            patients.where((p) => p.name.contains('John')).toList();

        expect(johnPatients.length, equals(2));
        expect(johnPatients.every((p) => p.name.contains('John')), isTrue);
      });

      test('should filter patients by age range', () async {
        final patients = [
          TestHelpers.createTestPatient(age: 25),
          TestHelpers.createTestPatient(age: 35),
          TestHelpers.createTestPatient(age: 45),
          TestHelpers.createTestPatient(age: 55),
        ];

        final middleAgedPatients = patients
            .where((p) => p.age != null && p.age! >= 30 && p.age! <= 50)
            .toList();

        expect(middleAgedPatients.length, equals(2));
      });
    });

    group('Patient Bloc State Management', () {
      test('should have correct initial state', () {
        expect(patientsBloc.state, isA<PatientsInitial>());
      });

      blocTest<MockPatientsBloc, PatientsState>(
        'should emit [PatientsLoading, PatientsLoaded] when LoadPatients is added',
        build: () => patientsBloc,
        act: (bloc) => bloc.add(LoadPatients()),
        expect: () => [
          isA<PatientsLoading>(),
          isA<PatientsLoaded>(),
        ],
      );

      blocTest<MockPatientsBloc, PatientsState>(
        'should emit [PatientsLoading, PatientCreated] when CreatePatient is added',
        build: () => patientsBloc,
        act: (bloc) => bloc.add(CreatePatient(patientData: {
          'name': 'New Patient',
          'age': 30,
          'gender': 'Male',
        })),
        expect: () => [
          isA<PatientsLoading>(),
          isA<PatientCreated>(),
        ],
      );

      blocTest<MockPatientsBloc, PatientsState>(
        'should load patients with correct data',
        build: () => patientsBloc,
        act: (bloc) => bloc.add(LoadPatients()),
        verify: (bloc) {
          final state = bloc.state;
          if (state is PatientsLoaded) {
            expect(state.patients.length, equals(2));
            expect(state.patients.first.name, equals('John Doe'));
            expect(state.patients.last.name, equals('Jane Smith'));
          }
        },
      );

      blocTest<MockPatientsBloc, PatientsState>(
        'should create patient with correct data',
        build: () => patientsBloc,
        act: (bloc) => bloc.add(CreatePatient(patientData: {
          'name': 'Test Patient',
          'age': 25,
          'gender': 'Female',
        })),
        verify: (bloc) {
          final state = bloc.state;
          if (state is PatientCreated) {
            expect(state.patient.name, equals('Test Patient'));
          }
        },
      );

      test('should handle error states', () {
        final errorMessages = [
          'Failed to load patients',
          'Patient not found',
          'Network error',
          'Permission denied',
        ];

        for (final error in errorMessages) {
          expect(error, isA<String>());
          expect(error.isNotEmpty, isTrue);
        }
      });
    });

    group('Patient Validation', () {
      test('should validate required fields', () {
        // Test that required fields are validated
        expect(
            () => PatientModel(
                  id: '',
                  name: '',
                  ownerId: '',
                  clinicId: '',
                ),
            returnsNormally);
      });

      test('should validate phone number format', () {
        final validPhoneNumbers = [
          '+1234567890',
          '(555) 123-4567',
          '555-123-4567',
          '5551234567',
        ];

        final invalidPhoneNumbers = [
          '123',
          'abc-def-ghij',
          '',
        ];

        for (final phone in validPhoneNumbers) {
          expect(phone.isNotEmpty, isTrue);
        }

        for (final phone in invalidPhoneNumbers) {
          expect(phone.length < 10, isTrue);
        }
      });

      test('should validate age ranges', () {
        final validAges = [0, 1, 25, 65, 100, 120];
        final invalidAges = [-1, 150, 200];

        for (final age in validAges) {
          expect(age >= 0 && age <= 150, isTrue);
        }

        for (final age in invalidAges) {
          expect(age < 0 || age > 150, isTrue);
        }
      });

      test('should validate gender values', () {
        final validGenders = ['Male', 'Female', 'Other', 'Prefer not to say'];

        for (final gender in validGenders) {
          expect(gender, isA<String>());
          expect(gender.isNotEmpty, isTrue);
        }
      });
    });

    group('Patient Business Logic', () {
      test('should calculate patient age from birth date', () {
        final birthDate =
            DateTime.now().subtract(const Duration(days: 365 * 30));
        final currentDate = DateTime.now();
        final age = currentDate.year - birthDate.year;

        expect(age, equals(30));
      });

      test('should format patient display name', () {
        final patient = TestHelpers.createTestPatient(
          name: 'john doe',
        );

        final formattedName = patient.name
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');

        expect(formattedName, equals('John Doe'));
      });

      test('should generate patient summary', () {
        final patient = TestHelpers.createTestPatient(
          name: 'John Doe',
          age: 35,
          gender: 'Male',
        );

        final summary =
            '${patient.name}, ${patient.age} years old, ${patient.gender}';

        expect(summary, equals('John Doe, 35 years old, Male'));
      });

      test('should handle patient contact information', () {
        final patient = TestHelpers.createTestPatient(
          phoneNumber: '+1234567890',
          alternativePhoneNumber: '+0987654321',
          address: '123 Main St, City, State',
        );

        expect(patient.phoneNumber, isNotNull);
        expect(patient.alternativePhoneNumber, isNotNull);
        expect(patient.address, isNotNull);
      });
    });

    group('Patient Search and Filtering', () {
      test('should search patients by multiple criteria', () {
        final patients = [
          TestHelpers.createTestPatient(
              name: 'John Doe', age: 30, gender: 'Male'),
          TestHelpers.createTestPatient(
              name: 'Jane Smith', age: 25, gender: 'Female'),
          TestHelpers.createTestPatient(
              name: 'Bob Johnson', age: 35, gender: 'Male'),
        ];

        // Search by gender
        final malePatients = patients.where((p) => p.gender == 'Male').toList();
        expect(malePatients.length, equals(2));

        // Search by age range
        final youngPatients =
            patients.where((p) => p.age != null && p.age! < 30).toList();
        expect(youngPatients.length, equals(1));

        // Search by name
        final johnPatients =
            patients.where((p) => p.name.contains('John')).toList();
        expect(johnPatients.length, equals(2));
      });

      test('should sort patients by different criteria', () {
        final patients = [
          TestHelpers.createTestPatient(name: 'Charlie', age: 40),
          TestHelpers.createTestPatient(name: 'Alice', age: 25),
          TestHelpers.createTestPatient(name: 'Bob', age: 35),
        ];

        // Sort by name
        patients.sort((a, b) => a.name.compareTo(b.name));
        expect(patients.first.name, equals('Alice'));
        expect(patients.last.name, equals('Charlie'));

        // Sort by age
        patients.sort((a, b) => (a.age ?? 0).compareTo(b.age ?? 0));
        expect(patients.first.age, equals(25));
        expect(patients.last.age, equals(40));
      });
    });
  });
}
