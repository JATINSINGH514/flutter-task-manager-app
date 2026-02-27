class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime dueDate;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
  });

  // Convert JSON → Dart object
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'].toString(),
      title: json['title'],
      description: json['description'],
      status: json['status'],
      dueDate: DateTime.parse(json['dueDate']),
    );
  }

  // Convert Dart object → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
    };
  }
}