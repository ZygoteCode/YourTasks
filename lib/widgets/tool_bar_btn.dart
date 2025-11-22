import 'package:fluent_ui/fluent_ui.dart';

class ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ToolbarBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 14),
        onPressed: onTap,
        style: ButtonStyle(
          padding: ButtonState.all(const EdgeInsets.all(4)),
        ),
      ),
    );
  }
}