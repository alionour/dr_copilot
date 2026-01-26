import 'package:dr_copilot/src/features/copilot_chat/services/openai_tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

List<Tool> getGeminiTools({List<String> userRequiredFields = const []}) {
  // Get the single source of truth tools from OpenAI definitions
  // We pass userRequiredFields, but openai_tools might ignore them for add_* as per previous fix.
  final openAITools = getOpenAITools(userRequiredFields: userRequiredFields);

  final functionDeclarations = <FunctionDeclaration>[];

  for (final tool in openAITools) {
    if (tool['type'] == 'function') {
      final function = tool['function'] as Map<String, dynamic>;
      final name = function['name'] as String;
      final description = function['description'] as String;
      final parameters = function['parameters'] as Map<String, dynamic>?;

      if (parameters != null) {
        functionDeclarations.add(
          FunctionDeclaration(
            name,
            description,
            _convertJsonSchemaToGeminiSchema(parameters),
          ),
        );
      } else {
        // Function with no parameters
        functionDeclarations.add(
          FunctionDeclaration(name, description, null),
        );
      }
    }
  }

  return [Tool(functionDeclarations: functionDeclarations)];
}

Schema _convertJsonSchemaToGeminiSchema(Map<String, dynamic> jsonSchema) {
  final typeStr = jsonSchema['type'] as String?;
  final description = jsonSchema['description'] as String?;
  final format = jsonSchema['format'] as String?;

  SchemaType type;
  switch (typeStr) {
    case 'string':
      type = SchemaType.string;
      break;
    case 'integer':
      type = SchemaType.integer;
      break;
    case 'number':
      type = SchemaType.number;
      break;
    case 'boolean':
      type = SchemaType.boolean;
      break;
    case 'array':
      type = SchemaType.array;
      break;
    case 'object':
      type = SchemaType.object;
      break;
    default:
      type = SchemaType.string;
  }

  Map<String, Schema>? properties;
  if (jsonSchema.containsKey('properties')) {
    final propsMap = jsonSchema['properties'] as Map<String, dynamic>;
    properties = {};
    propsMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        properties![key] = _convertJsonSchemaToGeminiSchema(value);
      } else if (value is Map) {
        properties![key] =
            _convertJsonSchemaToGeminiSchema(Map<String, dynamic>.from(value));
      }
    });
  }

  List<String>? requiredProperties;
  if (jsonSchema.containsKey('required')) {
    final reqList = jsonSchema['required'] as List;
    requiredProperties = reqList.map((e) => e.toString()).toList();
  }

  Schema? items;
  if (jsonSchema.containsKey('items')) {
    final itemsMap = jsonSchema['items'];
    if (itemsMap is Map<String, dynamic>) {
      items = _convertJsonSchemaToGeminiSchema(itemsMap);
    } else if (itemsMap is Map) {
      items =
          _convertJsonSchemaToGeminiSchema(Map<String, dynamic>.from(itemsMap));
    }
  }

  List<String>? enumValues;
  if (jsonSchema.containsKey('enum')) {
    final enumList = jsonSchema['enum'] as List;
    enumValues = enumList.map((e) => e.toString()).toList();
  }

  return Schema(
    type,
    description: description,
    format: format,
    properties: properties,
    requiredProperties: requiredProperties,
    items: items,
    enumValues: enumValues,
  );
}
