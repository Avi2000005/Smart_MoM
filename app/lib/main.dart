import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const SmartMoMApp());
}

class SmartMoMApp extends StatefulWidget {
  const SmartMoMApp({super.key});

  @override
  State<SmartMoMApp> createState() => _SmartMoMAppState();
}

class _SmartMoMAppState extends State<SmartMoMApp> {
  bool _darkMode = true;
  bool _loggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart MoM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: _loggedIn
          ? AppShell(
              darkMode: _darkMode,
              onToggleTheme: () => setState(() => _darkMode = !_darkMode),
              onLogout: () async {
                await AuthService.logout();
                setState(() => _loggedIn = false);
              },
            )
          : LoginScreen(
              onLogin: () => setState(() => _loggedIn = true),
            ),
    );
  }
}

enum _Tab { meetings, tasks, analytics, settings }

class AppShell extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Tab _tab = _Tab.meetings;
  int _unreadCount = 0; // ← ADD THIS

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount(); // ← ADD THIS
  }

  // ── Fetch unread badge count ──────────────────────────────────────────────
  Future<void> _fetchUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Widget get _body {
    switch (_tab) {
      case _Tab.meetings:
        return const MeetingsScreen();
      case _Tab.tasks:
        return const TasksScreen();
      case _Tab.analytics:
        return const AnalyticsScreen();
      case _Tab.settings:
        return SettingsScreen(onLogout: widget.onLogout);
    }
  }

  // ── Open notification panel & refresh badge after closing ─────────────────
  void _openNotifications() async {
    await showDialog(
      context: context,
      builder: (_) => const _NotificationPanel(),
    );
    _fetchUnreadCount(); // refresh badge when panel closes
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [

          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 64,
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Let's Meet",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),

                /// NOTIFICATION BELL WITH BADGE ──────────────────────────
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      color: AppColors.textSecondary,
                      onPressed: _openNotifications,
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadCount > 99 ? "99+" : "$_unreadCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),

                /// THEME
                IconButton(
                  key: const ValueKey('theme_button'),
                  tooltip: widget.darkMode ? 'Light Mode' : 'Dark Mode',
                  icon: Icon(
                    widget.darkMode ? Icons.light_mode : Icons.dark_mode,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: widget.onToggleTheme,
                ),

                /// SETTINGS
                IconButton(
                  tooltip: "Settings",
                  icon: const Icon(Icons.settings),
                  color: AppColors.textSecondary,
                  onPressed: () => setState(() => _tab = _Tab.settings),
                ),
              ],
            ),
          ),

          /// NAVBAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: "Meetings",
                    icon: Icons.calendar_month,
                    active: _tab == _Tab.meetings,
                    onTap: () => setState(() => _tab = _Tab.meetings),
                  ),
                  _TabButton(
                    label: "Tasks",
                    icon: Icons.task_alt,
                    active: _tab == _Tab.tasks,
                    onTap: () => setState(() => _tab = _Tab.tasks),
                  ),
                  _TabButton(
                    label: "Analytics",
                    icon: Icons.bar_chart,
                    active: _tab == _Tab.analytics,
                    onTap: () => setState(() => _tab = _Tab.analytics),
                  ),
                ],
              ),
            ),
          ),

          Expanded(child: _body),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── NOTIFICATION PANEL (Now fetches real data) ────────────────────────────────
class _NotificationPanel extends StatefulWidget {
  const _NotificationPanel();

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await NotificationService.getNotifications();
      if (mounted) setState(() { _notifications = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    setState(() {
      for (var n in _notifications) n["read"] = true;
    });
  }

  Future<void> _deleteOne(String id, int index) async {
    await NotificationService.deleteNotification(id);
    setState(() => _notifications.removeAt(index));
  }

  IconData _iconForType(String? type) {
  switch (type) {
    case "task_assigned":    return Icons.assignment_ind;
    case "task_deadline":    return Icons.access_time;
    case "task_overdue":     return Icons.warning_amber_rounded;
    case "task_completed":   return Icons.check_circle_outline;
    case "meeting_created":  return Icons.video_call;
    case "meeting_reminder": return Icons.calendar_today;
    case "participant_added":return Icons.group_add;
    default:                 return Icons.notifications;
  }
}

Color _colorForType(String? type) {
  switch (type) {
    case "task_assigned":    return Colors.purple;
    case "task_deadline":    return Colors.orange;
    case "task_overdue":     return Colors.red;
    case "task_completed":   return Colors.green;
    case "meeting_created":  return Colors.blue;
    case "meeting_reminder": return Colors.blue;
    case "participant_added":return Colors.teal;
    default:                 return Colors.grey;
  }
}

  String _timeAgo(String? iso) {
    if (iso == null) return "";
    final dt = DateTime.tryParse(iso);
    if (dt == null) return "";
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24)   return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = _notifications.where((n) => n["read"] == false).length;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        height: 480,
        child: Column(
          children: [

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text(
                    "Notifications",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$unread",
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (unread > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(
                        "Mark all read",
                        style: TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.purple),
                    )
                  : _notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("No notifications",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (ctx, i) {
                            final n = _notifications[i];
                            final isUnread = n["read"] == false;
                            final type = n["type"] as String?;

                            return Dismissible(
                              key: Key(n["_id"]),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red.withOpacity(0.2),
                                child: const Icon(Icons.delete, color: Colors.red),
                              ),
                              onDismissed: (_) => _deleteOne(n["_id"], i),
                              child: ListTile(
                                onTap: () async {
                                  if (isUnread) {
                                    await NotificationService.markOneRead(n["_id"]);
                                    setState(() => n["read"] = true);
                                  }
                                },
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _colorForType(type).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _iconForType(type),
                                    color: _colorForType(type),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  n["message"] ?? "",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isUnread
                                        ? null
                                        : Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _timeAgo(n["createdAt"]),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                                trailing: isUnread
                                    ? const CircleAvatar(
                                        radius: 4,
                                        backgroundColor: Colors.purple,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}