import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cryptography/cryptography.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yourtasks/projects/project.dart';
import 'package:yourtasks/tasks/task_item.dart';
import 'package:yourtasks/tasks/task_priority.dart';

class AppState extends ChangeNotifier {
  List<TaskItem> _tasks = [];
  List<Project> _projects = [];
  ThemeMode _themeMode = ThemeMode.system;

  bool _isLocked = true;
  bool _isLoading = false;
  String? _errorMessage;

  SecretKey? _secretKey;
  List<int>? _fileSalt;
  final _algorithm = AesGcm.with256bits();

  List<TaskItem> get tasks => _tasks;
  List<Project> get projects => _projects;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isLocked => _isLocked;
  String? get errorMessage => _errorMessage;

  List<TaskItem> get inboxTasks =>
      _tasks.where((t) => !t.isCompleted && t.projectId == null).toList();
  List<TaskItem> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  AppState(); 

  Future<bool> unlockApp(String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final path = await _getFilePath();
      final File file = File(path);

      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();

        if (fileBytes.length < 28) {
          throw Exception("File danneggiato o troppo corto.");
        }

        final salt = fileBytes.sublist(0, 16);
        final encryptedContent = fileBytes.sublist(16);

        final key = await _deriveKey(password, salt);

        final secretBox = SecretBox.fromConcatenation(
          encryptedContent,
          nonceLength: 12,
          macLength: 16,
        );

        final clearTextBytes = await _algorithm.decrypt(
          secretBox,
          secretKey: key,
        );

        final jsonString = utf8.decode(clearTextBytes);
        final data = jsonDecode(jsonString);
        _loadJsonData(data);

        _secretKey = key;
        _fileSalt = salt;
      } else {
        _generateInitialData();
        final salt = _generateSecureRandomBytes(16);
        _secretKey = await _deriveKey(password, salt);
        _fileSalt = salt;
        await _saveData(); 
      }

      _isLocked = false;
      return true;
    } catch (_) {
      _errorMessage = "Wrong password or can't decrypt data.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );
    return await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
  }

  List<int> _generateSecureRandomBytes(int length) {
    final rng = math.Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }

  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/yourtasks_data.tasks';
  }

  Future<void> _saveData() async {
    if (_secretKey == null || _fileSalt == null) return;

    try {
      final path = await _getFilePath();
      final File file = File(path);

      final data = {
        'tasks': _tasks.map((e) => e.toJson()).toList(),
        'projects': _projects.map((e) => e.toJson()).toList(),
      };
      final jsonString = jsonEncode(data);
      final clearTextBytes = utf8.encode(jsonString);

      final nonce = _algorithm.newNonce(); 
      
      final secretBox = await _algorithm.encrypt(
        clearTextBytes,
        secretKey: _secretKey!,
        nonce: nonce,
      );

      final allBytes = [
        ..._fileSalt!,
        ...secretBox.concatenation(),
      ];

      await file.writeAsBytes(allBytes);
    } catch (_) {}
  }

  void _loadJsonData(Map<String, dynamic> data) {
    if (data['tasks'] != null) {
      _tasks = (data['tasks'] as List).map((e) => TaskItem.fromJson(e)).toList();
    }
    if (data['projects'] != null) {
      _projects = (data['projects'] as List).map((e) => Project.fromJson(e)).toList();
    }
  }

  void _generateInitialData() {
    _tasks = [
      TaskItem(
        id: const Uuid().v4(),
        title: 'Welcome to YourTasks!',
        description: 'All of your data is encrypted with **AES-256-GCM**.',
        priority: TaskPriority.p1,
      ),
    ];
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
      _projects[index] =
          Project(id: id, name: newName, colorValue: newColorValue);
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

  List<TaskItem> getProjectTasks(String projectId) {
    return _tasks
        .where((t) => !t.isCompleted && t.projectId == projectId)
        .toList();
  }
}