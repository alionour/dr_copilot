import 'package:equatable/equatable.dart';

class ClinicalReportTemplate extends Equatable {
  final String id;
  final String name;
  final List<dynamic> content; // Quill Delta JSON content

  const ClinicalReportTemplate({
    required this.id,
    required this.name,
    required this.content,
  });

  @override
  List<Object?> get props => [id, name, content];
}

