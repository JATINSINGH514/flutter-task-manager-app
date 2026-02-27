import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  ConsumerState<AddEditTaskScreen> createState() =>
      _AddEditTaskScreenState();
}

class _AddEditTaskScreenState
    extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String status = "pending";
  DateTime? dueDate;

  /// 🔹 store id separately (IMPORTANT FIX)
  String taskId = "";

  @override
  void initState() {
    super.initState();

    if (widget.task != null) {
      taskId = widget.task!.id; // 🔥 save id here

      titleController.text = widget.task!.title;
      descriptionController.text = widget.task!.description;
      status = widget.task!.status;
      dueDate = widget.task!.dueDate;
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => dueDate = picked);
    }
  }

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate() || dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final task = TaskModel(
      id: taskId, // 🔥 ALWAYS use stored id
      title: titleController.text,
      description: descriptionController.text,
      status: status,
      dueDate: dueDate!,
    );

    if (widget.task == null) {
      // ADD
      await ref.read(taskProvider.notifier).addTask(task);
    } else {
      // UPDATE
      await ref.read(taskProvider.notifier).updateTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? "Add Task" : "Edit Task"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter title" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Enter description" : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: status,
                items: const [
                  DropdownMenuItem(
                    value: "pending",
                    child: Text("Pending"),
                  ),
                  DropdownMenuItem(
                    value: "completed",
                    child: Text("Completed"),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => status = value!),
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      dueDate == null
                          ? "Select Due Date"
                          : dueDate.toString().split(" ")[0],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: pickDate,
                    child: const Text("Pick Date"),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: taskState.isLoading ? null : saveTask,
                  child: taskState.isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.task == null
                          ? "Save Task"
                          : "Update Task"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}