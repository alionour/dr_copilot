import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_message_model.g.dart';

/// Enum for message types in voice conversation
enum MessageType {
  userVoice,
  assistantVoice,
  userText,
  assistantText,
  systemAction,
  error
}

/// Enum for voice message status
enum VoiceMessageStatus {
  recording,
  processing,
  completed,
  failed,
  speaking
}

/// Converter for MessageType enum
class MessageTypeConverter implements JsonConverter<MessageType, String> {
  const MessageTypeConverter();

  @override
  MessageType fromJson(String json) {
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => MessageType.userText,
    );
  }

  @override
  String toJson(MessageType object) {
    return object.toString().split('.').last;
  }
}

/// Converter for VoiceMessageStatus enum
class VoiceMessageStatusConverter implements JsonConverter<VoiceMessageStatus, String> {
  const VoiceMessageStatusConverter();

  @override
  VoiceMessageStatus fromJson(String json) {
    return VoiceMessageStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json,
      orElse: () => VoiceMessageStatus.completed,
    );
  }

  @override
  String toJson(VoiceMessageStatus object) {
    return object.toString().split('.').last;
  }
}

/// Converter for Timestamp
class TimestampConverter implements JsonConverter<Timestamp, dynamic> {
  const TimestampConverter();

  @override
  Timestamp fromJson(dynamic json) {
    if (json is Timestamp) return json;
    if (json is Map<String, dynamic>) {
      return Timestamp(json['_seconds'] ?? 0, json['_nanoseconds'] ?? 0);
    }
    return Timestamp.now();
  }

  @override
  dynamic toJson(Timestamp object) {
    return object;
  }
}

/// Model representing a voice message in the conversation
@JsonSerializable()
class VoiceMessageModel {
  final String id;
  final String sessionId;
  final String content;
  final String? audioPath;
  final double? audioDuration;
  
  @MessageTypeConverter()
  final MessageType type;
  
  @VoiceMessageStatusConverter()
  final VoiceMessageStatus status;
  
  @TimestampConverter()
  final Timestamp timestamp;
  
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final String? errorMessage;
  final bool isProcessing;

  const VoiceMessageModel({
    required this.id,
    required this.sessionId,
    required this.content,
    this.audioPath,
    this.audioDuration,
    required this.type,
    required this.status,
    required this.timestamp,
    this.actionType,
    this.actionData,
    this.errorMessage,
    this.isProcessing = false,
  });

  factory VoiceMessageModel.fromJson(Map<String, dynamic> json) =>
      _$VoiceMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMessageModelToJson(this);

  VoiceMessageModel copyWith({
    String? id,
    String? sessionId,
    String? content,
    String? audioPath,
    double? audioDuration,
    MessageType? type,
    VoiceMessageStatus? status,
    Timestamp? timestamp,
    String? actionType,
    Map<String, dynamic>? actionData,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return VoiceMessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      audioDuration: audioDuration ?? this.audioDuration,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  /// Create a user voice message
  factory VoiceMessageModel.userVoice({
    required String id,
    required String sessionId,
    required String content,
    String? audioPath,
    double? audioDuration,
  }) {
    return VoiceMessageModel(
      id: id,
      sessionId: sessionId,
      content: content,
      audioPath: audioPath,
      audioDuration: audioDuration,
      type: MessageType.userVoice,
      status: VoiceMessageStatus.completed,
      timestamp: Timestamp.now(),
    );
  }

  /// Create an assistant voice message
  factory VoiceMessageModel.assistantVoice({
    required String id,
    required String sessionId,
    required String content,
    String? audioPath,
    double? audioDuration,
  }) {
    return VoiceMessageModel(
      id: id,
      sessionId: sessionId,
      content: content,
      audioPath: audioPath,
      audioDuration: audioDuration,
      type: MessageType.assistantVoice,
      status: VoiceMessageStatus.completed,
      timestamp: Timestamp.now(),
    );
  }

  /// Create a system action message
  factory VoiceMessageModel.systemAction({
    required String id,
    required String sessionId,
    required String content,
    required String actionType,
    Map<String, dynamic>? actionData,
  }) {
    return VoiceMessageModel(
      id: id,
      sessionId: sessionId,
      content: content,
      type: MessageType.systemAction,
      status: VoiceMessageStatus.completed,
      timestamp: Timestamp.now(),
      actionType: actionType,
      actionData: actionData,
    );
  }

  /// Create an error message
  factory VoiceMessageModel.error({
    required String id,
    required String sessionId,
    required String errorMessage,
  }) {
    return VoiceMessageModel(
      id: id,
      sessionId: sessionId,
      content: 'Error occurred',
      type: MessageType.error,
      status: VoiceMessageStatus.failed,
      timestamp: Timestamp.now(),
      errorMessage: errorMessage,
    );
  }

  /// Check if this is a user message
  bool get isUserMessage => type == MessageType.userVoice || type == MessageType.userText;

  /// Check if this is an assistant message
  bool get isAssistantMessage => type == MessageType.assistantVoice || type == MessageType.assistantText;

  /// Check if this message has audio
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  /// Check if this is an action message
  bool get isAction => type == MessageType.systemAction;

  /// Check if this is an error message
  bool get isError => type == MessageType.error;
}
