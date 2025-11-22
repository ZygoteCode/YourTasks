import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/tasks/task_item.dart';
import 'package:yourtasks/tasks/task_priority.dart';
import 'package:yourtasks/widgets/tool_bar_btn.dart';

class TaskEditorDialog extends StatefulWidget {
  final TaskItem? task;
  final String? defaultProjectId;

  const TaskEditorDialog({super.key, this.task, this.defaultProjectId});

  @override
  State<TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<TaskEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDate;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController =
        TextEditingController(text: widget.task?.description ?? '');
    _selectedPriority = widget.task?.priority ?? TaskPriority.p1;
    _selectedDate = widget.task?.dueDate;
    _selectedProjectId = widget.task?.projectId ?? widget.defaultProjectId;
  }

  void _applyFormat(String startTag, String endTag) {
    final text = _descController.text;
    final selection = _descController.selection;

    if (selection.start < 0 || selection.end < 0) return;

    final newText = text.replaceRange(selection.start, selection.end,
        '$startTag${text.substring(selection.start, selection.end)}$endTag');

    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
          offset: selection.end + startTag.length + endTag.length),
    );
  }

  void _pickDateTime(BuildContext context) async {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    
    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text("Select Date & Time"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DatePicker(
                selected: tempDate,
                onChanged: (v) => tempDate = v,
              ),
              const SizedBox(height: 12),
              TimePicker(
                selected: tempDate,
                onChanged: (v) => tempDate = v,
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text("Confirm"),
              onPressed: () {
                setState(() => _selectedDate = tempDate);
                Navigator.pop(context);
              },
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 650),
      title: Text(widget.task == null ? 'Add task' : 'Modify task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextBox(
            controller: _titleController,
            placeholder: 'Name of the task',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            cursorColor: Colors.blue,
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: theme.resources.dividerStrokeColorDefault),
              borderRadius: BorderRadius.circular(4),
              color: theme.resources.controlFillColorDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorSecondary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      ToolbarBtn(
                          icon: FluentIcons.bold,
                          tooltip: 'Bold',
                          onTap: () => _applyFormat('**', '**')),
                      const SizedBox(width: 4),
                      ToolbarBtn(
                          icon: FluentIcons.italic,
                          tooltip: 'Italic',
                          onTap: () => _applyFormat('_', '_')),
                      const SizedBox(width: 4),
                      ToolbarBtn(
                          icon: FluentIcons.embed,
                          tooltip: 'Code',
                          onTap: () => _applyFormat('`', '`')),
                    ],
                  ),
                ),
                const Divider(),
                TextBox(
                  controller: _descController,
                  placeholder: 'Description...',
                  maxLines: 15,
                  minLines: 3,
                  decoration: WidgetStateProperty.all(BoxDecoration(
                      border: Border.all(color: Colors.transparent))),
                  highlightColor: Colors.transparent,
                  unfocusedColor: Colors.transparent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Button(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.calendar,
                        color: _selectedDate != null ? Colors.green : null,
                        size: 14),
                    const SizedBox(width: 8),
                    Text(_selectedDate == null
                        ? 'Expiration date'
                        : DateFormat('dd/MM/yyyy HH:mm')
                            .format(_selectedDate!)),
                  ],
                ),
                onPressed: () => _pickDateTime(context),
              ),
              DropDownButton(
                title: Row(
                  children: [
                    Icon(FluentIcons.flag,
                        color: _selectedPriority.color(theme.brightness),
                        size: 14),
                    const SizedBox(width: 8),
                    Text(_selectedPriority.label),
                  ],
                ),
                items: TaskPriority.values
                    .map((e) => MenuFlyoutItem(
                          text: Text(e.label),
                          leading: Icon(FluentIcons.flag,
                              color: e.color(theme.brightness), size: 14),
                          onPressed: () =>
                              setState(() => _selectedPriority = e),
                        ))
                    .toList(),
              ),
              if (appState.projects.isNotEmpty)
                ComboBox<String>(
                  placeholder: const Text('Project'),
                  value: _selectedProjectId,
                  items: appState.projects
                      .map((p) => ComboBoxItem(
                            value: p.id,
                            child: Row(
                              children: [
                                Icon(FluentIcons.circle_shape_solid,
                                    color: p.color, size: 10),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedProjectId = value),
                ),
            ],
          )
        ],
      ),
      actions: [
        if (widget.task != null)
          Button(
            style: ButtonStyle(foregroundColor: ButtonState.all(Colors.red)),
            onPressed: () {
              context.read<AppState>().deleteTask(widget.task!.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(
          child: const Text('Save'),
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final newTask = TaskItem(
                id: widget.task?.id ?? const Uuid().v4(),
                title: _titleController.text,
                description: _descController.text,
                priority: _selectedPriority,
                dueDate: _selectedDate,
                projectId: _selectedProjectId,
                isCompleted: widget.task?.isCompleted ?? false,
              );

              if (widget.task == null) {
                context.read<AppState>().addTask(newTask);
              } else {
                context.read<AppState>().updateTask(newTask);
              }
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}