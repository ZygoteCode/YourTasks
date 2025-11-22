import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:yourtasks/ui/app_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _revealPassword = false;

  void _attemptUnlock() async {
    if (_passwordController.text.isEmpty) return;
    await context.read<AppState>().unlockApp(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return ScaffoldPage(
      content: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Icon(FluentIcons.lock, size: 64)),
              const SizedBox(height: 24),
              Text(
                "YourTasks",
                style: FluentTheme.of(context).typography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Insert the password to decrypt or create new one.",
                textAlign: TextAlign.center,
                style: FluentTheme.of(context).typography.body,
              ),
              const SizedBox(height: 32),
              TextBox(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: !_revealPassword,
                maxLines: 1,
                suffix: IconButton(
                  icon: Icon(
                    _revealPassword ? FluentIcons.view : FluentIcons.password_field,
                  ),
                  onPressed: () =>
                      setState(() => _revealPassword = !_revealPassword),
                ),
                onSubmitted: (_) => _attemptUnlock(),
              ),
              if (appState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: InfoBar(
                    title: const Text('Error'),
                    content: Text(appState.errorMessage!),
                    severity: InfoBarSeverity.error,
                  ),
                ),
              const SizedBox(height: 24),
              if (appState.isLoading)
                const ProgressBar()
              else
                FilledButton(
                  onPressed: _attemptUnlock,
                  child: const Text("Unlock"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}