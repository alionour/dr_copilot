import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:equatable/equatable.dart';

class CorrectionModel extends Equatable {
  final String id;
  final Command originalCommand;
  final Command correctedCommand;
  final DateTime createdAt;

  const CorrectionModel({
    required this.id,
    required this.originalCommand,
    required this.correctedCommand,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, originalCommand, correctedCommand, createdAt];
}
