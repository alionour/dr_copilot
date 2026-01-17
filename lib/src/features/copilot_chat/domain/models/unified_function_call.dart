/// Unified function call representation that works across all AI providers
/// (Gemini, Groq, GPT, etc.)
class UnifiedFunctionCall {
  final String name;
  final Map<String, dynamic> args;

  const UnifiedFunctionCall({
    required this.name,
    required this.args,
  });

  @override
  String toString() => 'UnifiedFunctionCall(name: $name, args: $args)';
}
