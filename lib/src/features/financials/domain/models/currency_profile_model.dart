import 'package:json_annotation/json_annotation.dart';

part 'currency_profile_model.g.dart';

@JsonSerializable()
class CurrencyProfileModel {
  final String id;
  final String currency;
  final String name;
  final DateTime? createdAt;

  CurrencyProfileModel({
    required this.id,
    required this.currency,
    required this.name,
    this.createdAt,
  });

  factory CurrencyProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$CurrencyProfileModelToJson(this);

  CurrencyProfileModel copyWith({
    String? id,
    String? currency,
    String? name,
    DateTime? createdAt,
  }) {
    return CurrencyProfileModel(
      id: id ?? this.id,
      currency: currency ?? this.currency,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
