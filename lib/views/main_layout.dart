import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/tasks/task_list_page.dart';

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
          title: const Text("YourTasks",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
          )),
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
                    maxLines: 1),
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
        });
  }
}