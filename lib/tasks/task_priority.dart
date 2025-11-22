import 'package:fluent_ui/fluent_ui.dart';

enum TaskPriority {
  p1,
  p2,
  p3,
  p4,
}

extension TaskPriorityExt on TaskPriority {
  Color color(Brightness brightness) {
    switch (this) {
      case TaskPriority.p1:
        return Colors.red;
      case TaskPriority.p2:
        return Colors.orange;
      case TaskPriority.p3:
        return Colors.blue;
      case TaskPriority.p4:
        return brightness == Brightness.dark
            ? Colors.white
            : const Color.fromARGB(255, 150, 150, 150);
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.p1:
        return 'Priority 1';
      case TaskPriority.p2:
        return 'Priority 2';
      case TaskPriority.p3:
        return 'Priority 3';
      case TaskPriority.p4:
        return 'Priority 4';
    }
  }
}