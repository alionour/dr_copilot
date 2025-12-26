import 'package:google_generative_ai/google_generative_ai.dart';

List<Tool> getGeminiTools({List<String> userRequiredFields = const []}) {
  // Helper to check requirements with backward compatibility
  bool isRequired(String entity, String field) {
    return userRequiredFields.contains('$entity.$field') ||
        (entity == 'patient' && userRequiredFields.contains(field));
  }

  // --- Patient Descriptions ---
  String ageDesc = 'The age of the patient.';
  if (isRequired('patient', 'age')) {
    ageDesc += ' (STRICTLY REQUIRED by User Settings)';
  } else {
    ageDesc += ' (Highly Recommended)';
  }

  String genderDesc = 'The gender of the patient.';
  if (isRequired('patient', 'gender')) {
    genderDesc += ' (STRICTLY REQUIRED by User Settings)';
  } else {
    genderDesc += ' (Highly Recommended)';
  }

  String phoneDesc = 'The phone number.';
  if (isRequired('patient', 'phone')) {
    phoneDesc += ' (STRICTLY REQUIRED by User Settings)';
  } else {
    phoneDesc += ' (Highly Recommended)';
  }

  String addressDesc = 'The address of the patient.';
  if (isRequired('patient', 'address')) {
    addressDesc += ' (STRICTLY REQUIRED by User Settings)';
  }

  String altPhoneDesc = 'The alternative phone number of the patient.';
  if (isRequired('patient', 'alt_phone')) {
    altPhoneDesc += ' (STRICTLY REQUIRED by User Settings)';
  }

  String doctorDesc = 'The treating doctor.';
  if (isRequired('patient', 'doctor')) {
    doctorDesc += ' (STRICTLY REQUIRED by User Settings)';
  }

  String occupationDesc = 'The occupation of the patient.';
  if (isRequired('patient', 'occupation')) {
    occupationDesc += ' (STRICTLY REQUIRED by User Settings)';
  }

  // --- Session Descriptions ---
  String sessionTypeDesc =
      'The type of the session (e.g., \'pediatricIntensive\', \'adultIntensive\', \'standard\', \'traction\').';
  if (isRequired('session', 'type')) {
    sessionTypeDesc += ' (STRICTLY REQUIRED by User Settings)';
  }

  String sessionDoctorDesc =
      'The ID of the doctor for the session. (STRICTLY REQUIRED)';

  // --- Evaluation Descriptions ---
  String evalDoctorDesc =
      'The ID of the doctor for the evaluation. (STRICTLY REQUIRED)';

  // Build required properties lists
  final patientRequired = ['name'];
  if (isRequired('patient', 'age')) patientRequired.add('age');
  if (isRequired('patient', 'gender')) patientRequired.add('gender');
  if (isRequired('patient', 'phone') || isRequired('patient', 'phoneNumber')) {
    patientRequired.add('phoneNumber');
  }
  if (isRequired('patient', 'address')) patientRequired.add('address');
  if (isRequired('patient', 'alt_phone'))
    patientRequired.add('alternativePhoneNumber');
  if (isRequired('patient', 'doctor')) patientRequired.add('treatingDoctor');
  if (isRequired('patient', 'occupation')) patientRequired.add('occupation');

  final sessionRequired = [
    'patientId',
    'price',
    'startDateTime',
    'endDateTime',
    'doctorId'
  ];
  if (isRequired('session', 'type')) sessionRequired.add('sessionType');

  final evalRequired = [
    'patientId',
    'patientName',
    'price',
    'startDateTime',
    'endDateTime',
    'doctorId'
  ];

  return [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'add_patient',
          'Adds a new patient to the system.',
          Schema(
            SchemaType.object,
            properties: {
              'name': Schema(SchemaType.string,
                  description: 'The full name of the patient.'),
              'age': Schema(SchemaType.integer, description: ageDesc),
              'gender': Schema(SchemaType.string, description: genderDesc),
              'address': Schema(SchemaType.string, description: addressDesc),
              'phoneNumber': Schema(SchemaType.string, description: phoneDesc),
              'alternativePhoneNumber':
                  Schema(SchemaType.string, description: altPhoneDesc),
              'treatingDoctor':
                  Schema(SchemaType.string, description: doctorDesc),
              'occupation':
                  Schema(SchemaType.string, description: occupationDesc),
            },
            requiredProperties: patientRequired,
          ),
        ),
        FunctionDeclaration(
          'edit_patient',
          'Edits an existing patient\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the patient to edit.'),
              'name': Schema(SchemaType.string,
                  description: 'The new name of the patient.'),
              'age': Schema(SchemaType.integer,
                  description: 'The new age of the patient.'),
              'gender': Schema(SchemaType.string,
                  description: 'The new gender of the patient.'),
              'address': Schema(SchemaType.string,
                  description: 'The new address of the patient.'),
              'phoneNumber': Schema(SchemaType.string,
                  description: 'The new phone number of the patient.'),
              'alternativePhoneNumber': Schema(SchemaType.string,
                  description:
                      'The new alternative phone number of the patient.'),
              'treatingDoctor': Schema(SchemaType.string,
                  description: 'The new name of the treating doctor.'),
              'occupation': Schema(SchemaType.string,
                  description: 'The new occupation of the patient.'),
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_patient',
          'Deletes a patient from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the patient to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'add_session',
          'Adds a new session for a patient.',
          Schema(
            SchemaType.object,
            properties: {
              'patientId': Schema(SchemaType.string,
                  description:
                      'The ID of the patient for whom the session is being added.'),
              'price': Schema(SchemaType.number,
                  format: 'double', description: 'The price of the session.'),
              'startDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The start date and time of the session in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The end date and time of the session in ISO 8601 format.'),
              'sessionType':
                  Schema(SchemaType.string, description: sessionTypeDesc),
              'patientName': Schema(SchemaType.string,
                  description: 'The name of the patient.'),
              'doctorId':
                  Schema(SchemaType.string, description: sessionDoctorDesc)
            },
            requiredProperties: sessionRequired,
          ),
        ),
        FunctionDeclaration(
          'edit_session',
          'Edits an existing session\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the session to edit.'),
              'patientId': Schema(SchemaType.string,
                  description:
                      'The ID of the patient for whom the session is being updated.'),
              'price': Schema(SchemaType.number,
                  format: 'double',
                  description: 'The new price of the session.'),
              'startDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The new start date and time of the session in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The new end date and time of the session in ISO 8601 format.'),
              'sessionType': Schema(SchemaType.string,
                  description:
                      'The new type of the session (e.g., \'pediatricIntensive\', \'adultIntensive\', \'standard\', \'traction\').'),
              'patientName': Schema(SchemaType.string,
                  description: 'The new name of the patient.'),
              'doctorId': Schema(SchemaType.string,
                  description: 'The new ID of the doctor for the session.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_session',
          'Deletes a session from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the session to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'add_evaluation',
          'Adds a new evaluation for a patient.',
          Schema(
            SchemaType.object,
            properties: {
              'patientId': Schema(SchemaType.string,
                  description:
                      'The ID of the patient for whom the evaluation is being added.'),
              'patientName': Schema(SchemaType.string,
                  description:
                      'The name of the patient for whom the evaluation is being added.'),
              'price': Schema(SchemaType.number,
                  format: 'double',
                  description: 'The price of the evaluation.'),
              'startDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The start date and time of the evaluation in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The end date and time of the evaluation in ISO 8601 format.'),
              'doctorId': Schema(SchemaType.string, description: evalDoctorDesc)
            },
            requiredProperties: evalRequired,
          ),
        ),
        FunctionDeclaration(
          'edit_evaluation',
          'Edits an existing evaluation\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the evaluation to edit.'),
              'patientId': Schema(SchemaType.string,
                  description:
                      'The ID of the patient for whom the evaluation is being updated.'),
              'patientName': Schema(SchemaType.string,
                  description:
                      'The new name of the patient for whom the evaluation is being updated.'),
              'price': Schema(SchemaType.number,
                  format: 'double',
                  description: 'The new price of the evaluation.'),
              'startDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The new start date and time of the evaluation in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string,
                  format: 'date-time',
                  description:
                      'The new end date and time of the evaluation in ISO 8601 format.'),
              'doctorId': Schema(SchemaType.string,
                  description: 'The new ID of the doctor for the evaluation.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_evaluation',
          'Deletes an evaluation from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the evaluation to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'get_patient',
          'Retrieves a patient\'s information by their ID or name.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the patient to retrieve.'),
              'name': Schema(SchemaType.string,
                  description: 'The name of the patient to retrieve.')
            },
          ),
        ),
        FunctionDeclaration(
          'list_patients',
          'Lists patients, optionally filtered by name.',
          Schema(
            SchemaType.object,
            properties: {
              'name': Schema(SchemaType.string,
                  description:
                      'Optional: The name or partial name to filter patients by.')
            },
          ),
        ),
        FunctionDeclaration(
          'get_session',
          'Retrieves a session\'s information by its ID.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the session to retrieve.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'list_sessions',
          'Lists sessions, optionally filtered by patient name or date.',
          Schema(
            SchemaType.object,
            properties: {
              'patientName': Schema(SchemaType.string,
                  description:
                      'Optional: The name or partial name of the patient to filter sessions by.'),
              'date': Schema(SchemaType.string,
                  format: 'date',
                  description:
                      'Optional: The date to filter sessions by (e.g., \'YYYY-MM-DD\').')
            },
          ),
        ),
        FunctionDeclaration(
          'get_evaluation',
          'Retrieves an evaluation\'s information by its ID.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string,
                  description: 'The ID of the evaluation to retrieve.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'list_evaluations',
          'Lists evaluations, optionally filtered by patient name or date.',
          Schema(
            SchemaType.object,
            properties: {
              'patientName': Schema(SchemaType.string,
                  description:
                      'Optional: The name or partial name of the patient to filter evaluations by.'),
              'date': Schema(SchemaType.string,
                  format: 'date',
                  description:
                      'Optional: The date to filter evaluations by (e.g., \'YYYY-MM-DD\').')
            },
          ),
        ),
      ],
    ),
  ];
}
