import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/analytics_model.dart';
import '../../domain/repositories/charts_repository.dart';

// Events
abstract class ChartsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadChartsData extends ChartsEvent {
  final String clinicId;

  LoadChartsData(this.clinicId);

  @override
  List<Object?> get props => [clinicId];
}

// States
abstract class ChartsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChartsInitial extends ChartsState {}

class ChartsLoading extends ChartsState {}

class ChartsLoaded extends ChartsState {
  final AnalyticsData data;

  ChartsLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class ChartsError extends ChartsState {
  final String message;

  ChartsError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ChartsBloc extends Bloc<ChartsEvent, ChartsState> {
  final ChartsRepository repository;

  ChartsBloc({required this.repository}) : super(ChartsInitial()) {
    on<LoadChartsData>(_onLoadChartsData);
  }

  Future<void> _onLoadChartsData(
    LoadChartsData event,
    Emitter<ChartsState> emit,
  ) async {
    emit(ChartsLoading());

    final result = await repository.getAnalyticsData(event.clinicId);

    result.fold(
      (failure) => emit(ChartsError(failure.message)),
      (data) => emit(ChartsLoaded(data)),
    );
  }
}
