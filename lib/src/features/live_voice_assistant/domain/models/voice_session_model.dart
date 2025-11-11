import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'voice_message_model.dart';

part 'voice_session_model.g.dart';

/// Enum for voice session status
enum VoiceSessionStatus {
  idle,
  listening,
  processing,
  speaking,
  paused,
  ended,
  error
}

/// Converter for VoiceSessionStatus enum
class VoiceSessionStatusConverter
    implements JsonConverter<VoiceSessionStatus, String> {
  const VoiceSessionStatusConverter();

  @override
  VoiceSessionStatus fromJson(String json) {
    return VoiceSessionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => VoiceSessionStatus.idle,
    );
  }

  @override
  String toJson(VoiceSessionStatus object) {
    return object.toString().split('.').last;
  }
}

/// Model representing a live voice conversation session
@JsonSerializable()
class VoiceSessionModel {
  final String id;
  final String userId;
  final String? title;

  @VoiceSessionStatusConverter()
  final VoiceSessionStatus status;

  @TimestampConverter()
  final Timestamp startTime;

  @TimestampConverter()
  final Timestamp? endTime;

  final List<VoiceMessageModel> messages;
  final Map<String, dynamic> context;
  final String? selectedAiModel;
  final bool isActive;
  final int messageCount;
  final double? totalDuration;

  const VoiceSessionModel({
    required this.id,
    required this.userId,
    this.title,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.messages,
    required this.context,
    this.selectedAiModel,
    required this.isActive,
    required this.messageCount,
    this.totalDuration,
  });

  factory VoiceSessionModel.fromJson(Map<String, dynamic> json) =>
      _$VoiceSessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionModelToJson(this);

  VoiceSessionModel copyWith({
    String? id,
    String? userId,
    String? title,
    VoiceSessionStatus? status,
    Timestamp? startTime,
    Timestamp? endTime,
    List<VoiceMessageModel>? messages,
    Map<String, dynamic>? context,
    String? selectedAiModel,
    bool? isActive,
    int? messageCount,
    double? totalDuration,
  }) {
    return VoiceSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      selectedAiModel: selectedAiModel ?? this.selectedAiModel,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  /// Create a new voice session
  factory VoiceSessionModel.create({
    required String id,
    required String userId,
    String? title,
    String? selectedAiModel,
  }) {
    return VoiceSessionModel(
      id: id,
      userId: userId,
      title: title ??
          'Voice Session ${DateTime.now().toString().substring(0, 16)}',
      status: VoiceSessionStatus.idle,
      startTime: Timestamp.now(),
      messages: [],
      context: {},
      selectedAiModel: selectedAiModel ?? 'Gemini',
      isActive: true,
      messageCount: 0,
    );
  }

  /// Add a message to the session
  VoiceSessionModel addMessage(VoiceMessageModel message) {
    final updatedMessages = List<VoiceMessageModel>.from(messages)
      ..add(message);
    return copyWith(
      messages: updatedMessages,
      messageCount: updatedMessages.length,
    );
  }

  /// Update the last message in the session
  VoiceSessionModel updateLastMessage(VoiceMessageModel message) {
    if (messages.isEmpty) return addMessage(message);

    final updatedMessages = List<VoiceMessageModel>.from(messages);
    updatedMessages[updatedMessages.length - 1] = message;

    return copyWith(messages: updatedMessages);
  }

  /// Update session status
  VoiceSessionModel updateStatus(VoiceSessionStatus newStatus) {
    return copyWith(status: newStatus);
  }

  /// End the session
  VoiceSessionModel endSession() {
    return copyWith(
      status: VoiceSessionStatus.ended,
      endTime: Timestamp.now(),
      isActive: false,
    );
  }

  /// Update context with new data
  VoiceSessionModel updateContext(Map<String, dynamic> newContext) {
    final updatedContext = Map<String, dynamic>.from(context)
      ..addAll(newContext);
    return copyWith(context: updatedContext);
  }

  /// Get the last message
  VoiceMessageModel? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  /// Get user messages only
  List<VoiceMessageModel> get userMessages =>
      messages.where((m) => m.isUserMessage).toList();

  /// Get assistant messages only
  List<VoiceMessageModel> get assistantMessages =>
      messages.where((m) => m.isAssistantMessage).toList();

  /// Get action messages only
  List<VoiceMessageModel> get actionMessages =>
      messages.where((m) => m.isAction).toList();

  /// Check if session is currently active
  bool get isCurrentlyActive => isActive && status != VoiceSessionStatus.ended;

  /// Check if session is in a voice interaction state
  bool get isInVoiceMode =>
      status == VoiceSessionStatus.listening ||
      status == VoiceSessionStatus.speaking ||
      status == VoiceSessionStatus.processing;

  /// Get session duration in minutes
  double get durationInMinutes {
    final end = endTime ?? Timestamp.now();
    final duration =
        end.millisecondsSinceEpoch - startTime.millisecondsSinceEpoch;
    return duration / (1000 * 60); // Convert to minutes
  }

  /// Generate a summary title based on messages
  String generateTitle() {
    if (messages.isEmpty) return 'New Voice Session';

    final firstUserMessage =
        userMessages.isNotEmpty ? userMessages.first.content : '';
    if (firstUserMessage.isNotEmpty) {
      // Take first 30 characters and add ellipsis if longer
      return firstUserMessage.length > 30
          ? '${firstUserMessage.substring(0, 30)}...'
          : firstUserMessage;
    }

    return 'Voice Session ${startTime.toDate().toString().substring(0, 16)}';
  }
}
