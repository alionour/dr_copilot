import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/models/task_model.dart';
import '../../domain/usecases/task_usecase.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TaskUseCase _useCase;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  TasksBloc(this._useCase) : super(TasksInitial()) {
    on<StreamTasks>(_onStreamTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    on<MarkTaskAsDone>(_onMarkTaskAsDone);
    on<UpdateTasksList>(_onUpdateTasksList);
    on<TasksStreamError>(_onTasksStreamError);
  }

  Future<void> _onStreamTasks(
    StreamTasks event,
    Emitter<TasksState> emit,
  ) async {
    debugPrint(
        '🔄 Tasks: Starting to stream tasks for clinic: ${event.clinicId}');
    emit(TasksLoading());
    await _tasksSubscription?.cancel();
    _tasksSubscription =
        _useCase.streamTasks(event.clinicId, userId: event.userId).listen(
      (tasks) {
        debugPrint('✅ Tasks: Loaded ${tasks.length} tasks successfully');
        add(UpdateTasksList(tasks));
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Tasks: Stream error occurred!');
        debugPrint('Error details: $error');
        debugPrint('Stack trace: $stackTrace');
        // Add error event instead of calling emit directly
        add(TasksStreamError(error.toString()));
      },
    );
  }

  void _onTasksStreamError(TasksStreamError event, Emitter<TasksState> emit) {
    debugPrint('⚠️ Tasks: Emitting error state: ${event.message}');
    emit(TasksError(event.message));
  }

  void _onUpdateTasksList(UpdateTasksList event, Emitter<TasksState> emit) {
    emit(TasksLoaded(event.tasks));
  }

  Future<void> _onCreateTask(
    CreateTask event,
    Emitter<TasksState> emit,
  ) async {
    // Optimistic or waiting? Let's verify result.
    // Since it's realtime, the stream will update the UI.
    // However, we might want to emit a temporary loading/success for the Action itself.
    // For simplicity in this dashboard, we might rely on stream updates,
    // or we can use a separate 'TaskActionState' if needed.
    // Here we just perform the action. Errors should be handled (e.g. via a separate effect or snackbar).

    final result = await _useCase.createTask(event.task);
    result.fold(
      (failure) => emit(TasksError(
          failure.message)), // Emitting error will replace list... be careful.
      // Ideally we use a mixin for side-effects or a comprehensive state.
      // For now, if error, we show it, then maybe revert?
      // Better: Don't replace 'Loaded' state with Error if we want to keep showing data.
      // But standard Bloc pattern usually uses single state stream.
      // Let's stick to simple state logic: Error state replaces current view.
      (_) => null,
    );
  }

  Future<void> _onUpdateTask(
    UpdateTask event,
    Emitter<TasksState> emit,
  ) async {
    final result = await _useCase.updateTask(event.task);
    result.fold(
      (failure) => emit(TasksError(failure.message)),
      (_) => null,
    );
  }

  Future<void> _onDeleteTask(
    DeleteTask event,
    Emitter<TasksState> emit,
  ) async {
    final result = await _useCase.deleteTask(event.taskId);
    result.fold(
      (failure) => emit(TasksError(failure.message)),
      (_) => null,
    );
  }

  Future<void> _onMarkTaskAsDone(
    MarkTaskAsDone event,
    Emitter<TasksState> emit,
  ) async {
    final result = await _useCase.markAsDone(event.taskId);
    result.fold(
      (failure) => emit(TasksError(failure.message)),
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
