import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/task_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {

  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {

    try {

      final data = await TaskService.getTasks();

      setState(() {

        _tasks = data.map<Task>((t) {

          return Task(
            id: t["_id"],
            title: t["title"],
            description: t["action"] ?? "",
            assignedTo: "",
            relatedMeeting: t["meetingId"],
            dueDate: t["deadline"] != null
                ? DateTime.parse(t["deadline"])
                : null,
            isCompleted: t["completed"] ?? false,
          );

        }).toList();

        _loading = false;

      });

    } catch (e) {

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load tasks")),
      );

    }

  }

  Future<void> _toggleTask(Task task) async {

    await TaskService.toggleTask(task.id, task.relatedMeeting);

    _loadTasks();

  }

  Future<void> _deleteTask(Task task) async {

    await TaskService.deleteTask(task.id, task.relatedMeeting);

    _loadTasks();

  }

  /// VIEW TASK DETAILS
  void _viewTask(Task task) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(

        title: Text(task.title),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Description: ${task.description}"),

            const SizedBox(height: 10),

            Text("Meeting ID: ${task.relatedMeeting}"),

            const SizedBox(height: 10),

            Text(
              "Deadline: ${task.dueDate != null ? DateFormat('dd MMM yyyy').format(task.dueDate!) : "No deadline"}",
            ),

            const SizedBox(height: 10),

            Text(
              "Status: ${task.isCompleted ? "Completed" : "Pending"}",
            ),

          ],
        ),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )

        ],

      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return const Center(child: Text("No tasks assigned"));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView.builder(

        itemCount: _tasks.length,

        itemBuilder: (context, index) {

          final task = _tasks[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),

            child: ListTile(

              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTask(task),
              ),

              title: Text(task.title),

              subtitle: task.dueDate != null
                  ? Text(
                      DateFormat('dd MMM yyyy')
                          .format(task.dueDate!.toLocal()),
                    )
                  : null,

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// VIEW TASK
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _viewTask(task),
                  ),

                  /// DELETE TASK
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task),
                  ),

                ],
              ),

            ),

          );

        },

      ),
    );
  }
}