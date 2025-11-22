import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

const String appTitle = 'YourTasks';

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

final List<Color> projectColors = [
  Colors.blue,
  Colors.red,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.magenta,
  Colors.grey,
];

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

  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name, 
    'colorValue': colorValue
  };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      colorValue: json['colorValue'] ?? 0xFF0078D7,
    );
  }
}

class AppState extends ChangeNotifier {
  List<TaskItem> _tasks = [];
  List<Project> _projects = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  List<TaskItem> get tasks => _tasks;
  List<Project> get projects => _projects;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  List<TaskItem> get inboxTasks => _tasks.where((t) => !t.isCompleted && t.projectId == null).toList();
  List<TaskItem> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  
  List<TaskItem> getProjectTasks(String projectId) {
    return _tasks.where((t) => !t.isCompleted && t.projectId == projectId).toList();
  }

  AppState() {
    _loadData();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void addTask(TaskItem task) {
    _tasks.add(task);
    _saveData();
    notifyListeners();
  }

  void updateTask(TaskItem task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveData();
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _saveData();
      notifyListeners();
    }
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    _saveData();
    notifyListeners();
  }

  void addProject(String name) {
    _projects.add(Project(id: const Uuid().v4(), name: name));
    _saveData();
    notifyListeners();
  }

  void updateProject(String id, String newName, int newColorValue) {
    final index = _projects.indexWhere((p) => p.id == id);
    if (index != -1) {
      _projects[index] = Project(id: id, name: newName, colorValue: newColorValue);
      _saveData();
      notifyListeners();
    }
  }

  void deleteProject(String projectId) {
    _projects.removeWhere((p) => p.id == projectId);
    for (var t in _tasks) {
      if (t.projectId == projectId) t.projectId = null;
    }
    _saveData();
    notifyListeners();
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/yourtasks_data.json';
  }

  Future<void> _saveData() async {
    try {
      final path = await _getFilePath();
      final File file = File(path);
      final data = {
        'tasks': _tasks.map((e) => e.toJson()).toList(),
        'projects': _projects.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final path = await _getFilePath();
      final File file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        if (data['tasks'] != null) {
          _tasks = (data['tasks'] as List).map((e) => TaskItem.fromJson(e)).toList();
        }
        if (data['projects'] != null) {
          _projects = (data['projects'] as List).map((e) => Project.fromJson(e)).toList();
        }
      } else {
        _tasks = [
          TaskItem(id: const Uuid().v4(), title: 'Welcome to YourTasks!', description: 'Explore features.\n**Bold** and `code` supported!', priority: TaskPriority.p1),
        ];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    title: "YourTasks",
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setIcon('assets/icon.ico');
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const YourTasksApp(),
    ),
  );
}

class YourTasksApp extends StatelessWidget {
  const YourTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return FluentApp(
      title: appTitle,
      themeMode: appState.themeMode,
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        fontFamily: 'Segoe UI',
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        fontFamily: 'Segoe UI',
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int topIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    if (appState.isLoading) {
      return const Center(child: ProgressRing());
    }

    List<NavigationPaneItem> items = [
      PaneItem(
        icon: const Icon(FluentIcons.inbox),
        title: const Text('Upcoming tasks'),
        body: const TaskListPage(filterType: 'inbox'),
      ),
      PaneItem(
        icon: const Icon(FluentIcons.checkbox_composite),
        title: const Text('Completed'),
        body: const TaskListPage(filterType: 'completed'),
      ),
      PaneItemSeparator(),
      PaneItemHeader(header: const Text('PROJECTS')),
    ];

    for (var project in appState.projects) {
      items.add(PaneItem(
        icon: Icon(FluentIcons.circle_shape_solid, color: project.color),
        title: Text(project.name),
        body: TaskListPage(filterType: 'project', projectId: project.id),
      ));
    }

    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text(
          appTitle, 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
        ),
        automaticallyImplyLeading: false,
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Tooltip(
              message: "New project",
              child: IconButton(
                icon: const Icon(FluentIcons.add_group),
                onPressed: () => _showAddProjectDialog(context),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(appState.themeMode == ThemeMode.dark 
                  ? FluentIcons.sunny 
                  : FluentIcons.clear_night),
              onPressed: () => appState.toggleTheme(),
            ),
            const SizedBox(width: 20),
          ],
        )
      ),
      pane: NavigationPane(
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.compact,
        items: items,
        footerItems: [],
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('New project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Name"),
              const SizedBox(height: 8),
              TextBox(
                controller: controller,
                placeholder: 'Example: work, home, ...',
                maxLines: 1
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              child: const Text('Create'),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<AppState>().addProject(controller.text);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      }
    );
  }
}

class TaskListPage extends StatelessWidget {
  final String filterType; 
  final String? projectId;

