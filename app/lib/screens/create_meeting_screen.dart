// lib/screens/create_meeting_screen.dart

import 'package:flutter/material.dart';
import '../services/meeting_service.dart';
import '../services/user_service.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {

  final _titleCtrl  = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();      // ← new search controller

  DateTime? meetingDate;

  // All users loaded for task assignment dropdown
  List<dynamic> users = [];

  // Selected participant IDs
  List<String> selectedParticipantIds = [];

  // Selected participant objects (for display + task dropdown)
  List<dynamic> selectedParticipants = [];

  // Search results
  List<dynamic> searchResults = [];
  bool searching = false;
  bool showResults = false;

  List<Map<String, dynamic>> tasks = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _clientCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search users ────────────────────────────────────────────────────────────
  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() { searchResults = []; showResults = false; });
      return;
    }

    setState(() => searching = true);

    final results = await UserService.searchUsers(query);

    setState(() {
      searchResults = results;
      searching     = false;
      showResults   = true;
    });
  }

  // ── Add participant from search result ──────────────────────────────────────
  void _addParticipant(dynamic user) {
    final id = user["_id"];
    if (selectedParticipantIds.contains(id)) return;

    setState(() {
      selectedParticipantIds.add(id);
      selectedParticipants.add(user);
      searchResults = [];
      showResults   = false;
    });

    _searchCtrl.clear();
  }

  // ── Remove participant ──────────────────────────────────────────────────────
  void _removeParticipant(String id) {
    setState(() {
      selectedParticipantIds.remove(id);
      selectedParticipants.removeWhere((u) => u["_id"] == id);
      // Also clear task assignment if this user was assigned
      for (var task in tasks) {
        if (task["assignedTo"] == id) task["assignedTo"] = "";
      }
    });
  }

  // ── Pick meeting date ───────────────────────────────────────────────────────
  Future<void> pickMeetingDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) setState(() => meetingDate = picked);
  }

  // ── Pick task deadline ──────────────────────────────────────────────────────
  Future<void> pickDeadline(int index) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => tasks[index]["deadline"] = picked.toIso8601String());
    }
  }

  // ── Add task ────────────────────────────────────────────────────────────────
  void addTask() {
    setState(() {
      tasks.add({
        "title":      "",
        "action":     "",
        "category":   "Quality",
        "assignedTo": "",
        "deadline":   null
      });
    });
  }

  // ── Create meeting ──────────────────────────────────────────────────────────
  Future<void> createMeeting() async {
    if (_titleCtrl.text.isEmpty || meetingDate == null) return;

    setState(() => loading = true);

    final data = {
      "title":        _titleCtrl.text,
      "client":       _clientCtrl.text,
      "date":         meetingDate!.toIso8601String(),
      "participants": selectedParticipantIds,
      "tasks":        tasks
    };

    final res = await MeetingService.createMeeting(data);

    setState(() => loading = false);

    if (!mounted) return;

    if (res["message"] == "Meeting created") {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Error creating meeting")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: AppBar(title: const Text("Create Meeting")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            // ── Meeting Details ─────────────────────────────────────────────
            const Text("Meeting Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Meeting Title"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _clientCtrl,
              decoration: const InputDecoration(labelText: "Client / Project"),
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: pickMeetingDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Meeting Date"),
                child: Text(
                  meetingDate == null
                      ? "Select Date"
                      : "${meetingDate!.day}/${meetingDate!.month}/${meetingDate!.year}",
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Participants ────────────────────────────────────────────────
            const Text("Participants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            // Search box
            TextField(
              controller: _searchCtrl,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                labelText: "Search by name or email",
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                searchResults = [];
                                showResults   = false;
                              });
                            },
                          )
                        : null,
              ),
            ),

            // Search results dropdown
            if (showResults)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text("No verified users found",
                          style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (_, i) {
                          final user = searchResults[i];
                          final alreadyAdded = selectedParticipantIds
                              .contains(user["_id"]);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.purple.withOpacity(0.2),
                              child: Text(
                                (user["username"] as String)
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(user["username"]),
                            subtitle: Text(user["email"],
                              style: const TextStyle(fontSize: 12)),
                            trailing: alreadyAdded
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text("Added",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_rounded,
                                      color: Colors.purple,
                                    ),
                                    onPressed: () => _addParticipant(user),
                                  ),
                          );
                        },
                      ),
              ),

            const SizedBox(height: 12),

            // Selected participants chips
            if (selectedParticipants.isNotEmpty) ...[
              const Text("Added Participants",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedParticipants.map((u) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.purple.withOpacity(0.2),
                      child: Text(
                        (u["username"] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12, color: Colors.purple),
                      ),
                    ),
                    label: Text(u["username"]),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeParticipant(u["_id"]),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // ── Tasks ───────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tasks",
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addTask,
                ),
              ],
            ),

            ...tasks.asMap().entries.map((entry) {
              int index = entry.key;
              var task  = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [

                      // Delete task button
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                          onPressed: () =>
                              setState(() => tasks.removeAt(index)),
                        ),
                      ),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Task Title"),
                        onChanged: (v) => task["title"] = v,
                      ),

                      DropdownButtonFormField<String>(
                        value: task["category"],
                        items: const [
                          DropdownMenuItem(
                            value: "Quality",
                            child: Text("Quality")),
                          DropdownMenuItem(
                            value: "Cost",
                            child: Text("Cost")),
                          DropdownMenuItem(
                            value: "Delivery",
                            child: Text("Delivery")),
                          DropdownMenuItem(
                            value: "Development",
                            child: Text("Development")),
                          DropdownMenuItem(
                            value: "Engineering",
                            child: Text("Engineering")),
                          DropdownMenuItem(
                            value: "Others",
                            child: Text("Others")),
                        ],
                        onChanged: (v) =>
                            setState(() => task["category"] = v),
                        decoration: const InputDecoration(
                          labelText: "Category"),
                      ),

                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Action"),
                        onChanged: (v) => task["action"] = v,
                      ),

                      // Assign to — only from selected participants
                      selectedParticipants.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                "Add participants first to assign tasks",
                                style: TextStyle(
                                  color: Colors.grey, fontSize: 12),
                              ),
                            )
                          : DropdownButtonFormField(
                              value: task["assignedTo"] == ""
                                  ? null
                                  : task["assignedTo"],
                              items: selectedParticipants.map((u) {
                                return DropdownMenuItem(
                                  value: u["_id"],
                                  child: Text(u["username"]),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => task["assignedTo"] = v),
                              decoration: const InputDecoration(
                                labelText: "Assign To"),
                            ),

                      const SizedBox(height: 10),

                      InkWell(
                        onTap: () => pickDeadline(index),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Deadline"),
                          child: Text(
                            task["deadline"] == null
                                ? "Select Deadline"
                                : task["deadline"]
                                    .toString()
                                    .split("T")[0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: createMeeting,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Create Meeting",
                      style: TextStyle(fontSize: 16)),
                  ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}