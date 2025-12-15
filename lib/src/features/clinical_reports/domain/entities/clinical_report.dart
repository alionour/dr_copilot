import 'package:equatable/equatable.dart';

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
  ];
}

