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

  ClinicalReportInstruction copyWith({
    String? id,
    String? userId,
    String? label,
    String? instruction,
  }) {
    return ClinicalReportInstruction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      instruction: instruction ?? this.instruction,
    );
  }

  factory ClinicalReportInstruction.fromMap(Map<String, dynamic> map) {
    return ClinicalReportInstruction(
      id: map['id'] as String,
      userId: map['userId'] as String,
      label: map['label'] as String,
      instruction: map['instruction'] as String,
    );
  }

  factory ClinicalReportInstruction.fromJson(Map<String, dynamic> json) =>
      ClinicalReportInstruction.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'instruction': instruction,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  List<Object?> get props => [id, userId, label, instruction];
}
