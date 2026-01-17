import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String clinicId;
  final String title;
  final String description;
  final String? assignedToUserId; // ID of the user responsible for the task
  final String assignedByUserId; // ID of the user who created the task
  final String status; // pending, in_progress, done, archived
  final String priority; // low, medium, high, urgent
  final DateTime? dueDate;
  final String? linkedPatientId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.description,
    this.assignedToUserId,
    required this.assignedByUserId,
    required this.status,
    required this.priority,
    this.dueDate,
    this.linkedPatientId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      assignedToUserId: json['assignedToUserId'] as String?,
      assignedByUserId: json['assignedByUserId'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      dueDate: (json['dueDate'] as Timestamp?)?.toDate(),
      linkedPatientId: json['linkedPatientId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinicId': clinicId,
      'title': title,
      'description': description,
      'assignedToUserId': assignedToUserId,
      'assignedByUserId': assignedByUserId,
      'status': status,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'linkedPatientId': linkedPatientId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskModel copyWith({
    String? id,
    String? clinicId,
    String? title,
    String? description,
    String? assignedToUserId,
    String? assignedByUserId,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? linkedPatientId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedByUserId: assignedByUserId ?? this.assignedByUserId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      linkedPatientId: linkedPatientId ?? this.linkedPatientId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
