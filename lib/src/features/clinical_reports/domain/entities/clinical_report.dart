import 'package:equatable/equatable.dart';

class BodyMarker extends Equatable {
  final String id;
  final double x; // Relative X (0.0 to 1.0)
  final double y; // Relative Y (0.0 to 1.0)
  final String label;
  final String type; // e.g., 'pain', 'rash', 'scar'

  const BodyMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    this.type = 'pain',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'label': label,
      'type': type,
    };
  }

  factory BodyMarker.fromJson(Map<String, dynamic> json) {
    return BodyMarker(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      label: json['label'] as String,
      type: json['type'] as String? ?? 'pain',
    );
  }

  @override
  List<Object?> get props => [id, x, y, label, type];
}

class ClinicalReport extends Equatable {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final DateTime date;
  final List<String> documentUrls;
  final String? contentUrl; // Reserved for future Storage migration
  final String? content; // HTML content stored in Firestore
  final String? googleDocId; // Link to Google Doc (null when finalized)
  final bool isFinalized; // True when exported and locked
  final DateTime? finalizedAt; // When report was finalized
  final String? finalizedBy; // User ID who finalized
  final List<BodyMarker> bodyMapPoints;

  const ClinicalReport({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.date,
    this.documentUrls = const [],
    this.contentUrl,
    this.content,
    this.googleDocId,
    this.isFinalized = false,
    this.finalizedAt,
    this.finalizedBy,
    this.bodyMapPoints = const [],
  });

  ClinicalReport copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    DateTime? date,
    List<String>? documentUrls,
    String? contentUrl,
    String? content,
    String? googleDocId,
    bool? isFinalized,
    DateTime? finalizedAt,
    String? finalizedBy,
    List<BodyMarker>? bodyMapPoints,
  }) {
    return ClinicalReport(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      documentUrls: documentUrls ?? this.documentUrls,
      contentUrl: contentUrl ?? this.contentUrl,
      content: content ?? this.content,
      googleDocId: googleDocId ?? this.googleDocId,
      isFinalized: isFinalized ?? this.isFinalized,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      bodyMapPoints: bodyMapPoints ?? this.bodyMapPoints,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientId,
        title,
        description,
        date,
        documentUrls,
        contentUrl,
        content,
        googleDocId,
        isFinalized,
        finalizedAt,
        finalizedBy,
        bodyMapPoints,
      ];
}
