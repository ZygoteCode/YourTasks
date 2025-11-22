import 'package:fluent_ui/fluent_ui.dart';

class Project {
  final String id;
  String name;
  int colorValue;

  Project({
    required this.id,
    required this.name,
    this.colorValue = 0xFF0078D7,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'colorValue': colorValue};

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      colorValue: json['colorValue'] ?? 0xFF0078D7,
    );
  }
}