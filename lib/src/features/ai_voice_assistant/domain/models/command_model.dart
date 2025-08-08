import 'package:equatable/equatable.dart';

class Command extends Equatable {
  final String intent;
  final Map<String, dynamic> entities;

  const Command({required this.intent, required this.entities});

  factory Command.fromJson(Map<String, dynamic> json) {
    return Command(
      intent: json['intent'],
      entities: Map<String, dynamic>.from(json['entities']),
    );
  }

  @override
  List<Object?> get props => [intent, entities];
}
