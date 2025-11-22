import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/projects/project.dart';

final List<Color> projectColors = [
  Color(0xFF1565C0),
  Color(0xFF0288D1),
  Color(0xFF009688),
  Color(0xFF43A047),
  Color(0xFFCDDC39),
  Color(0xFFFFB300),
  Color(0xFFFF7043),
  Color(0xFFD81B60),
];

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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: FluentTheme.of(context).accentColor,
                            width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(FluentIcons.check_mark,
                          color: Colors.white, size: 16)
                      : null,
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
        Button(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context)),
        FilledButton(
            child: const Text("Save"),
            onPressed: () {
              if (_nameCtrl.text.isNotEmpty) {
                context.read<AppState>().updateProject(
                    widget.project.id, _nameCtrl.text, _selectedColorValue);
                Navigator.pop(context);
              }
            })
      ],
    );
  }
}