import 'package:yourtasks/tasks/task_priority.dart';

class TaskItem {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  TaskPriority priority;
  bool isCompleted;
  String? projectId;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.p4,
    this.isCompleted = false,
    this.projectId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate?.toIso8601String(),
    'priority': priority.index,
    'isCompleted': isCompleted,
    'projectId': projectId,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: TaskPriority.values[json['priority'] ?? 3],
      isCompleted: json['isCompleted'] ?? false,
      projectId: json['projectId'],
    );
  }
}