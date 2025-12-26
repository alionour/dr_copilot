import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserSettingsModel extends Equatable {
  final Map<String, dynamic> preferences;
  final String? localeCode;
  final bool? isDarkMode;
  final DateTime? lastUpdated;

  const UserSettingsModel({
    this.preferences = const {},
    this.localeCode,
    this.isDarkMode,
    this.lastUpdated,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      localeCode: json['localeCode'] as String?,
      isDarkMode: json['isDarkMode'] as bool?,
      lastUpdated: json['lastUpdated'] is Timestamp
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferences': preferences,
      'localeCode': localeCode,
      'isDarkMode': isDarkMode,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  UserSettingsModel copyWith({
    Map<String, dynamic>? preferences,
    String? localeCode,
    bool? isDarkMode,
    DateTime? lastUpdated,
  }) {
    return UserSettingsModel(
      preferences: preferences ?? this.preferences,
      localeCode: localeCode ?? this.localeCode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [preferences, localeCode, isDarkMode, lastUpdated];
}
