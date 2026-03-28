class Participant {
  final String id;
  final String name;
  final String email;

  const Participant({
    required this.id,
    required this.name,
    required this.email,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class DiscussionPoint {
  int srNo;
  String point;
  String category;
  String action;
  DateTime? targetDate;
  String responsibility;

  DiscussionPoint({
    required this.srNo,
    this.point = '',
    this.category = 'Quality',
    this.action = '',
    this.targetDate,
    this.responsibility = '',
  });

  static const List<String> categories = [
    'Quality',
    'Cost',
    'Delivery',
    'Development',
    'Engineering',
    'Others',
  ];
}

class Meeting {
  final String id;
  final String title;
  final DateTime date;
  final String projectName;
  final String description;
  final List<Participant> participants;
  final List<DiscussionPoint> discussionPoints;

  const Meeting({
    required this.id,
    required this.title,
    required this.date,
    this.projectName = '',
    this.description = '',
    this.participants = const [],
    this.discussionPoints = const [],
  });
}

class Task {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String assignedTo;
  final String relatedMeeting;
  final DateTime? dueDate;
  final DateTime? reminderDate;
  bool isCompleted;


  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.tags = const [],
    this.assignedTo = '',
    this.relatedMeeting = '',
    this.dueDate,
    this.isCompleted = false,
    this.reminderDate,
  });

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}

// ---------------------------------------------------------------------------
// Sample / seed data
// ---------------------------------------------------------------------------
class SampleData {
  SampleData._();

  static final List<Participant> participants = [
    const Participant(
      id: 'p1',
      name: 'Vivek Bhise',
      email: 'vivek.bhise@pccoepune.org',
    ),
    const Participant(
      id: 'p2',
      name: 'Arpit Gupta',
      email: 'arpit.gupta@pccoepune.org',
    ),
    const Participant(
      id: 'p3',
      name: 'Priyanka Gupta',
      email: 'priyanka.gupta@pccoepune.org',
    ),
    const Participant(
      id: 'p4',
      name: 'Rahul Sharma',
      email: 'rahul.sharma@pccoepune.org',
    ),
  ];

  static List<Meeting> get meetings => [
    Meeting(
      id: 'm1',
      title: 'Sprint Planning Q1',
      date: DateTime(2026, 3, 10),
      projectName: 'Smart MoM',
      description: 'Quarterly sprint planning and backlog grooming session.',
      participants: [participants[0], participants[1]],
      discussionPoints: [
        DiscussionPoint(
          srNo: 1,
          point: 'UI polish for dark theme',
          category: 'Quality',
          action: 'Refine color palette and contrast ratios',
          responsibility: 'Vivek Bhise',
          targetDate: DateTime(2026, 3, 15),
        ),
        DiscussionPoint(
          srNo: 2,
          point: 'Optimize database queries',
          category: 'Development',
          action: 'Profile slow queries and add indexes',
          responsibility: 'Arpit Gupta',
          targetDate: DateTime(2026, 3, 18),
        ),
      ],
    ),
    Meeting(
      id: 'm2',
      title: 'Design Review Session',
      date: DateTime(2026, 2, 25),
      projectName: 'Mobile App',
      description: 'UI/UX review for the new mobile application.',
      participants: [participants[0], participants[2], participants[3]],
      discussionPoints: [
        DiscussionPoint(
          srNo: 1,
          point: 'Navigation flow improvement',
          category: 'Quality',
          action: 'Redesign bottom navigation',
          responsibility: 'Priyanka Gupta',
          targetDate: DateTime(2026, 2, 28),
        ),
      ],
    ),
    Meeting(
      id: 'm3',
      title: 'Budget Review February',
      date: DateTime(2026, 2, 15),
      projectName: 'Finance',
      description: 'Monthly budget review and cost analysis.',
      participants: [participants[1], participants[3]],
      discussionPoints: [],
    ),
  ];

  static List<Task> get tasks => [
    Task(
      id: 't1',
      title: 'Refine color palette',
      description: 'Update dark theme colors for better contrast',
      tags: const ['UI', 'Design'],
      assignedTo: 'Vivek Bhise',
      relatedMeeting: 'Sprint Planning Q1',
      dueDate: DateTime(2026, 3, 15),
    ),
    Task(
      id: 't2',
      title: 'Optimize database queries',
      description: 'Profile and fix slow queries with indexes',
      tags: const ['Backend', 'Performance'],
      assignedTo: 'Arpit Gupta',
      relatedMeeting: 'Sprint Planning Q1',
      dueDate: DateTime(2026, 3, 18),
    ),
    Task(
      id: 't3',
      title: 'Redesign navigation flow',
      description: 'Create new bottom navigation wireframes',
      tags: const ['UX', 'Design'],
      assignedTo: 'Priyanka Gupta',
      relatedMeeting: 'Design Review Session',
      dueDate: DateTime(2026, 2, 28),
      isCompleted: true,
    ),
    Task(
      id: 't4',
      title: 'Write API documentation',
      description: 'Document all REST endpoints with examples',
      tags: const ['Docs'],
      assignedTo: 'Rahul Sharma',
      relatedMeeting: 'Sprint Planning Q1',
      dueDate: DateTime(2026, 3, 5),
    ),
    Task(
      id: 't5',
      title: 'Set up CI/CD pipeline',
      description: 'Configure GitHub Actions for auto-deploy',
      tags: const ['DevOps'],
      assignedTo: 'Arpit Gupta',
      relatedMeeting: 'Budget Review February',
      dueDate: DateTime(2026, 3, 20),
      isCompleted: true,
    ),
  ];
}
