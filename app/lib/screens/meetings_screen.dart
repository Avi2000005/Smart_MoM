import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/meeting_service.dart';

import 'create_meeting_screen.dart';
import 'meeting_detail_modal.dart';

import '../services/api_service.dart';
import '../services/download_service.dart';


class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {

  List<Meeting> _meetings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  /// LOAD MEETINGS
  Future<void> _loadMeetings() async {

    try {

      final data = await MeetingService.getMeetings();

      setState(() {

        _meetings = data.map<Meeting>((m){

          final participants = (m["participants"] ?? [])
              .map<Participant>((p) => Participant(
                    id: p["_id"] ?? "",
                    name: p["username"] ?? "Unknown",
                    email: p["email"] ?? "",
                  ))
              .toList();

          final discussionPoints =
              (m["tasks"] ?? []).map<DiscussionPoint>((t) {

            String responsible = "";

            if (t["assignedTo"] is Map) {
              responsible = t["assignedTo"]["username"] ?? "";
            }

            return DiscussionPoint(
              srNo: 1,
              point: t["title"] ?? "",
              category: t["category"] ?? "Others",
              action: t["action"] ?? "",
              responsibility: responsible,
              targetDate: t["deadline"] != null
                  ? DateTime.parse(t["deadline"])
                  : null,
            );

          }).toList();

          return Meeting(
            id: m["_id"],
            title: m["title"] ?? "",
            projectName: m["client"] ?? "",
            date: DateTime.parse(m["date"]),
            participants: participants,
            discussionPoints: discussionPoints,
          );

        }).toList();

        _loading = false;

      });

    } catch (e) {

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load meetings")),
      );

    }

  }

  /// CREATE MEETING
  Future<void> _openCreate() async {

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateMeetingScreen(),
      ),
    );

    _loadMeetings();

  }

  /// DELETE MEETING
  void _confirmDelete(Meeting m) {

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Meeting"),
        content: Text('Delete "${m.title}"?'),
        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {

              await MeetingService.deleteMeeting(m.id);

              Navigator.pop(context);

              _loadMeetings();

            },
            child: const Text("Delete"),
          )

        ],
      ),
    );

  }

  /// EXPORT PDF
 Future<void> _exportMeeting(Meeting meeting) async {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Downloading PDF...")),
  );

  final token = await ApiService.getToken();

  final url =
      "https://smart-mom.onrender.com/api/meetings/export/${meeting.id}?token=$token";

  // Replaced url_launcher browser redirect with native background downloading
  final savedPath = await DownloadService.downloadPDF(
    url: url,
    fileName: meeting.title.replaceAll(" ", "_"), // Safe filename
  );

  if (savedPath != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF Saved to: $savedPath")),
    );
  }

}

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(28),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Text(
                "Meetings",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const Spacer(),

              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Meeting"),
                onPressed: _openCreate,
              )

            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _meetings.isEmpty
                    ? const Center(
                        child: Text("No meetings yet"),
                      )
                    : ListView.builder(
                        itemCount: _meetings.length,
                        itemBuilder: (_, i) {

                          final meeting = _meetings[i];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),

                            child: ListTile(

                              title: Text(meeting.title),

                              subtitle: Text(
                                DateFormat('dd MMM yyyy')
                                    .format(meeting.date.toLocal()),
                              ),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  /// VIEW
                                  IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () {

                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            MeetingDetailModal(
                                                meeting: meeting),
                                      );

                                    },
                                  ),

                                  /// EXPORT PDF
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf),
                                    onPressed: () =>
                                        _exportMeeting(meeting),
                                  ),

                                  /// DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () =>
                                        _confirmDelete(meeting),
                                  ),

                                ],
                              ),

                            ),
                          );

                        },
                      ),
          )

        ],
      ),
    );
  }
}