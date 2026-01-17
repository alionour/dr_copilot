import 'package:equatable/equatable.dart';

class BodyMarker extends Equatable {
  final String id;
  final double x; // Relative X (0.0 to 1.0)
  final double y; // Relative Y (0.0 to 1.0)
  final double? z; // Relative Z (optional, for 3D)
  final String label;
  final String type; // e.g., 'pain', 'rash', 'scar', 'injury'
  final String notes; // Detailed description/observations
  final DateTime timestamp; // When marker was created/modified
  final String color; // Hex color string (e.g., '#FF0000' for red)
  final String view; // 'front', 'back', 'left', 'right', '3d'
  final double scale; // Scale factor for 3D markers (default 1.0)
  final String?
      modelId; // ID of the 3D model this marker belongs to (e.g., 'human_body.glb')

  const BodyMarker({
    required this.id,
    required this.x,
    required this.y,
    this.z,
    required this.label,
    required this.timestamp,
    this.type = 'pain',
    this.notes = '',
    this.color = '#D32F2F', // Default red
    this.view = 'front', // Default to front view
    this.scale = 1.0,
    this.modelId,
  });

  /// Copy with for updates
  BodyMarker copyWith({
    String? id,
    double? x,
    double? y,
    double? z,
    String? label,
    String? type,
    String? notes,
    DateTime? timestamp,
    String? color,
    String? view,
    double? scale,
    String? modelId,
  }) {
    return BodyMarker(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      label: label ?? this.label,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      color: color ?? this.color,
      view: view ?? this.view,
      scale: scale ?? this.scale,
      modelId: modelId ?? this.modelId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'z': z,
      'label': label,
      'type': type,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'color': color,
      'view': view,
      'scale': scale,
      'modelId': modelId,
    };
  }

  factory BodyMarker.fromJson(Map<String, dynamic> json) {
    return BodyMarker(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      z: json['z'] != null ? (json['z'] as num).toDouble() : null,
      label: json['label'] as String,
      type: json['type'] as String? ?? 'pain',
      notes: json['notes'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      color: json['color'] as String? ?? '#D32F2F',
      view: json['view'] as String? ?? 'front',
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      modelId: json['modelId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, x, y, z, label, type, notes, timestamp, color, view, scale, modelId];
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