  const TaskListPage({super.key, required this.filterType, this.projectId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    List<TaskItem> tasksToShow = [];
    String headerTitle = "";
    Project? currentProject;

    switch (filterType) {
      case 'inbox':
        tasksToShow = appState.inboxTasks;
        headerTitle = "Upcoming tasks";
        break;
      case 'completed':
        tasksToShow = appState.completedTasks;
        headerTitle = "Completed";
        break;
      case 'project':
        if (projectId != null) {
          tasksToShow = appState.getProjectTasks(projectId!);
          try {
            currentProject = appState.projects.firstWhere((p) => p.id == projectId);
            headerTitle = currentProject.name;
          } catch (e) {
            headerTitle = "Project not found";
          }
        }
        break;
    }

    tasksToShow.sort((a, b) {
      int priorityComp = a.priority.index.compareTo(b.priority.index);
      if (priorityComp != 0) return priorityComp;
      
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            if (currentProject != null) 
               Padding(
                 padding: const EdgeInsets.only(right: 12.0),
                 child: Icon(FluentIcons.circle_shape_solid, color: currentProject.color, size: 18),
               ),
            Text(headerTitle),
          ],
        ),
        commandBar: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentProject != null)
              Tooltip(
                message: "Modify project",
                child: IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () => _showProjectOptions(context, currentProject!),
                ),
              ),
            const SizedBox(width: 8),
            if (filterType != 'completed')
              FilledButton(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add),
                    SizedBox(width: 8),
                    Text('Add task'),
                  ],
                ),
                onPressed: () => _showTaskDialog(context, null, projectId),
              ),
          ],
        ),
      ),
      content: tasksToShow.isEmpty 
        ? _buildEmptyState(context, filterType)
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasksToShow.length,
            itemBuilder: (context, index) {
              final task = tasksToShow[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TaskTile(
                  key: ValueKey(task.id),
                  task: task,
                  onTap: () => _showTaskDialog(context, task, null),
                ),
              );
            },
          ),
    );
  }

  void _showProjectOptions(BuildContext context, Project project) {
    showDialog(
      context: context, 
      builder: (context) => ProjectSettingsDialog(project: project)
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'completed' ? FluentIcons.checkbox_composite : FluentIcons.post_update, 
            size: 64, 
            color: Colors.grey
          ),
          const SizedBox(height: 20),
          Text(
            type == 'completed' ? 'No tasks completed yet!' : 'Everything has been done! Relax yourself.',
            style: FluentTheme.of(context).typography.subtitle,
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, TaskItem? existingTask, String? defaultProjectId) {
    showDialog(
      context: context,
      builder: (_) => TaskEditorDialog(task: existingTask, defaultProjectId: defaultProjectId),
    );
  }
}

class ProjectSettingsDialog extends StatefulWidget {
  final Project project;
  const ProjectSettingsDialog({super.key, required this.project});

  @override
  State<ProjectSettingsDialog> createState() => _ProjectSettingsDialogState();
}

class _ProjectSettingsDialogState extends State<ProjectSettingsDialog> {
  late TextEditingController _nameCtrl;
  late int _selectedColorValue;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _selectedColorValue = widget.project.colorValue;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text("Modify project"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Project name"),
          const SizedBox(height: 8),
          TextBox(controller: _nameCtrl, maxLines: 1),
          const SizedBox(height: 16),
          const Text("Color"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: projectColors.map((c) {
              final bool isSelected = c.value == _selectedColorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorValue = c.value),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: FluentTheme.of(context).accentColor, width: 3) : null,
                  ),
                  child: isSelected ? const Icon(FluentIcons.check_mark, color: Colors.white, size: 16) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 10),
          HyperlinkButton(
            child: Text("Delete project", style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<AppState>().deleteProject(widget.project.id);
              Navigator.pop(context); 
            },
          )
        ],
      ),
      actions: [
        Button(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
        FilledButton(
          child: const Text("Save"), 
          onPressed: () {
            if (_nameCtrl.text.isNotEmpty) {
              context.read<AppState>().updateProject(widget.project.id, _nameCtrl.text, _selectedColorValue);
              Navigator.pop(context);
            }
          }
        )
      ],
    );
  }
}

