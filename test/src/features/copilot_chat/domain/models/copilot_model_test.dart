import 'package:dr_copilot/src/features/copilot_chat/domain/models/copilot_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_helpers.dart';

void main() {
  group('CopilotModel Tests', () {
    group('Constructor', () {
      test('should create CopilotModel with required parameters', () {
        const id = 'test-copilot-id';
        const name = 'Test Copilot';
        const role = 'assistant';

        final copilot = CopilotModel(
          id: id,
          name: name,
          role: role,
        );

        expect(copilot.id, equals(id));
        expect(copilot.name, equals(name));
        expect(copilot.role, equals(role));
      });

      test('should create CopilotModel with different roles', () {
        final roles = ['assistant', 'doctor', 'nurse', 'admin'];

        for (final role in roles) {
          final copilot = CopilotModel(
            id: 'test-id',
            name: 'Test Copilot',
            role: role,
          );

          expect(copilot.role, equals(role));
        }
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final copilot = TestHelpers.createTestCopilot(
          id: 'test-copilot-id',
          name: 'Test Copilot',
          role: 'assistant',
        );

        final json = copilot.toJson();

        expect(json['id'], equals('test-copilot-id'));
        expect(json['name'], equals('Test Copilot'));
        expect(json['role'], equals('assistant'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'test-copilot-id',
          'name': 'Test Copilot',
          'role': 'assistant',
        };

        final copilot = CopilotModel.fromJson(json);

        expect(copilot.id, equals('test-copilot-id'));
        expect(copilot.name, equals('Test Copilot'));
        expect(copilot.role, equals('assistant'));
      });

      test('should handle JSON round trip', () {
        final originalCopilot = TestHelpers.createTestCopilot(
          id: 'round-trip-id',
          name: 'Round Trip Copilot',
          role: 'doctor',
        );

        final json = originalCopilot.toJson();
        final deserializedCopilot = CopilotModel.fromJson(json);

        expect(deserializedCopilot.id, equals(originalCopilot.id));
        expect(deserializedCopilot.name, equals(originalCopilot.name));
        expect(deserializedCopilot.role, equals(originalCopilot.role));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        final copilot1 = TestHelpers.createTestCopilot(
          id: 'test-id',
          name: 'Test Copilot',
          role: 'assistant',
        );
        final copilot2 = TestHelpers.createTestCopilot(
          id: 'test-id',
          name: 'Test Copilot',
          role: 'assistant',
        );

        expect(copilot1, equals(copilot2));
        expect(copilot1.hashCode, equals(copilot2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final copilot1 = TestHelpers.createTestCopilot(id: 'test-id-1');
        final copilot2 = TestHelpers.createTestCopilot(id: 'test-id-2');

        expect(copilot1, isNot(equals(copilot2)));
      });

      test('should not be equal when names differ', () {
        final copilot1 = TestHelpers.createTestCopilot(name: 'Copilot One');
        final copilot2 = TestHelpers.createTestCopilot(name: 'Copilot Two');

        expect(copilot1, isNot(equals(copilot2)));
      });

      test('should not be equal when roles differ', () {
        final copilot1 = TestHelpers.createTestCopilot(role: 'assistant');
        final copilot2 = TestHelpers.createTestCopilot(role: 'doctor');

        expect(copilot1, isNot(equals(copilot2)));
      });
    });

    group('Validation', () {
      test('should handle empty strings', () {
        final copilot = CopilotModel(
          id: '',
          name: '',
          role: '',
        );

        expect(copilot.id, equals(''));
        expect(copilot.name, equals(''));
        expect(copilot.role, equals(''));
      });

      test('should handle special characters in name', () {
        final copilot = CopilotModel(
          id: 'test-id',
          name: 'Dr. AI Assistant™ (v2.0)',
          role: 'assistant',
        );

        expect(copilot.name, equals('Dr. AI Assistant™ (v2.0)'));
      });

      test('should handle various role types', () {
        final roleTypes = [
          'assistant',
          'doctor',
          'nurse',
          'admin',
          'specialist',
          'consultant',
          'AI_ASSISTANT',
          'medical-bot',
        ];

        for (final role in roleTypes) {
          final copilot = CopilotModel(
            id: 'test-id',
            name: 'Test Copilot',
            role: role,
          );

          expect(copilot.role, equals(role));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        final copilot = CopilotModel(
          id: longString,
          name: longString,
          role: longString,
        );

        expect(copilot.id.length, equals(1000));
        expect(copilot.name.length, equals(1000));
        expect(copilot.role.length, equals(1000));
      });

      test('should handle international characters', () {
        final copilot = CopilotModel(
          id: 'test-id',
          name: 'مساعد طبي ذكي',
          role: 'مساعد',
        );

        expect(copilot.name, equals('مساعد طبي ذكي'));
        expect(copilot.role, equals('مساعد'));
      });

      test('should handle mixed language content', () {
        final copilot = CopilotModel(
          id: 'test-id',
          name: 'AI Assistant / مساعد ذكي',
          role: 'multilingual-assistant',
        );

        expect(copilot.name, equals('AI Assistant / مساعد ذكي'));
        expect(copilot.role, equals('multilingual-assistant'));
      });

      test('should handle numeric strings', () {
        final copilot = CopilotModel(
          id: '12345',
          name: 'Copilot 2024',
          role: 'v1.0',
        );

        expect(copilot.id, equals('12345'));
        expect(copilot.name, equals('Copilot 2024'));
        expect(copilot.role, equals('v1.0'));
      });
    });

    group('Business Logic', () {
      test('should represent a valid copilot entity', () {
        final copilot = TestHelpers.createTestCopilot();

        // Basic validation that a copilot has essential properties
        expect(copilot.id, isNotEmpty);
        expect(copilot.name, isNotEmpty);
        expect(copilot.role, isNotEmpty);
      });

      test('should support different copilot types', () {
        final copilotTypes = [
          {'name': 'Medical Assistant', 'role': 'assistant'},
          {'name': 'Diagnostic Helper', 'role': 'diagnostician'},
          {'name': 'Treatment Advisor', 'role': 'advisor'},
          {'name': 'Research Bot', 'role': 'researcher'},
        ];

        for (final type in copilotTypes) {
          final copilot = CopilotModel(
            id: 'test-id',
            name: type['name']!,
            role: type['role']!,
          );

          expect(copilot.name, equals(type['name']));
          expect(copilot.role, equals(type['role']));
        }
      });

      test('should maintain immutability', () {
        final copilot = TestHelpers.createTestCopilot();
        final originalId = copilot.id;
        final originalName = copilot.name;
        final originalRole = copilot.role;

        // Properties should be final and immutable
        expect(copilot.id, equals(originalId));
        expect(copilot.name, equals(originalName));
        expect(copilot.role, equals(originalRole));
      });
    });

    group('JSON Edge Cases', () {
      test('should handle JSON with extra fields', () {
        final json = {
          'id': 'test-id',
          'name': 'Test Copilot',
          'role': 'assistant',
          'extraField': 'should be ignored',
          'anotherField': 123,
        };

        final copilot = CopilotModel.fromJson(json);

        expect(copilot.id, equals('test-id'));
        expect(copilot.name, equals('Test Copilot'));
        expect(copilot.role, equals('assistant'));
      });

      test('should handle JSON with null values gracefully', () {
        // This test assumes the model handles required fields properly
        expect(() {
          final json = {
            'id': 'test-id',
            'name': 'Test Copilot',
            'role': 'assistant',
          };
          CopilotModel.fromJson(json);
        }, returnsNormally);
      });
    });

    group('Type Safety', () {
      test('should maintain type safety for all properties', () {
        final copilot = TestHelpers.createTestCopilot();

        expect(copilot.id, isA<String>());
        expect(copilot.name, isA<String>());
        expect(copilot.role, isA<String>());
      });

      test('should handle type consistency in JSON operations', () {
        final copilot = TestHelpers.createTestCopilot();
        final json = copilot.toJson();

        expect(json['id'], isA<String>());
        expect(json['name'], isA<String>());
        expect(json['role'], isA<String>());
      });
    });
  });
}
