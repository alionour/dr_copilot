import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/add_evaluation_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/add_session_page.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/gemini_live_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/live_chat_state.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage>
    with SingleTickerProviderStateMixin {
  late GeminiLiveService _liveChatService;
  late AnimationController _visualizerController;

  String? _activeFormType;
  Map<String, dynamic>? _activeFormData;
  final List<_TranscriptEntry> _transcriptEntries = [];
  bool _showTranscript = true;
  StreamSubscription? _stateSub;
  StreamSubscription? _transcriptSub;

  @override
  void initState() {
    super.initState();
    _liveChatService = GetIt.instance<GeminiLiveService>();
    _visualizerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();

    // Setup Form Request callback
    _liveChatService.startSession().then((_) {
      // Re-setup the callback just in case of reconnection
      _setupCallbacks();
    });
    
    _setupCallbacks();

    _stateSub = _liveChatService.stateStream.listen((_) {
      if (mounted) setState(() {});
    });

    _transcriptSub = _liveChatService.transcriptStream.listen((text) {
      if (text.startsWith('__USER__:')) {
        _transcriptEntries.add(_TranscriptEntry(
          speaker: 'user',
          text: text.substring(9),
        ));
      } else if (text.startsWith('__AI__:')) {
        _transcriptEntries.add(_TranscriptEntry(
          speaker: 'ai',
          text: text.substring(7),
        ));
      }
      if (mounted) setState(() {});
    });
  }

  void _setupCallbacks() {
    final settings = context.read<SettingsBloc>().state;
    _liveChatService.currentLocale = settings.localeCode;
    _liveChatService.onFormRequested = (formType, initialData) {
      if (mounted) {
        setState(() {
          _activeFormType = formType;
          _activeFormData = initialData;
        });
      }
    };
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _transcriptSub?.cancel();
    _liveChatService.stopSession();
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: _activeFormData != null
            ? Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildVisualizer(theme, isDark),
                  ),
                  Container(
                    width: 1,
                    color: theme.dividerColor,
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildFormView(),
                  ),
                ],
              )
            : _buildVisualizer(theme, isDark),
      ),
    );
  }

  Widget _buildVisualizer(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.adaptive.arrow_back,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              if (_transcriptEntries.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showTranscript ? Icons.chat : Icons.chat_bubble_outline,
                    color: _showTranscript
                        ? _getStatusColor(
                            _liveChatService.currentState)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  tooltip: _showTranscript ? 'hideTranscript'.tr() : 'showTranscript'.tr(),
                  onPressed: () => setState(() => _showTranscript = !_showTranscript),
                ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: StreamBuilder<LiveChatState>(
            stream: _liveChatService.stateStream,
            initialData: _liveChatService.currentState,
            builder: (context, snapshot) {
              final state = snapshot.data!;
              return Column(
                children: [
                  const Spacer(flex: 1),

                  // Animated Orb
                  StreamBuilder<double>(
                    stream: _liveChatService.audioLevelStream,
                    initialData: 0.0,
                    builder: (context, levelSnapshot) {
                      final level = levelSnapshot.data ?? 0.0;
                      return SizedBox(
                        width: 200,
                        height: 200,
                        child: AnimatedBuilder(
                          animation: _visualizerController,
                          builder: (context, _) {
                            final isActive = state == LiveChatState.speaking ||
                                state == LiveChatState.listening ||
                                state == LiveChatState.initializing;
                            return CustomPaint(
                              size: const Size(200, 200),
                              painter: _OrbPainter(
                                audioLevel: level,
                                animationValue: _visualizerController.value,
                                isActive: isActive,
                                color: _getStatusColor(state),
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusIcon(state),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(state),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transcript panel
                  if (_showTranscript && _transcriptEntries.isNotEmpty)
                    _buildTranscriptPanel(theme, isDark),

                  if (state == LiveChatState.error)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => _liveChatService.startSession(),
                        icon: const Icon(Icons.refresh),
                        label: Text('retryConnection'.tr()),
                      ),
                    ),

                  const Spacer(flex: 1),

                  // End call button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptPanel(ThemeData theme, bool isDark) {
    // Show last few entries, scrolling
    return Flexible(
      flex: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 160),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          reverse: true,
          itemCount: _transcriptEntries.length,
          itemBuilder: (context, index) {
            final entry = _transcriptEntries[_transcriptEntries.length - 1 - index];
            final isUser = entry.speaker == 'user';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 8, top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white
                              : Colors.black).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUser ? 'youLabel'.tr() : 'aiLabel'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUser
                            ? Colors.blue
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.text,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(LiveChatState state) {
    switch (state) {
      case LiveChatState.listening:
        return const Icon(Icons.mic, color: Colors.blueAccent, size: 16);
      case LiveChatState.processing:
        return const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.purpleAccent));
      case LiveChatState.speaking:
        return const Icon(Icons.volume_up, color: Colors.greenAccent, size: 16);
      case LiveChatState.error:
        return const Icon(Icons.error_outline, color: Colors.redAccent, size: 16);
      default:
        return const Icon(Icons.circle, color: Colors.grey, size: 16);
    }
  }

  String _getStatusText(LiveChatState state) {
    switch (state) {
      case LiveChatState.initializing:
        return "initializingStatus".tr();
      case LiveChatState.listening:
        return "listeningStatus".tr();
      case LiveChatState.processing:
        return "thinkingStatus".tr();
      case LiveChatState.speaking:
        return "speakingStatus".tr();
      case LiveChatState.error:
        return "connectionError".tr();
      case LiveChatState.idle:
        return "readyStatus".tr();
    }
  }

  Color _getStatusColor(LiveChatState state) {
    switch (state) {
      case LiveChatState.initializing:
        return Colors.orangeAccent;
      case LiveChatState.listening:
        return Colors.blueAccent;
      case LiveChatState.processing:
        return Colors.purpleAccent;
      case LiveChatState.speaking:
        return Colors.greenAccent;
      case LiveChatState.error:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFormView() {
    if (_activeFormType == null || _activeFormData == null) {
      return const SizedBox();
    }

    Widget formWidget;
    if (_activeFormType == 'add_patient' || _activeFormType == 'edit_patient') {
      PatientModel? patient;
      if (_activeFormType == 'edit_patient' && _activeFormData!['id'] != null) {
        patient = PatientModel(
          id: _activeFormData!['id'],
          name: _activeFormData!['name'] ?? '',
          age: _activeFormData!['age'] is int
              ? _activeFormData!['age']
              : int.tryParse(_activeFormData!['age']?.toString() ?? ''),
          gender: _activeFormData!['gender'],
          address: _activeFormData!['address'],
          phone1: _activeFormData!['phone1'],
          phone2: _activeFormData!['phone2'],
          treatingDoctorId: _activeFormData!['treatingDoctor'],
          occupation: _activeFormData!['occupation'],
          ownerId: '',
          clinicId: '',
          createdAt: Timestamp.now(),
        );
      }
      formWidget = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AddPatientPage(
          initialData: _activeFormData!,
          patient: patient,
          showScaffold: false,
          onSuccess: () {
            _closeForm();
            _liveChatService.speak(patient != null
                ? "patientUpdated".tr()
                : "patientAddedSuccessfully".tr());
          },
          onCancel: _closeForm,
          onFormDataChange: (data) {
            _activeFormData = data;
          },
        ),
      );
    } else if (_activeFormType == 'add_session' || _activeFormType == 'edit_session') {
      SessionModel? session;
      if (_activeFormType == 'edit_session' && _activeFormData!['id'] != null) {
        session = SessionModel(
          id: _activeFormData!['id'],
          patientId: _activeFormData!['patientId'] ?? '',
          startDateTime: _activeFormData!['startDateTime'] ?? Timestamp.now(),
          endDateTime: _activeFormData!['endDateTime'] ?? Timestamp.now(),
          price: (_activeFormData!['price'] ?? 0).toDouble(),
          ownerId: '',
          clinicId: '',
          createdBy: '',
          createdAt: Timestamp.now(),
        );
      }
      formWidget = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AddSessionPage(
          initialData: _activeFormData,
          session: session,
          showScaffold: false,
          onSuccess: () {
            _closeForm();
            _liveChatService.speak(session != null
                ? "sessionUpdated".tr()
                : "sessionAdded".tr());
          },
          onCancel: _closeForm,
          onFormDataChange: (data) => _activeFormData = data,
        ),
      );
    } else if (_activeFormType == 'add_evaluation' || _activeFormType == 'edit_evaluation') {
      EvaluationModel? evaluation;
      if (_activeFormType == 'edit_evaluation' && _activeFormData!['id'] != null) {
        evaluation = EvaluationModel(
          id: _activeFormData!['id'],
          patientId: _activeFormData!['patientId'] ?? '',
          patientName: _activeFormData!['patientName'] ?? '',
          startDateTime: _activeFormData!['startDateTime'] ?? Timestamp.now(),
          endDateTime: _activeFormData!['endDateTime'] ?? Timestamp.now(),
          price: (_activeFormData!['price'] ?? 0).toDouble(),
          ownerId: '',
          clinicId: '',
          createdBy: '',
          createdAt: Timestamp.now(),
        );
      }
      formWidget = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AddEvaluationPage(
          initialData: _activeFormData,
          evaluation: evaluation,
          showScaffold: false,
          onSuccess: () {
            _closeForm();
            _liveChatService.speak(evaluation != null
                ? "evaluationUpdated".tr()
                : "evaluationAddedSuccessfully".tr());
          },
          onCancel: _closeForm,
          onFormDataChange: (data) => _activeFormData = data,
        ),
      );
    } else {
      formWidget = Center(
        child: Text('formNotImplemented'.tr(args: [_activeFormType ?? ''])),
      );
    }

    return formWidget;
  }

  void _closeForm() {
    setState(() {
      _activeFormType = null;
      _activeFormData = null;
    });
    _liveChatService.resume();
  }
}

class _TranscriptEntry {
  final String speaker;
  final String text;

  _TranscriptEntry({required this.speaker, required this.text});
}

class _OrbPainter extends CustomPainter {
  final double audioLevel;
  final double animationValue;
  final bool isActive;
  final Color color;
  final bool isDark;

  _OrbPainter({
    required this.audioLevel,
    required this.animationValue,
    required this.isActive,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.5;

    // Glow effect
    if (isActive) {
      for (int i = 5; i >= 1; i--) {
        final glowRadius = maxRadius +
            (sin((animationValue * 2 * pi) + (i * 0.5)) * 15 + 15) * i * 0.3 +
            audioLevel * 20 * i * 0.2;
        final glowOpacity = (0.08 / i) * (isActive ? 1.0 : 0.3);
        final glowPaint = Paint()
          ..color = color.withValues(alpha: glowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(center, glowRadius, glowPaint);
      }
    }

    // Outer ring dots
    final dotCount = 24;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * pi + animationValue * 2 * pi;
      final wobble = isActive ? sin(animationValue * 4 * pi + i * 0.7) * 8 : 0.0;
      final dotRadius = maxRadius - 5 + wobble + audioLevel * 15;
      final x = center.dx + cos(angle) * dotRadius;
      final y = center.dy + sin(angle) * dotRadius;
      final dotSize = (isActive ? 3.0 : 2.0) + audioLevel * 3;
      final dotPaint = Paint()
        ..color = color.withValues(
          alpha: (0.4 + (sin(animationValue * 2 * pi + i * 0.3) * 0.3 + 0.3) +
              audioLevel * 0.3),
        );
      canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
    }

    // Middle ring dots
    final midDotCount = 16;
    for (int i = 0; i < midDotCount; i++) {
      final angle = (i / midDotCount) * 2 * pi - animationValue * 1.5 * pi;
      final wobble = isActive ? sin(-animationValue * 3 * pi + i * 0.9) * 5 : 0.0;
      final dotRadius = maxRadius * 0.6 + wobble + audioLevel * 10;
      final x = center.dx + cos(angle) * dotRadius;
      final y = center.dy + sin(angle) * dotRadius;
      final dotPaint = Paint()
        ..color = color.withValues(
          alpha: (0.3 + (sin(-animationValue * 1.5 * pi + i * 0.5) * 0.2 + 0.3) +
              audioLevel * 0.2),
        );
      canvas.drawCircle(Offset(x, y), 2.5 + audioLevel * 2, dotPaint);
    }

    // Inner ring dots
    final innerDotCount = 8;
    for (int i = 0; i < innerDotCount; i++) {
      final angle = (i / innerDotCount) * 2 * pi + animationValue * pi;
      final dotRadius = maxRadius * 0.25 + audioLevel * 8;
      final x = center.dx + cos(angle) * dotRadius;
      final y = center.dy + sin(angle) * dotRadius;
      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.6 + audioLevel * 0.3);
      canvas.drawCircle(Offset(x, y), 3 + audioLevel * 3, dotPaint);
    }

    // Center dot
    final centerSize = 4 + audioLevel * 4;
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.9);
    canvas.drawCircle(center, centerSize, centerPaint);
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) {
    return oldDelegate.audioLevel != audioLevel ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive ||
        oldDelegate.color != color;
  }
}
