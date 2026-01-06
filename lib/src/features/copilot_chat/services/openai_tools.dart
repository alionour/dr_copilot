// OpenAI-compatible tool definitions for function calling
// Used by Groq, GPT, DeepSeek, and other OpenAI-compatible APIs

List<Map<String, dynamic>> getOpenAITools(
    {List<String> userRequiredFields = const []}) {
  // Helper to check requirements with backward compatibility
  bool isRequired(String entity, String field) {
    return userRequiredFields.contains('$entity.$field') ||
        (entity == 'patient' && userRequiredFields.contains(field));
  }

  // Build required properties lists
  final patientRequired = ['name'];
  if (isRequired('patient', 'age')) patientRequired.add('age');
  if (isRequired('patient', 'gender')) patientRequired.add('gender');
  if (isRequired('patient', 'phone') || isRequired('patient', 'phoneNumber')) {
    patientRequired.add('phoneNumber');
  }

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
    {
      'type': 'function',
      'function': {
        'name': 'add_patient',
        'description': 'Adds a new patient to the system.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description': 'The full name of the patient.'
            },
            'age': {
              'type': 'integer',
              'description': 'The age of the patient.'
            },
            'gender': {
              'type': 'string',
              'description': 'The gender of the patient.'
            },
            'address': {
              'type': 'string',
              'description': 'The address of the patient.'
            },
            'phoneNumber': {
              'type': 'string',
              'description': 'The phone number of the patient.'
            },
            'alternativePhoneNumber': {
              'type': 'string',
              'description': 'The alternative phone number.'
            },
            'treatingDoctor': {
              'type': 'string',
              'description': 'The treating doctor.'
            },
            'occupation': {
              'type': 'string',
              'description': 'The occupation of the patient.'
            },
          },
          'required': patientRequired,
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'edit_patient',
        'description': "Edits an existing patient's information.",
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the patient to edit.'
            },
            'name': {
              'type': 'string',
              'description': 'The new name of the patient.'
            },
            'age': {
              'type': 'integer',
              'description': 'The new age of the patient.'
            },
            'gender': {
              'type': 'string',
              'description': 'The new gender of the patient.'
            },
            'address': {
              'type': 'string',
              'description': 'The new address of the patient.'
            },
            'phoneNumber': {
              'type': 'string',
              'description': 'The new phone number.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_patient',
        'description': 'Deletes a patient from the system.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the patient to delete.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_patients',
        'description': 'Lists patients, optionally filtered by name.',
        'parameters': {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'description':
                  'Optional: The name or partial name to filter patients by.'
            },
            'startDate': {
              'type': 'string',
              'description': 'Optional: Start date filter (YYYY-MM-DD).'
            },
            'endDate': {
              'type': 'string',
              'description': 'Optional: End date filter (YYYY-MM-DD).'
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_patient',
        'description': "Retrieves a patient's information by their ID or name.",
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the patient to retrieve.'
            },
            'name': {
              'type': 'string',
              'description': 'The name of the patient to retrieve.'
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_session',
        'description': 'Adds a new session for a patient.',
        'parameters': {
          'type': 'object',
          'properties': {
            'patientId': {
              'type': 'string',
              'description': 'The ID of the patient.'
            },
            'price': {
              'type': 'number',
              'description': 'The price of the session.'
            },
            'startDateTime': {
              'type': 'string',
              'description': 'Start date/time in ISO 8601 format.'
            },
            'endDateTime': {
              'type': 'string',
              'description': 'End date/time in ISO 8601 format.'
            },
            'sessionType': {
              'type': 'string',
              'description': 'The type of session.'
            },
            'patientName': {
              'type': 'string',
              'description': 'The name of the patient.'
            },
            'doctorId': {
              'type': 'string',
              'description': 'The ID of the doctor.'
            },
          },
          'required': sessionRequired,
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'edit_session',
        'description': "Edits an existing session's information.",
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the session to edit.'
            },
            'patientId': {
              'type': 'string',
              'description': 'The ID of the patient.'
            },
            'price': {'type': 'number', 'description': 'The new price.'},
            'startDateTime': {
              'type': 'string',
              'description': 'New start date/time.'
            },
            'endDateTime': {
              'type': 'string',
              'description': 'New end date/time.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_session',
        'description': 'Deletes a session from the system.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the session to delete.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_sessions',
        'description':
            'Lists sessions, optionally filtered by patient name or date.',
        'parameters': {
          'type': 'object',
          'properties': {
            'patientName': {
              'type': 'string',
              'description': 'Optional: Patient name filter.'
            },
            'date': {
              'type': 'string',
              'description': 'Optional: Specific date (YYYY-MM-DD).'
            },
            'startDate': {
              'type': 'string',
              'description': 'Optional: Start date filter.'
            },
            'endDate': {
              'type': 'string',
              'description': 'Optional: End date filter.'
            },
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'add_evaluation',
        'description': 'Adds a new evaluation for a patient.',
        'parameters': {
          'type': 'object',
          'properties': {
            'patientId': {
              'type': 'string',
              'description': 'The ID of the patient.'
            },
            'patientName': {
              'type': 'string',
              'description': 'The name of the patient.'
            },
            'price': {
              'type': 'number',
              'description': 'The price of the evaluation.'
            },
            'startDateTime': {
              'type': 'string',
              'description': 'Start date/time in ISO 8601 format.'
            },
            'endDateTime': {
              'type': 'string',
              'description': 'End date/time in ISO 8601 format.'
            },
            'doctorId': {
              'type': 'string',
              'description': 'The ID of the doctor.'
            },
          },
          'required': evalRequired,
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'edit_evaluation',
        'description': "Edits an existing evaluation's information.",
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the evaluation to edit.'
            },
            'patientId': {
              'type': 'string',
              'description': 'The ID of the patient.'
            },
            'price': {'type': 'number', 'description': 'The new price.'},
            'startDateTime': {
              'type': 'string',
              'description': 'New start date/time.'
            },
            'endDateTime': {
              'type': 'string',
              'description': 'New end date/time.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'delete_evaluation',
        'description': 'Deletes an evaluation from the system.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': 'The ID of the evaluation to delete.'
            },
          },
          'required': ['id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'list_evaluations',
        'description':
            'Lists evaluations, optionally filtered by patient name or date.',
        'parameters': {
          'type': 'object',
          'properties': {
            'patientName': {
              'type': 'string',
              'description': 'Optional: Patient name filter.'
            },
            'date': {
              'type': 'string',
              'description': 'Optional: Specific date (YYYY-MM-DD).'
            },
            'startDate': {
              'type': 'string',
              'description': 'Optional: Start date filter.'
            },
            'endDate': {
              'type': 'string',
              'description': 'Optional: End date filter.'
            },
          },
          'required': [],
        },
      },
    },
  ];
}
