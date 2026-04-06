import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MeetingDetailModal extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetailModal({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            children: [

              /// HEADER
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            meeting.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          /// FIXED DATE DISPLAY
                          Text(
                            DateFormat('dd MMM yyyy')
                                .format(meeting.date.toLocal()),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (meeting.projectName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meeting.projectName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              /// BODY
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// PARTICIPANTS
                      _SectionLabel(
                        icon: Icons.people_outline_rounded,
                        label: 'Participants',
                      ),

                      const SizedBox(height: 12),

                      if (meeting.participants.isEmpty)
                        Text(
                          'No participants added.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Column(
                          children: meeting.participants
                              .map((p) => _ParticipantRow(p: p))
                              .toList(),
                        ),

                      const SizedBox(height: 24),

                      /// DISCUSSION POINTS
                      _SectionLabel(
                        icon: Icons.forum_outlined,
                        label: 'Discussion Points',
                      ),

                      const SizedBox(height: 12),

                      if (meeting.discussionPoints.isEmpty)
                        Text(
                          'No discussion points.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Column(
                          children: meeting.discussionPoints
                              .map((dp) => _DiscussionCard(point: dp))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {

  final DiscussionPoint point;

  const _DiscussionCard({required this.point});

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            point.point,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          Text("Category : ${point.category}"),

          const SizedBox(height: 6),

          if (point.action.isNotEmpty)
            Text("Action : ${point.action}"),

          if (point.action.isNotEmpty)
            const SizedBox(height: 6),

          Text("Responsibility : ${point.responsibility}"),

          const SizedBox(height: 6),

          Text(
            point.targetDate != null
                ? DateFormat('dd MMM yyyy')
                    .format(point.targetDate!.toLocal())
                : "No date",
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {

  final IconData icon;
  final String label;

  const _SectionLabel({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Icon(icon, color: AppColors.primary),

        const SizedBox(width: 8),

        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ParticipantRow extends StatelessWidget {

  final Participant p;

  const _ParticipantRow({required this.p});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [

          CircleAvatar(
            child: Text(p.initials),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name),
              Text(p.email),
            ],
          ),
        ],
      ),
    );
  }
}