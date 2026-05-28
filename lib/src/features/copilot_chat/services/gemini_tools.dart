import 'package:dr_copilot/src/features/copilot_chat/services/openai_tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google;
import 'package:firebase_ai/firebase_ai.dart' as firebase;

/// Returns tools compatible with google_generative_ai package.
List<google.Tool> getGeminiTools({List<String> userRequiredFields = const []}) {
  final openAITools = getOpenAITools(userRequiredFields: userRequiredFields);
  final functionDeclarations = <google.FunctionDeclaration>[];

  for (final tool in openAITools) {
    if (tool['type'] == 'function') {
      final function = tool['function'] as Map<String, dynamic>;
      final name = function['name'] as String;
      final description = function['description'] as String;
      final parameters = function['parameters'] as Map<String, dynamic>?;

      if (parameters != null) {
        functionDeclarations.add(
          google.FunctionDeclaration(
            name,
            description,
            _convertJsonSchemaToGoogleSchema(parameters),
          ),
        );
      } else {
        functionDeclarations.add(
          google.FunctionDeclaration(name, description, null),
        );
      }
    }
  }

  return [google.Tool(functionDeclarations: functionDeclarations)];
}

/// Returns tools compatible with firebase_ai package.
List<firebase.Tool> getFirebaseAITools({
  List<String> userRequiredFields = const [],
}) {
  final openAITools = getOpenAITools(userRequiredFields: userRequiredFields);
  final functionDeclarations = <firebase.FunctionDeclaration>[];

  for (final tool in openAITools) {
    if (tool['type'] == 'function') {
      final function = tool['function'] as Map<String, dynamic>;
      final name = function['name'] as String;
      final description = function['description'] as String;
      final parameters = function['parameters'] as Map<String, dynamic>?;

      if (parameters != null && parameters['type'] == 'object') {
        final propsMap =
            parameters['properties'] as Map<String, dynamic>? ?? {};
        final firebaseProps = <String, firebase.Schema>{};
        propsMap.forEach((key, value) {
          firebaseProps[key] =
              _convertJsonSchemaToFirebaseSchema(value as Map<String, dynamic>);
        });

        final requiredList =
            (parameters['required'] as List?)?.map((e) => e.toString()).toList() ??
                [];

        functionDeclarations.add(
          firebase.FunctionDeclaration(
            name,
            description,
            parameters: firebaseProps,
            optionalParameters:
                propsMap.keys.where((k) => !requiredList.contains(k)).toList(),
          ),
        );
      } else {
        functionDeclarations.add(
          firebase.FunctionDeclaration(name, description, parameters: {}),
        );
      }
    }
  }

  return [firebase.Tool.functionDeclarations(functionDeclarations)];
}

google.Schema _convertJsonSchemaToGoogleSchema(Map<String, dynamic> jsonSchema) {
  final typeStr = jsonSchema['type'] as String?;
  final description = jsonSchema['description'] as String?;
  final format = jsonSchema['format'] as String?;

  google.SchemaType type;
  switch (typeStr) {
    case 'string':
      type = google.SchemaType.string;
      break;
    case 'integer':
      type = google.SchemaType.integer;
      break;
    case 'number':
      type = google.SchemaType.number;
      break;
    case 'boolean':
      type = google.SchemaType.boolean;
      break;
    case 'array':
      type = google.SchemaType.array;
      break;
    case 'object':
      type = google.SchemaType.object;
      break;
    default:
      type = google.SchemaType.string;
  }

  Map<String, google.Schema>? properties;
  if (jsonSchema.containsKey('properties')) {
    final propsMap = jsonSchema['properties'] as Map<String, dynamic>;
    properties = {};
    propsMap.forEach((key, value) {
      properties![key] =
          _convertJsonSchemaToGoogleSchema(value as Map<String, dynamic>);
    });
  }

  List<String>? requiredProperties;
  if (jsonSchema.containsKey('required')) {
    final reqList = jsonSchema['required'] as List;
    requiredProperties = reqList.map((e) => e.toString()).toList();
  }

  google.Schema? items;
  if (jsonSchema.containsKey('items')) {
    items = _convertJsonSchemaToGoogleSchema(
      jsonSchema['items'] as Map<String, dynamic>,
    );
  }

  List<String>? enumValues;
  if (jsonSchema.containsKey('enum')) {
    enumValues = (jsonSchema['enum'] as List).map((e) => e.toString()).toList();
  }

  switch (type) {
    case google.SchemaType.object:
      return google.Schema.object(
        properties: properties ?? {},
        requiredProperties: requiredProperties,
        description: description,
      );
    case google.SchemaType.array:
      return google.Schema.array(
        items: items!,
        description: description,
      );
    case google.SchemaType.string:
      if (enumValues != null && enumValues.isNotEmpty) {
        return google.Schema.enumString(
          enumValues: enumValues,
          description: description,
        );
      }
      return google.Schema.string(
        description: description,
      );
    case google.SchemaType.integer:
      return google.Schema.integer(
        description: description,
        format: format,
      );
    case google.SchemaType.number:
      return google.Schema.number(
        description: description,
        format: format,
      );
    case google.SchemaType.boolean:
      return google.Schema.boolean(
        description: description,
      );
  }
}

firebase.Schema _convertJsonSchemaToFirebaseSchema(
  Map<String, dynamic> jsonSchema,
) {
  final typeStr = jsonSchema['type'] as String?;
  final description = jsonSchema['description'] as String?;
  final format = jsonSchema['format'] as String?;

  firebase.SchemaType type;
  switch (typeStr) {
    case 'string':
      type = firebase.SchemaType.string;
      break;
    case 'integer':
      type = firebase.SchemaType.integer;
      break;
    case 'number':
      type = firebase.SchemaType.number;
      break;
    case 'boolean':
      type = firebase.SchemaType.boolean;
      break;
    case 'array':
      type = firebase.SchemaType.array;
      break;
    case 'object':
      type = firebase.SchemaType.object;
      break;
    default:
      type = firebase.SchemaType.string;
  }

  Map<String, firebase.Schema>? properties;
  if (jsonSchema.containsKey('properties')) {
    final propsMap = jsonSchema['properties'] as Map<String, dynamic>;
    properties = {};
    propsMap.forEach((key, value) {
      properties![key] =
          _convertJsonSchemaToFirebaseSchema(value as Map<String, dynamic>);
    });
  }

  List<String>? optionalProperties;
  if (properties != null) {
    final requiredProperties =
        (jsonSchema['required'] as List?)?.map((e) => e.toString()).toList() ??
            [];
    optionalProperties = properties.keys
        .where((key) => !requiredProperties.contains(key))
        .toList();
  }

  firebase.Schema? items;
  if (jsonSchema.containsKey('items')) {
    items = _convertJsonSchemaToFirebaseSchema(
      jsonSchema['items'] as Map<String, dynamic>,
    );
  }

  List<String>? enumValues;
  if (jsonSchema.containsKey('enum')) {
    enumValues = (jsonSchema['enum'] as List).map((e) => e.toString()).toList();
  }

  return firebase.Schema(
    type,
    description: description,
    format: format,
    properties: properties,
    optionalProperties: optionalProperties,
    items: items,
    enumValues: enumValues,
  );
}
