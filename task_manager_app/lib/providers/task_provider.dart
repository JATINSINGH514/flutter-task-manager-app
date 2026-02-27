import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import 'package:hive/hive.dart';

/// 🔹 Task State
class TaskState {
  final bool isLoading;
  final List<TaskModel> tasks;
  final String? error;

  const TaskState({
    this.isLoading = false,
    this.tasks = const [],
    this.error,
  });

  TaskState copyWith({
    bool? isLoading,
    List<TaskModel>? tasks,
    String? error,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      error: error,
    );
  }
}

/// 🔹 Task Notifier
class TaskNotifier extends StateNotifier<TaskState> {
  final ApiService _apiService;

  TaskNotifier(this._apiService) : super(const TaskState());

  int currentPage = 1;
  bool hasMore = true;

  /// 🔹 Fetch first page
Future<void> getTasks() async {
  try {
    state = state.copyWith(isLoading: true, error: null);

    final tasks = await _apiService.fetchTasks();

    state = state.copyWith(
      isLoading: false,
      tasks: tasks,
    );
  } catch (e) {

    /// LOAD FROM CACHE
    final box = await Hive.openBox('taskBox');
    final cached = box.get('tasks');

    if (cached != null) {
      final cachedTasks = (cached as List)
          .map((task) => TaskModel.fromJson(task))
          .toList();

      state = state.copyWith(
        isLoading: false,
        tasks: cachedTasks,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: "No internet & no cached data",
      );
    }
  }
}

  /// 🔹 Load more tasks (pagination)
  Future<void> loadMoreTasks() async {
    if (!hasMore) return;

    try {
      currentPage++;

      final newTasks =
          await _apiService.fetchTasks(page: currentPage);

      if (newTasks.isEmpty) {
        hasMore = false;
      } else {
        state = state.copyWith(
          tasks: [...state.tasks, ...newTasks],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 🔹 Add task
  Future<void> addTask(TaskModel task) async {
    try {
      state = state.copyWith(isLoading: true);

      await _apiService.createTask(task);
      await getTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 🔹 Update task
  Future<void> updateTask(TaskModel task) async {
    try {
      state = state.copyWith(isLoading: true);

      await _apiService.updateTask(task);
      await getTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// 🔹 Delete task
  Future<void> deleteTask(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      await _apiService.deleteTask(id);
      await getTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// 🔹 Provider
final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  return TaskNotifier(ApiService());
});