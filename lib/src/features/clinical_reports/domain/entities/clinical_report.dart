import 'package:equatable/equatable.dart';

class ClinicalReport extends Equatable {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final DateTime date;
  final List<String> documentUrls;
  final String? contentUrl;

  const ClinicalReport({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.date,
    this.documentUrls = const [],
    this.contentUrl,
  });

  ClinicalReport copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    DateTime? date,
    List<String>? documentUrls,
    String? contentUrl,
  }) {
    return ClinicalReport(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      documentUrls: documentUrls ?? this.documentUrls,
      contentUrl: contentUrl ?? this.contentUrl,
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
      ];
}
