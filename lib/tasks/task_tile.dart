import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/widgets/rich_text_description.dart';
import 'package:yourtasks/tasks/task_item.dart';
import 'package:yourtasks/tasks/task_priority.dart';

class TaskTile extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const TaskTile({super.key, required this.task, required this.onTap});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final brightness = theme.brightness;
    final bool isOverdue = widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;

    final priorityColor = widget.task.priority.color(brightness);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isCompleting ? 0.0 : 1.0,
        child: Card(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          borderRadius: BorderRadius.circular(6),
          child: ListTile(
            onPressed: widget.onTap,
            leading: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: IconButton(
                icon: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          widget.task.isCompleted ? Colors.grey : priorityColor,
                      width: 2,
                    ),
                    color: widget.task.isCompleted
                        ? Colors.grey.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  child: widget.task.isCompleted
                      ? const Icon(FluentIcons.check_mark,
                          size: 14, color: Colors.grey)
                      : _isHovering
                          ? Icon(FluentIcons.check_mark,
                              size: 14, color: priorityColor.withOpacity(0.5))
                          : null,
                ),
                onPressed: () {
                  setState(() => _isCompleting = true);
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) {
                      context
                          .read<AppState>()
                          .toggleTaskCompletion(widget.task.id);
                    }
                  });
                },
              ),
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration:
                    widget.task.isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: RichTextDescription(
                      text: widget.task.description,
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                if (widget.task.dueDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      children: [
                        Icon(FluentIcons.calendar,
                            size: 12,
                            color: isOverdue ? Colors.red : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy - HH:mm')
                              .format(widget.task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? Colors.red : Colors.green,
                            fontWeight:
                                isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
            trailing: _isHovering && !widget.task.isCompleted
                ? IconButton(
                    icon: const Icon(FluentIcons.edit, size: 16),
                    onPressed: widget.onTap,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}