import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A model class representing clinic-specific settings.
class ClinicSettingsModel extends Equatable {
  /// The working days of the clinic (1 = Monday, 7 = Sunday).
  final List<int> workingDays;

  /// The list of required fields for Copilot AI generation.
  final List<String> copilotRequiredFields;

  /// The timestamp when the settings were last updated.
  final DateTime? lastUpdated;

  /// The ID of the user who last updated the settings.
  final String? updatedBy;

  /// Creates a new [ClinicSettingsModel] instance.
  const ClinicSettingsModel({
    this.workingDays = const [1, 2, 3, 4, 5],
    this.copilotRequiredFields = const [],
    this.lastUpdated,
    this.updatedBy,
  });

  factory ClinicSettingsModel.fromJson(Map<String, dynamic> json) {
    return ClinicSettingsModel(
      workingDays: (json['workingDays'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 1)
              .toList() ??
          const [1, 2, 3, 4, 5],
      copilotRequiredFields: (json['copilotRequiredFields'] as List<dynamic>?)
              ?.where((e) => e != null)
              .map((e) => e.toString())
              .toList() ??
          const [],
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workingDays': workingDays,
      'copilotRequiredFields': copilotRequiredFields,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  ClinicSettingsModel copyWith({
    List<int>? workingDays,
    List<String>? copilotRequiredFields,
    DateTime? lastUpdated,
    String? updatedBy,
  }) {
    return ClinicSettingsModel(
      workingDays: workingDays ?? this.workingDays,
      copilotRequiredFields:
          copilotRequiredFields ?? this.copilotRequiredFields,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  List<Object?> get props =>
      [workingDays, copilotRequiredFields, lastUpdated, updatedBy];
}
