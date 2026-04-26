// lib/screens/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/schedule.dart';
import '../models/room.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import 'schedule_screen.dart';
import 'chatbot_splash_screen.dart';
import 'room_availability_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell with bottom nav (mobile)
// ─────────────────────────────────────────────────────────────────────────────
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboardScreen> {
  int _idx = 0;

  static const List<_NavDef> _tabs = [
    _NavDef(Icons.dashboard_outlined,     Icons.dashboard,      'Dashboard'),
    _NavDef(Icons.meeting_room_outlined,  Icons.meeting_room,   'Rooms'),
    _NavDef(Icons.book_outlined,          Icons.book,           'Subjects'),
    _NavDef(Icons.calendar_month_outlined,Icons.calendar_month, 'Schedule'),
    _NavDef(Icons.person_outline,         Icons.person,         'Profile'),
  ];

  List<Widget> _bodies(AppState state) => [
    _TeacherHome(
      schedule: state.getTeacherSchedule(state.currentTeacher?.id ?? ''),
      onSchedule: () => setState(() => _idx = 3),
    ),
    const RoomAvailabilityScreen(),
    _TeacherSubjectsScreen(),
    TeacherScheduleViewScreen(teacher: state.currentTeacher!),
    _TeacherProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      if (state.currentTeacher == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        body: IndexedStack(index: _idx, children: _bodies(state)),
        floatingActionButton: _idx == 0
            ? FloatingActionButton(
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const ChatbotSplashScreen()),
          ),
          backgroundColor: AppColors.red,
          tooltip: 'AI Assistant',
          child: ClipOval(
            child: Image.asset('assets/images/css_logo.png', width: 40, height: 40, fit: BoxFit.cover),
          ),
        )
            : null,
        bottomNavigationBar: _BottomNav(
          tabs: _tabs,
          selectedIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
        ),
      );
    });
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavDef> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.tabs, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(active ? tabs[i].activeIcon : tabs[i].icon, size: 20,
                          color: active ? AppColors.red : Colors.white38),
                      const SizedBox(height: 3),
                      Text(tabs[i].label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? AppColors.red : Colors.white38,
                          )),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2, width: active ? 18 : 0,
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(1)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  final IconData icon, activeIcon;
  final String label;
  const _NavDef(this.icon, this.activeIcon, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Home Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherHome extends StatefulWidget {
  final List<ScheduleEntry> schedule;
  final VoidCallback onSchedule;
  const _TeacherHome({required this.schedule, required this.onSchedule});

  @override
  State<_TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<_TeacherHome> {
  // Track which notification IDs the teacher has already viewed.
  // Badge disappears once seen; reappears only when new ones arrive.
  final Set<String> _seenConflictIds   = {};
  final Set<String> _seenResponseIds   = {};

  List<ScheduleEntry> get _schedule => widget.schedule;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final teacher = state.currentTeacher!;
      final rooms = state.rooms;
      final availableRooms = rooms.where((r) => r.status == RoomStatus.available).length;
      final occupiedRooms  = rooms.where((r) => r.status == RoomStatus.occupied).length;

      final myConflicts = state.conflicts
          .where((c) =>
      !c.isResolved &&
          (c.conflictingEntry1.teacher.id == teacher.id ||
              c.conflictingEntry2.teacher.id == teacher.id))
          .toList();

      // Admin responses (resolved chat messages for this teacher)
      final adminResponses = state.chatMessages
          .where((m) => m.senderId == teacher.id && m.isResolved)
          .toList();

      // Unseen = items not yet marked as viewed by the teacher
      final unseenConflicts  = myConflicts.where((c) => !_seenConflictIds.contains(c.id)).toList();
      final unseenResponses  = adminResponses.where((m) => !_seenResponseIds.contains(m.id)).toList();
      final totalUnseenCount = unseenConflicts.length + unseenResponses.length;

      final now = DateTime.now();
      final weekdays = const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
      final todayName = now.weekday <= 6 ? weekdays[now.weekday - 1] : null;
      final todayClasses = todayName != null
          ? (_schedule.where((e) => e.day == todayName).toList()
        ..sort((a, b) => a.timeStart.compareTo(b.timeStart)))
          : <ScheduleEntry>[];

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Column(
              children: [
                // ── Top header bar ──────────────────────────────────────────
                Container(
                  color: AppColors.darkGray,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(
                            '${teacher.firstName[0]}${teacher.lastName[0]}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, ${teacher.firstName}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text(teacher.department,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
                          ],
                        ),
                      ),
                      // ── Notification bell (conflicts + admin responses) ──
                      GestureDetector(
                        onTap: () {
                          // Mark all current notifications as seen
                          setState(() {
                            _seenConflictIds.addAll(myConflicts.map((c) => c.id));
                            _seenResponseIds.addAll(adminResponses.map((m) => m.id));
                          });
                          _showNotificationsPanel(ctx, state, teacher, myConflicts, adminResponses);
                        },
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                totalUnseenCount > 0
                                    ? Icons.notifications
                                    : Icons.notifications_outlined,
                                color: Colors.white70,
                                size: 26,
                              ),
                            ),
                            if (totalUnseenCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 18, height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppColors.conflict,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$totalUnseenCount',
                                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),

                            // ── 4-stat row ──────────────────────────────────
                            if (isWide)
                              Row(children: [
                                _StatCard(icon: Icons.meeting_room_outlined, iconColor: AppColors.available, value: '$availableRooms', label: 'Available Rooms'),
                                const SizedBox(width: 12),
                                _StatCard(icon: Icons.event_busy_outlined, iconColor: AppColors.conflict, value: '$occupiedRooms', label: 'Occupied Rooms'),
                                const SizedBox(width: 12),
                                _StatCard(icon: Icons.calendar_today_outlined, iconColor: AppColors.darkGray, value: '${_schedule.length}', label: 'My Classes'),
                                const SizedBox(width: 12),
                                _StatCard(
                                  icon: Icons.warning_amber_outlined,
                                  iconColor: myConflicts.isNotEmpty ? AppColors.conflict : AppColors.available,
                                  value: '${myConflicts.length}',
                                  label: 'Conflict Alerts',
                                ),
                              ])
                            else
                              Column(children: [
                                Row(children: [
                                  _StatCard(icon: Icons.meeting_room_outlined, iconColor: AppColors.available, value: '$availableRooms', label: 'Available Rooms'),
                                  const SizedBox(width: 12),
                                  _StatCard(icon: Icons.event_busy_outlined, iconColor: AppColors.conflict, value: '$occupiedRooms', label: 'Occupied Rooms'),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  _StatCard(icon: Icons.calendar_today_outlined, iconColor: AppColors.darkGray, value: '${_schedule.length}', label: 'My Classes'),
                                  const SizedBox(width: 12),
                                  _StatCard(
                                    icon: Icons.warning_amber_outlined,
                                    iconColor: myConflicts.isNotEmpty ? AppColors.conflict : AppColors.available,
                                    value: '${myConflicts.length}',
                                    label: 'Conflict Alerts',
                                  ),
                                ]),
                              ]),

                            // ── Notification hint banner (if conflicts exist) ─
                            if (unseenConflicts.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _seenConflictIds.addAll(myConflicts.map((c) => c.id));
                                    _seenResponseIds.addAll(adminResponses.map((m) => m.id));
                                  });
                                  _showNotificationsPanel(ctx, state, teacher, myConflicts, adminResponses);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.conflict.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.conflict.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.warning_amber_rounded, color: AppColors.conflict, size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${myConflicts.length} schedule conflict${unseenConflicts.length > 1 ? 's' : ''} detected — tap to view & notify admin',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.conflict),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.conflict, size: 16),
                                  ]),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ── Today's classes ─────────────────────────────
                            Row(children: [
                              Text("Today's Classes",
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                              if (todayName != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGray.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(todayName, style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 10),

                            if (todayClasses.isEmpty)
                              _EmptyState(icon: Icons.coffee_outlined, message: 'No classes today — enjoy your day!')
                            else
                              ...todayClasses.map((e) => _TodayCard(entry: e)),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  /// Opens the notification panel with conflicts + admin responses.
  void _showNotificationsPanel(
      BuildContext context,
      AppState state,
      Teacher teacher,
      List<ScheduleConflict> conflicts,
      List<ChatMessage> adminResponses,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsPanel(
        teacher: teacher,
        conflicts: conflicts,
        adminResponses: adminResponses,
        state: state,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Panel (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsPanel extends StatefulWidget {
  final Teacher teacher;
  final List<ScheduleConflict> conflicts;
  final List<ChatMessage> adminResponses;
  final AppState state;

  const _NotificationsPanel({
    required this.teacher,
    required this.conflicts,
    required this.adminResponses,
    required this.state,
  });

  @override
  State<_NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<_NotificationsPanel> {
  final Set<String> _notified = {};

  void _notifyAdmin(BuildContext context, ScheduleConflict c) {
    if (_notified.contains(c.id)) return;
    final entry = c.conflictingEntry1.teacher.id == widget.teacher.id
        ? c.conflictingEntry1
        : c.conflictingEntry2;
    final msg = ChatMessage(
      id: 'conflict_${c.id}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.teacher.id,
      senderName: widget.teacher.fullName,
      message:
      '⚠️ CONFLICT ALERT\n\n'
          '📚 Subject: ${entry.subject.code} – ${entry.subject.name}\n'
          '📅 Day: ${entry.day}  ⏰ ${entry.timeStart}–${entry.timeEnd}\n'
          '🚪 Room: ${entry.room.name}\n'
          '📋 Type: ${c.typeLabel}\n\n'
          '${c.description}\n\n'
          'Please help resolve this schedule conflict.',
      isFromTeacher: true,
      timestamp: DateTime.now(),
      isResolved: false,
    );
    widget.state.sendChatMessage(msg);
    setState(() => _notified.add(c.id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Admin notified about conflict.', style: GoogleFonts.inter()),
      backgroundColor: AppColors.available,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hasConflicts = widget.conflicts.isNotEmpty;
    final hasResponses = widget.adminResponses.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgGray,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                const Icon(Icons.notifications, color: AppColors.darkGray, size: 20),
                const SizedBox(width: 10),
                Text('Notifications',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: AppColors.lightGray),
                ),
              ]),
            ),
            const Divider(height: 1),

            Expanded(
              child: (!hasConflicts && !hasResponses)
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No notifications', style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightGray)),
                  ],
                ),
              )
                  : ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [

                  // ── Schedule Conflicts section ──────────────────────
                  if (hasConflicts) ...[
                    _sectionHeader('Schedule Conflicts', AppColors.conflict, Icons.warning_amber_outlined),
                    const SizedBox(height: 10),
                    ...widget.conflicts.map((c) {
                      final alreadyNotified = _notified.contains(c.id);
                      final entry = c.conflictingEntry1.teacher.id == widget.teacher.id
                          ? c.conflictingEntry1
                          : c.conflictingEntry2;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.conflict.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: AppColors.conflict.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          children: [
                            // Card header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.conflict.withValues(alpha: 0.07),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text('${entry.subject.code} · ${entry.subject.name}',
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.conflict.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(c.typeLabel,
                                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.conflict)),
                                ),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${entry.day}  ${entry.timeStart}–${entry.timeEnd}  ·  ${entry.room.name}',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                                  const SizedBox(height: 4),
                                  Text(c.description,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray)),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: alreadyNotified ? null : () => _notifyAdmin(context, c),
                                      icon: Icon(alreadyNotified ? Icons.check_circle_outline : Icons.send_outlined, size: 15),
                                      label: Text(
                                        alreadyNotified ? 'Admin Notified' : 'Notify Admin',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: alreadyNotified ? AppColors.available : AppColors.conflict,
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  // ── Admin Responses section ─────────────────────────
                  if (hasResponses) ...[
                    _sectionHeader('Admin Responses', AppColors.available, Icons.admin_panel_settings_outlined),
                    const SizedBox(height: 10),
                    ...widget.adminResponses.map((msg) {
                      final approved = msg.wasApproved == true;
                      final color = approved ? AppColors.available : AppColors.conflict;
                      final note = (msg.adminResponse ?? '').trim();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.25)),
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.07),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              ),
                              child: Row(children: [
                                Icon(approved ? Icons.check_circle_outline : Icons.cancel_outlined,
                                    color: color, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  approved ? 'Request Approved' : 'Request Rejected',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                                ),
                              ]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Original request preview
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgGray,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.borderGray),
                                    ),
                                    child: Text(
                                      msg.message.length > 120
                                          ? '${msg.message.substring(0, 120)}...'
                                          : msg.message,
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray),
                                    ),
                                  ),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Admin note: $note',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.red),
                                        ),
                                      ),
                                    ]),
                                  ],
                                  if (approved) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      const Icon(Icons.auto_stories_outlined, size: 13, color: AppColors.available),
                                      const SizedBox(width: 6),
                                      Text('Your schedule has been automatically adjusted.',
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.available)),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) => Row(children: [
    Icon(icon, color: color, size: 16),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
  ]);
}