class TaskTile extends StatefulWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const TaskTile({super.key, required this.task, required this.onTap});

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> with SingleTickerProviderStateMixin {
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
                      color: widget.task.isCompleted ? Colors.grey : priorityColor,
                      width: 2,
                    ),
                    color: widget.task.isCompleted ? Colors.grey.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: widget.task.isCompleted 
                    ? const Icon(FluentIcons.check_mark, size: 14, color: Colors.grey)
                    : _isHovering 
                        ? Icon(FluentIcons.check_mark, size: 14, color: priorityColor.withOpacity(0.5))
                        : null,
                ),
                onPressed: () {
                  setState(() => _isCompleting = true);
                  Future.delayed(const Duration(milliseconds: 350), () {
                     if (mounted) context.read<AppState>().toggleTaskCompletion(widget.task.id);
                  });
                },
              ),
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
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
                        Icon(FluentIcons.calendar, size: 12, color: isOverdue ? Colors.red : Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy - HH:mm').format(widget.task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? Colors.red : Colors.green,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
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

class RichTextDescription extends StatelessWidget {
  final String text;
  final Color color;

  const RichTextDescription({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: color, fontSize: 13, fontFamily: 'Segoe UI'),
        children: _parseMarkdown(text, context),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> _parseMarkdown(String text, BuildContext context) {
    List<InlineSpan> spans = [];
    final regex = RegExp(r'(\*\*[^*]+\*\*)|(__[^_]+__)|(`[^`]+`)|(\*[^*]+\*)|(_[^_]+_)');
    
    int start = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      String matchText = match.group(0)!;
      
      if (matchText.startsWith('**') || matchText.startsWith('__')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ));
      } else if (matchText.startsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              matchText.substring(1, matchText.length - 1),
              style: const TextStyle(fontFamily: 'Consolas', fontSize: 11),
            ),
          ),
        ));
      } else if (matchText.startsWith('*') || matchText.startsWith('_')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
}

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
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _selectedPriority = widget.task?.priority ?? TaskPriority.p1;
    _selectedDate = widget.task?.dueDate;
    _selectedProjectId = widget.task?.projectId ?? widget.defaultProjectId;
  }

  void _applyFormat(String startTag, String endTag) {
    final text = _descController.text;
    final selection = _descController.selection;

    if (selection.start < 0 || selection.end < 0) return;

    final newText = text.replaceRange(
      selection.start, 
      selection.end, 
      '$startTag${text.substring(selection.start, selection.end)}$endTag'
    );

    _descController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.end + startTag.length + endTag.length),
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
              border: Border.all(color: theme.resources.dividerStrokeColorDefault),
              borderRadius: BorderRadius.circular(4),
              color: theme.resources.controlFillColorDefault,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.resources.subtleFillColorSecondary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      _ToolbarBtn(icon: FluentIcons.bold, tooltip: 'Bold', onTap: () => _applyFormat('**', '**')),
                      const SizedBox(width: 4),
                      _ToolbarBtn(icon: FluentIcons.italic, tooltip: 'Italic', onTap: () => _applyFormat('_', '_')),
                      const SizedBox(width: 4),
                      _ToolbarBtn(icon: FluentIcons.embed, tooltip: 'Code', onTap: () => _applyFormat('`', '`')),
                    ],
                  ),
                ),
                const Divider(),
                TextBox(
                  controller: _descController,
                  placeholder: 'Description...',
                  maxLines: 15,
                  minLines: 3,
                  decoration: WidgetStateProperty.all(BoxDecoration(border: Border.all(color: Colors.transparent))),
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
                    Icon(FluentIcons.calendar, color: _selectedDate != null ? Colors.green : null, size: 14),
                    const SizedBox(width: 8),
                    Text(_selectedDate == null 
                      ? 'Expiration date' 
                      : DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!)),
                  ],
                ),
                onPressed: () => _pickDateTime(context),
              ),
              
              DropDownButton(
                title: Row(
                  children: [
                    Icon(FluentIcons.flag, color: _selectedPriority.color(theme.brightness), size: 14),
                    const SizedBox(width: 8),
                    Text(_selectedPriority.label),
                  ],
                ),
                items: TaskPriority.values.map((e) => MenuFlyoutItem(
                  text: Text(e.label),
                  leading: Icon(FluentIcons.flag, color: e.color(theme.brightness), size: 14),
                  onPressed: () => setState(() => _selectedPriority = e),
                )).toList(),
              ),
              
              if (appState.projects.isNotEmpty)
                ComboBox<String>(
                  placeholder: const Text('Project'),
                  value: _selectedProjectId,
                  items: appState.projects.map((p) => ComboBoxItem(
                    value: p.id,
                    child: Row(
                      children: [
                        Icon(FluentIcons.circle_shape_solid, color: p.color, size: 10),
                        const SizedBox(width: 8),
                        Text(p.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedProjectId = value),
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
          child: Text(widget.task == null ? 'Add' : 'Save'),
          onPressed: () {
            if (_titleController.text.isEmpty) return;

            final newTask = TaskItem(
              id: widget.task?.id ?? const Uuid().v4(),
              title: _titleController.text,
              description: _descController.text,
              priority: _selectedPriority,
              dueDate: _selectedDate,
              isCompleted: widget.task?.isCompleted ?? false,
              projectId: _selectedProjectId,
            );

            if (widget.task == null) {
              context.read<AppState>().addTask(newTask);
            } else {
              context.read<AppState>().updateTask(newTask);
            }
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    DateTime tempDate = _selectedDate ?? DateTime.now();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: const Text('Select date and hour'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DatePicker(
                    selected: tempDate,
                    onChanged: (d) => setDialogState(() => tempDate = d),
                  ),
                  const SizedBox(height: 15),
                  TimePicker(
                    selected: tempDate,
                    onChanged: (d) => setDialogState(() => tempDate = d),
                  ),
                ],
              ),
              actions: [
                Button(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                FilledButton(
                  child: const Text('Confirm'),
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
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14),
        onPressed: onTap,
        style: ButtonStyle(
          padding: ButtonState.all(const EdgeInsets.all(6)),
        ),
      ),
    );
  }
}