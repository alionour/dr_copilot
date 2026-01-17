import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserSettingsModel extends Equatable {
  final Map<String, dynamic> preferences;
  final String? localeCode;
  final bool? usePremiumModels;
  final bool? isDarkMode;
  final DateTime? lastUpdated;

  const UserSettingsModel({
    this.preferences = const {},
    this.localeCode,
    this.usePremiumModels,
    this.isDarkMode,
    this.lastUpdated,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      localeCode: json['localeCode'] as String?,
      usePremiumModels: json['usePremiumModels'] as bool?,
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
      'usePremiumModels': usePremiumModels,
      'isDarkMode': isDarkMode,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  UserSettingsModel copyWith({
    Map<String, dynamic>? preferences,
    String? localeCode,
    bool? usePremiumModels,
    bool? isDarkMode,
    DateTime? lastUpdated,
  }) {
    return UserSettingsModel(
      preferences: preferences ?? this.preferences,
      localeCode: localeCode ?? this.localeCode,
      usePremiumModels: usePremiumModels ?? this.usePremiumModels,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props =>
      [preferences, localeCode, usePremiumModels, isDarkMode, lastUpdated];
}
