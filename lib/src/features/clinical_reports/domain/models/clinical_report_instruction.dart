import 'package:equatable/equatable.dart';

class ClinicalReportInstruction extends Equatable {
  final String id;
  final String userId;
  final String label;
  final String instruction;

  const ClinicalReportInstruction({
    required this.id,
    required this.userId,
    required this.label,
    required this.instruction,
  });

  factory ClinicalReportInstruction.fromJson(Map<String, dynamic> json) {
    return ClinicalReportInstruction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      label: json['label'] as String,
      instruction: json['instruction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'instruction': instruction,
    };
  }

  @override
  List<Object?> get props => [id, userId, label, instruction];
}
