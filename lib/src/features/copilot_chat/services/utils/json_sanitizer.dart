import 'package:cloud_firestore/cloud_firestore.dart';

/// Sanitizes a JSON-like object for Gemini, converting non-standard types like [Timestamp].
dynamic sanitizeJsonForGemini(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  }
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), sanitizeJsonForGemini(v)));
  }
  if (value is List) {
    return value.map(sanitizeJsonForGemini).toList();
  }
  return value;
}
