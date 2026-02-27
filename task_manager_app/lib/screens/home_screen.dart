import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    /// Load first page
    Future.microtask(() =>
        ref.read(taskProvider.notifier).getTasks());

    /// Pagination scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(taskProvider.notifier).loadMoreTasks();
      }
    });
  }

  Future<void> refreshTasks() async {
    await ref.read(taskProvider.notifier).getTasks();
  }

  /// DELETE CONFIRMATION
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(id);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
      ),

      /// ➕ ADD TASK
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditTaskScreen(),
            ),
          );

          refreshTasks();
        },
        child: const Icon(Icons.add),
      ),

      /// 🔄 PULL TO REFRESH
      body: RefreshIndicator(
        onRefresh: refreshTasks,
        child: _buildBody(taskState),
      ),
    );
  }

  Widget _buildBody(TaskState taskState) {
    if (taskState.isLoading && taskState.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskState.error != null && taskState.tasks.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              taskState.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    }

    if (taskState.tasks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text("No tasks found")),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: taskState.tasks.length + 1,
      itemBuilder: (context, index) {

        /// Show loader at bottom
        if (index == taskState.tasks.length) {
          return taskState.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox();
        }

        final task = taskState.tasks[index];

        return TaskCard(
          task: task,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTaskScreen(task: task),
              ),
            );
            refreshTasks();
          },
          onDelete: () => confirmDelete(task.id),
        );
      },
    );
  }
}