// ── Stat card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
          ],
        ),
      ),
    );
  }
}

// ── Today class card ───────────────────────────────────────────────────────
class _TodayCard extends StatelessWidget {
  final ScheduleEntry entry;
  const _TodayCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) {
        final isCancelled = state.cancelledEntryIds.contains(entry.id);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: kCardDecoration(
            borderColor: isCancelled
                ? AppColors.conflict.withValues(alpha: 0.4)
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isCancelled ? AppColors.conflict : AppColors.red,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.subject.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCancelled ? AppColors.lightGray : AppColors.darkGray,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (isCancelled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.conflict.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.conflict.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.cancel_outlined,
                                        size: 10, color: AppColors.conflict),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Cancelled',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.conflict,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\${entry.subject.code} · \${entry.section}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isCancelled ? AppColors.lightGray : AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.access_time_outlined, size: 12, color: AppColors.lightGray),
                          const SizedBox(width: 4),
                          Text('\${entry.timeStart} – \${entry.timeEnd}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                          const SizedBox(width: 14),
                          Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.lightGray),
                          const SizedBox(width: 4),
                          Text(entry.room.name,
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Subjects Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherSubjectsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final teacher = state.currentTeacher!;
      final schedule = state.getTeacherSchedule(teacher.id);
      final Map<String, List<ScheduleEntry>> bySubject = {};
      for (final e in schedule) {
        bySubject.putIfAbsent(e.subject.id, () => []).add(e);
      }
      final scheduleSubjects = state.getTeacherSubjects(teacher.id);
      final assignedIds = scheduleSubjects.map((s) => s.id).toSet();
      final directSubjects = teacher.assignedSubjects.where((s) => !assignedIds.contains(s.id)).toList();
      final subjects = [...scheduleSubjects, ...directSubjects];

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('My Subjects',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${subjects.length} subjects',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.red)),
                ),
              ),
            ),
          ],
        ),
        body: subjects.isEmpty
            ? _EmptyState(icon: Icons.book_outlined, message: 'No subjects assigned yet.\nAsk your admin.')
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: subjects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final subj = subjects[i];
            final entries = bySubject[subj.id] ?? [];
            final isLab = subj.type == SubjectType.laboratory;
            final accentColor = isLab ? AppColors.moderate : AppColors.red;
            return Container(
              decoration: kCardDecoration(),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(isLab ? Icons.science_outlined : Icons.menu_book_outlined, color: accentColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subj.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          Text('${subj.code} · ${subj.department}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Chip(subj.typeLabel, color: accentColor),
                        const SizedBox(height: 4),
                        Text('${subj.units} units · ${subj.hours} hrs',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
                      ],
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _InfoChip(Icons.school_outlined, subj.yearLevel),
                        const SizedBox(width: 8),
                        _InfoChip(Icons.calendar_today_outlined, subj.semester),
                      ]),
                      const SizedBox(height: 10),
                      if (entries.isEmpty)
                        _InlineInfo('Not yet scheduled')
                      else
                        ...entries.map((e) => _ScheduleRow(entry: e)),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
      );
    });
  }
}

