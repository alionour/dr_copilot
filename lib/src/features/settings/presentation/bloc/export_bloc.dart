import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/settings/domain/services/export_service.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/export_event.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/export_state.dart';

/// BLoC for managing the user data export process.
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService _exportService;
  final String _userId;
  final String _userEmail;
  final String? _primaryClinicId;

  ExportBloc({
    required ExportService exportService,
    required String userId,
    required String userEmail,
    String? primaryClinicId,
  }) : _exportService = exportService,
       _userId = userId,
       _userEmail = userEmail,
       _primaryClinicId = primaryClinicId,
       super(const ExportInitial()) {
    on<ExportDataRequested>(_onExportDataRequested);
    on<ExportProgressUpdated>(_onExportProgressUpdated);
    on<ExportCompleted>(_onExportCompleted);
    on<ExportFailed>(_onExportFailed);
    on<ExportReset>(_onExportReset);
  }

  /// Handles the export data requested event.
  Future<void> _onExportDataRequested(
    ExportDataRequested event,
    Emitter<ExportState> emit,
  ) async {
    try {
      // 1. Check user permissions first
      if (_primaryClinicId == null || _primaryClinicId.isEmpty) {
        emit(
          const ExportFailure(
            'Unable to determine your clinic. Please ensure you are a member of a clinic.',
          ),
        );
        return;
      }

      final permissionResult = await _exportService.canUserExport(
        _userId,
        _primaryClinicId,
      );

      if (permissionResult['canExport'] != true) {
        final reason =
            permissionResult['reason'] as String? ??
            'You do not have permission to export data';
        emit(ExportFailure(reason));
        return;
      }

      // 2. Check rate limiting
      final canExportResult = await _exportService.canExport();

      if (canExportResult['canExport'] != true) {
        final daysRemaining = canExportResult['daysRemaining'] as int;
        final nextExportDate = canExportResult['nextExportDate'] as DateTime;
        final formattedDate =
            '${nextExportDate.year}-${nextExportDate.month.toString().padLeft(2, '0')}-${nextExportDate.day.toString().padLeft(2, '0')}';

        emit(
          ExportFailure(
            'You can only export data once per week. Please wait $daysRemaining more day${daysRemaining > 1 ? 's' : ''} (available on $formattedDate).',
          ),
        );
        return;
      }

      // 3. Start export
      emit(
        const ExportInProgress(
          progress: 0.0,
          currentCategory: 'Starting export...',
        ),
      );

      // Start the export with progress callback
      final filePath = await _exportService.exportAllUserData(
        _userId,
        _userEmail,
        onProgress: (progress, category) {
          add(
            ExportProgressUpdated(
              progress: progress,
              currentCategory: category,
            ),
          );
        },
      );

      // Get file size
      final fileSize = await _exportService.getFileSize(filePath);

      // Emit success
      add(ExportCompleted(filePath));
      emit(ExportSuccess(filePath: filePath, fileSize: fileSize));
    } catch (e) {
      add(ExportFailed(e.toString()));
      emit(ExportFailure(e.toString()));
    }
  }

  /// Handles export progress updates.
  void _onExportProgressUpdated(
    ExportProgressUpdated event,
    Emitter<ExportState> emit,
  ) {
    emit(
      ExportInProgress(
        progress: event.progress,
        currentCategory: event.currentCategory,
      ),
    );
  }

  /// Handles export completion.
  void _onExportCompleted(
    ExportCompleted event,
    Emitter<ExportState> emit,
  ) async {
    final fileSize = await _exportService.getFileSize(event.filePath);
    emit(ExportSuccess(filePath: event.filePath, fileSize: fileSize));
  }

  /// Handles export failure.
  void _onExportFailed(ExportFailed event, Emitter<ExportState> emit) {
    emit(ExportFailure(event.error));
  }

  /// Handles export reset.
  void _onExportReset(ExportReset event, Emitter<ExportState> emit) {
    emit(const ExportInitial());
  }
}
