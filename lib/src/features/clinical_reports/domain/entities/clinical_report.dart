import 'package:equatable/equatable.dart';

class ClinicalReport extends Equatable {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final DateTime date;
  final List<String> documentUrls;

  const ClinicalReport({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.date,
    this.documentUrls = const [],
  });

  ClinicalReport copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    DateTime? date,
    List<String>? documentUrls,
  }) {
    return ClinicalReport(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      documentUrls: documentUrls ?? this.documentUrls,
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
      ];
}