class _ScheduleRow extends StatelessWidget {
  final ScheduleEntry entry;
  const _ScheduleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(children: [
        Icon(Icons.calendar_month_outlined, size: 13, color: AppColors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text('${entry.day}  ${entry.timeStart}–${entry.timeEnd}',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        ),
        Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.lightGray),
        const SizedBox(width: 4),
        Text(entry.room.name, style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
        const SizedBox(width: 8),
        Icon(Icons.groups_outlined, size: 12, color: AppColors.lightGray),
        const SizedBox(width: 4),
        Text(entry.section, style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Schedule View Tab
// ─────────────────────────────────────────────────────────────────────────────
class TeacherScheduleViewScreen extends StatefulWidget {
  final dynamic teacher;
  const TeacherScheduleViewScreen({super.key, required this.teacher});
  @override
  State<TeacherScheduleViewScreen> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleViewScreen> {
  static const _days = ['Monday','Tuesday','Wednesday','Thursday','Friday'];
  String _selectedDay = 'ALL';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final all = state.getTeacherSchedule(widget.teacher.id);
      final filtered = _selectedDay == 'ALL'
          ? all
          : (all.where((e) => e.day == _selectedDay).toList()
        ..sort((a, b) => a.timeStart.compareTo(b.timeStart)));
      final totalUnits = all.fold<int>(0, (s, e) => s + e.subject.units);
      final conflictCount = all.where((e) => e.hasConflict).length;

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('My Schedule',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('${all.length} classes · $totalUnits units',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: conflictCount > 0 ? AppColors.conflict : AppColors.available,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      conflictCount > 0 ? '$conflictCount conflict${conflictCount > 1 ? 's' : ''}' : 'No conflicts',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: conflictCount > 0 ? AppColors.conflict : AppColors.available,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', ..._days].map((day) {
                        final active = _selectedDay == day;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? AppColors.darkGray : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: active ? AppColors.darkGray : AppColors.borderGray),
                            ),
                            child: Text(
                              day == 'ALL' ? 'ALL' : day.substring(0, 3).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.lightGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                icon: Icons.free_breakfast_outlined,
                message: _selectedDay == 'ALL' ? 'No classes assigned yet' : 'No classes on $_selectedDay',
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ScheduleCard(entry: filtered[i]),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry;
  const _ScheduleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasConflict = entry.hasConflict;
    final statusColor = hasConflict ? AppColors.conflict : AppColors.available;
    final isLab = entry.subject.type.toString().contains('laboratory');

    return Container(
      decoration: kCardDecoration(borderColor: statusColor.withValues(alpha: 0.3)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(hasConflict ? 'Conflict Detected' : 'Scheduled',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            const Spacer(),
            _Chip(entry.day, color: AppColors.midGray),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(entry.subject.name,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
                _Chip(isLab ? 'Laboratory' : 'Lecture', color: AppColors.lightGray),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (entry.room.hasProjector) _InfoChip(Icons.tv_outlined, 'Projector'),
                if (entry.room.hasAirConditioning) _InfoChip(Icons.ac_unit_outlined, 'AC'),
                if (entry.room.hasComputers) _InfoChip(Icons.computer_outlined, 'Computers'),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgGray,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.subject.code} · ${entry.section}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    const SizedBox(height: 3),
                    Text('${entry.room.name} · ${entry.timeStart}–${entry.timeEnd}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Profile Tab
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final t = state.currentTeacher!;
      final liveUnits = state.getTeacherSchedule(t.id).fold<int>(0, (s, e) => s + e.subject.units);
      final isOver = liveUnits > t.maxUnits;

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('My Profile',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(children: [
                  Container(
                    decoration: kCardDecoration(),
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: AppColors.darkGray, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text('${t.firstName[0]}${t.lastName[0]}',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.fullName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                            Text(t.department, style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
                            Text(t.employeeId, style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: kCardDecoration(),
                    child: Column(children: [
                      _ProfileRow(Icons.email_outlined, 'Email', t.email),
                      const Divider(height: 1),
                      _ProfileRow(Icons.work_outline, 'Unit Type', t.unitType),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(children: [
                          Icon(Icons.book_outlined, size: 16, color: isOver ? AppColors.conflict : AppColors.lightGray),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Teaching Units', style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray))),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$liveUnits / ${t.maxUnits}',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isOver ? AppColors.conflict : AppColors.darkGray)),
                              Text(isOver ? 'Overloaded' : liveUnits == 0 ? 'No classes yet' : 'Current load',
                                  style: GoogleFonts.inter(fontSize: 10,
                                      color: isOver ? AppColors.conflict : AppColors.lightGray)),
                            ],
                          ),
                        ]),
                      ),
                      const Divider(height: 1),
                      _ProfileRow(Icons.star_outline, 'Expertise',
                          t.expertise.isEmpty ? 'Not set' : t.expertise.join(', ')),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        state.logout();
                        if (!ctx.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          ctx,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.conflict,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.lightGray),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray))),
        Flexible(child: Text(value, textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkGray))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightGray, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: AppColors.borderGray), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppColors.lightGray),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.midGray)),
      ]),
    );
  }
}

class _InlineInfo extends StatelessWidget {
  final String message;
  const _InlineInfo(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, size: 13, color: AppColors.lightGray),
        const SizedBox(width: 8),
        Text(message, style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
      ]),
    );
  }
}