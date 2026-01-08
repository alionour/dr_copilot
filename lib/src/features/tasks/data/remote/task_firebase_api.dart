import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/task_model.dart';

class TaskFirebaseApi {
  final FirebaseFirestore _firestore;

  TaskFirebaseApi({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('tasks');

  /// Stream tasks for a specific clinic.
  /// Optionally filtered by user ID (assignedToUserId).
  Stream<List<TaskModel>> streamTasks(String clinicId, {String? userId}) {
    Query<Map<String, dynamic>> query =
        _tasksCollection.where('clinicId', isEqualTo: clinicId);

    if (userId != null) {
      query = query.where('assignedToUserId', isEqualTo: userId);
    }

    // Order by createdAt descending by default (newest first)
    // Note: Creating composite indexes might be required for queries with multiple filters + sorting
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> createTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksCollection.doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  Future<void> markAsDone(String taskId) async {
    await _tasksCollection.doc(taskId).update({
      'status': 'done',
      'updatedAt': Timestamp.now(),
    });
  }
}
