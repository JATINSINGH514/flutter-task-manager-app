import 'package:dio/dio.dart';
import '../models/task_model.dart';
import 'package:hive/hive.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://69a0b1893188b0b1d5395964.mockapi.io/api/v1",
      headers: {
        "Content-Type": "application/json",
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // 🔹 Fetch all tasks
 // 🔹 Fetch tasks with pagination
Future<List<TaskModel>> fetchTasks({int page = 1}) async {
  try {
    final response =
        await _dio.get('/tasks?page=$page&limit=10');

    if (response.statusCode == 200) {

      /// SAVE TO CACHE
      final box = await Hive.openBox('taskBox');
      box.put('tasks', response.data);

      return (response.data as List)
          .map((task) => TaskModel.fromJson(task))
          .toList();
    } else {
      throw Exception("Failed to load tasks");
    }
  } catch (e) {
    throw Exception("Network error");
  }
}

  // 🔹 Create new task
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _dio.post(
        '/tasks',
        data: task.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TaskModel.fromJson(response.data);
      } else {
        throw Exception("Failed to create task");
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception("Unexpected error occurred");
    }
  }

  // 🔹 Update task
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await _dio.put(
        '/tasks/${task.id}',
        data: task.toJson(),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(response.data);
      } else {
        throw Exception("Failed to update task");
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception("Unexpected error occurred");
    }
  }

  // 🔹 Delete task
  Future<void> deleteTask(String id) async {
    try {
      final response = await _dio.delete('/tasks/$id');

      if (response.statusCode != 200) {
        throw Exception("Failed to delete task");
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception("Unexpected error occurred");
    }
  }

  // 🔹 Centralized Dio Error Handler
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return "Connection timeout. Please try again.";
      case DioExceptionType.receiveTimeout:
        return "Server took too long to respond.";
      case DioExceptionType.badResponse:
        return "Server error: ${e.response?.statusCode}";
      case DioExceptionType.cancel:
        return "Request cancelled.";
      case DioExceptionType.connectionError:
        return "No internet connection.";
      default:
        return "Network error occurred.";
    }
  }
}