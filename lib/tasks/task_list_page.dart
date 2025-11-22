import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/projects/project.dart';
import 'package:yourtasks/projects/project_settings_dialog.dart';
import 'package:yourtasks/tasks/task_editor_dialog.dart';
import 'package:yourtasks/tasks/task_item.dart';
import 'package:yourtasks/tasks/task_tile.dart';

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
            currentProject =
                appState.projects.firstWhere((p) => p.id == projectId);
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
                child: Icon(FluentIcons.circle_shape_solid,
                    color: currentProject.color, size: 18),
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
                  onPressed: () =>
                      _showProjectOptions(context, currentProject!),
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
        builder: (context) => ProjectSettingsDialog(project: project));
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
              type == 'completed'
                  ? FluentIcons.checkbox_composite
                  : FluentIcons.post_update,
              size: 64,
              color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            type == 'completed'
                ? 'No tasks completed yet!'
                : 'Everything has been done! Relax yourself.',
            style: FluentTheme.of(context).typography.subtitle,
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(
      BuildContext context, TaskItem? existingTask, String? defaultProjectId) {
    showDialog(
      context: context,
      builder: (_) => TaskEditorDialog(
          task: existingTask, defaultProjectId: defaultProjectId),
    );
  }
}