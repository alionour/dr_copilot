import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_api_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/evaluations_repository.dart';

class EvaluationsRepositoryImpl implements EvaluationsRepository {
  final EvaluationApiImpl? apiImpl;
  final EvaluationFirebaseApi? firebaseApi;

  EvaluationsRepositoryImpl({this.apiImpl, this.firebaseApi});

  @override
  Future<void> addEvaluation(EvaluationModel evaluation) {
    if (apiImpl != null) {
      return apiImpl!.addEvaluation(evaluation);
    } else if (firebaseApi != null) {
      return firebaseApi!.addEvaluation(evaluation);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<void> updateEvaluation(EvaluationModel evaluationModel) {
    if (apiImpl != null) {
      return apiImpl!.updateEvaluation(evaluationModel);
    } else if (firebaseApi != null) {
      return firebaseApi!.updateEvaluation(evaluationModel);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<void> deleteEvaluation(String sessionId) {
    if (apiImpl != null) {
      return apiImpl!.deleteEvaluation(sessionId);
    } else if (firebaseApi != null) {
      return firebaseApi!.deleteEvaluation(sessionId);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<List<EvaluationModel>> getEvaluations() {
    if (apiImpl != null) {
      return apiImpl!.getEvaluations();
    } else if (firebaseApi != null) {
      return firebaseApi!.getEvaluations();
    } else {
      throw Exception('No data source provided');
    }
  }
}
