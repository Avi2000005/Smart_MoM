import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';

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
          onLogout: () => setState(() => _loggedIn = false),
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

  void _openNotifications() {
    showDialog(
      context: context,
      builder: (_) => const _NotificationPanel(),
    );
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

                /// NOTIFICATIONS
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: AppColors.textSecondary,
                  onPressed: _openNotifications,
                ),

                /// THEME
                IconButton(
                  tooltip: widget.darkMode ? 'Light Mode' : 'Dark Mode',
                  icon: Icon(
                    widget.darkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
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

          /// NAVBAR (IMPROVED STYLE)
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
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// NOTIFICATION PANEL
class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {

    return Dialog(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [

            Text(
              "Notifications",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            SizedBox(height: 16),

            ListTile(
              leading: Icon(Icons.schedule),
              title: Text("Task deadline tomorrow"),
              subtitle: Text("Submit project report"),
            ),

            ListTile(
              leading: Icon(Icons.warning),
              title: Text("Overdue task"),
              subtitle: Text("Prepare client presentation"),
            ),

            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text("Meeting reminder"),
              subtitle: Text("Team sprint planning"),
            ),
          ],
        ),
      ),
    );
  }
}