import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';
import 'package:yourtasks/views/login_page.dart';
import 'package:yourtasks/views/main_layout.dart';

class YourTasksApp extends StatelessWidget {
  const YourTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return FluentApp(
      title: "YourTasks",
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
      home: appState.isLocked ? const LoginPage() : const MainLayout(),
    );
  }
}