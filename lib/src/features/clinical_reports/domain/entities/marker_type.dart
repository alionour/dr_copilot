import 'package:equatable/equatable.dart';

class MarkerType extends Equatable {
  final String id;
  final String name;
  final int iconCodePoint; // Material Icon code point
  final String iconFontFamily; // 'MaterialIcons' or custom font
  final String color; // Hex color string
  final bool isBuiltIn; // True for predefined types (pain, injury, etc.)

  const MarkerType({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily = 'MaterialIcons',
    required this.color,
    this.isBuiltIn = false,
  });

  /// Built-in marker types
  static const List<MarkerType> builtInTypes = [
    MarkerType(
      id: 'pain',
      name: 'Pain',
      iconCodePoint: 0xe55b, // Icons.location_on
      color: '#D32F2F',
      isBuiltIn: true,
    ),
    MarkerType(
      id: 'injury',
      name: 'Injury',
      iconCodePoint: 0xf04f3, // Icons.healing
      color: '#F57C00',
      isBuiltIn: true,
    ),
    MarkerType(
      id: 'rash',
      name: 'Rash',
      iconCodePoint: 0xe91b, // Icons.bubble_chart
      color: '#7B1FA2',
      isBuiltIn: true,
    ),
    MarkerType(
      id: 'scar',
      name: 'Scar',
      iconCodePoint: 0xef4d, // Icons.linear_scale
      color: '#616161',
      isBuiltIn: true,
    ),
    MarkerType(
      id: 'other',
      name: 'Other',
      iconCodePoint: 0xe55b, // Icons.location_on
      color: '#1976D2',
      isBuiltIn: true,
    ),
  ];

  MarkerType copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    String? color,
    bool? isBuiltIn,
  }) {
    return MarkerType(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      color: color ?? this.color,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'color': color,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory MarkerType.fromJson(Map<String, dynamic> json) {
    return MarkerType(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      iconFontFamily: json['iconFontFamily'] as String? ?? 'MaterialIcons',
      color: json['color'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, iconCodePoint, iconFontFamily, color, isBuiltIn];
}
