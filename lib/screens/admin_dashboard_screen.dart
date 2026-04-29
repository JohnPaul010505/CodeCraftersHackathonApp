import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import 'conflict_resolver_screen.dart';
import 'conflict_detection_screen.dart';
import 'admin_chatbot_screen.dart';
import 'room_availability_screen.dart';
import 'teacher_management_screen.dart';

class AdminDashboardBody extends StatelessWidget {
  final void Function(int) onNavigate;
  const AdminDashboardBody({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final occ = state.occupancyRate;
      final bgColor = AppColors.dashBgColor(occ);
      final pendingRequests = state.pendingChatRequests;

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        body: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                backgroundColor: AppColors.darkGray,
                elevation: 0,
                actions: [
                  // Room Override button
                  IconButton(
                    icon: const Icon(Icons.event_available_outlined, color: Colors.white),
                    tooltip: 'Room Override',
                    onPressed: () => _showRoomOverrideDialog(ctx, state),
                  ),
                  // Notifications bell with badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => _showNotificationsDialog(ctx, state),
                      ),
                      if (pendingRequests > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$pendingRequests',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Welcome, Administrator',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick Action Buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _QuickActionButton(
                                    icon: Icons.settings_outlined,
                                    label: 'Manage Rooms',
                                    onTap: () => onNavigate(1),
                                  ),
                                  const SizedBox(width: 10),
                                  _QuickActionButton(
                                    icon: Icons.school_outlined,
                                    label: 'Manage Teachers',
                                    onTap: () => onNavigate(2),
                                  ),
                                  const SizedBox(width: 10),
                                  _QuickActionButton(
                                    icon: Icons.build_circle_outlined,
                                    label: 'Conflict Resolver',
                                    onTap: () => Navigator.push(
                                      ctx,
                                      MaterialPageRoute(
                                        builder: (_) => const ConflictResolverScreen(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Occupancy Banner ──────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(color: bgColor),
                      child: Column(
                        children: [
                          Text(
                            '${state.availableRooms} / ${state.rooms.length}',
                            style: GoogleFonts.inter(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusText(occ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.darkGray.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Stat Cards 2x2 ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Stat Cards 2x2 flat grid ──────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.borderGray),
                            ),
                            child: Column(
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Available Rooms',
                                          value: '${state.availableRooms}',
                                          icon: Icons.meeting_room_outlined,
                                          color: AppColors.available,
                                          onTap: () => onNavigate(1),
                                        ),
                                      ),
                                      Container(width: 1, color: AppColors.borderGray),
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Occupied Rooms',
                                          value: '${state.occupiedRooms}',
                                          icon: Icons.event_busy_outlined,
                                          color: AppColors.conflict,
                                          onTap: () => onNavigate(1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(height: 1, color: AppColors.borderGray),
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Scheduled Classes',
                                          value: '${state.scheduledClasses}',
                                          icon: Icons.calendar_today_outlined,
                                          color: AppColors.darkGray,
                                          onTap: () => onNavigate(4),
                                        ),
                                      ),
                                      Container(width: 1, color: AppColors.borderGray),
                                      Expanded(
                                        child: _StatCard(
                                          label: 'Conflict Alerts',
                                          value: '${state.activeConflicts}',
                                          icon: Icons.warning_amber_outlined,
                                          color: state.activeConflicts > 0
                                              ? AppColors.warning
                                              : AppColors.available,
                                          onTap: () => Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder: (_) => const ConflictDetectionScreen(),
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

                          const SizedBox(height: 20),

                          // ── Room Distribution ──────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderGray),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room Distribution',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _TappableDonutChart(
                                      title: 'Room Type',
                                      values: [
                                        state.rooms.where((r) => r.type == RoomType.lecture).length.toDouble(),
                                        state.rooms.where((r) => r.type == RoomType.laboratory).length.toDouble(),
                                      ],
                                      colors: const [Color(0xFF5C6BC0), Color(0xFFAB47BC)],
                                      labels: ['Lecture', 'Lab'],
                                    ),
                                    _TappableDonutChart(
                                      title: 'Availability',
                                      values: [
                                        state.availableRooms.toDouble(),
                                        state.occupiedRooms.toDouble(),
                                      ],
                                      colors: const [Color(0xFF26A69A), Color(0xFFEF5350)],
                                      labels: ['Available', 'Occupied'],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Teacher Workload ───────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderGray),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher Workload',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _TeacherWorkloadChart(teachers: state.teachers),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Semester Information ───────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderGray),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semester Information',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _InfoRow('Current Semester', '1st Semester 2024-2025'),
                                _InfoRow('Total Rooms', '${state.rooms.length}'),
                                _InfoRow('Active Teachers', '${state.teachers.length}'),
                                _InfoRow('Scheduled Sections', '${state.scheduledClasses}'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      );
    });
  }

  static String _statusText(double occ) {
    if (occ < 0.3) return 'Many rooms available';
    if (occ < 0.6) return 'Moderate room usage';
    if (occ < 0.85) return 'Few rooms available';
    return 'All rooms occupied';
  }

  // ── Notifications dialog ─────────────────────────────────────────────────
  void _showNotificationsDialog(BuildContext context, AppState state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'notifications',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: _NotificationsDialog(state: state),
            ),
          ),
        );
      },
    );
  }

  // ── Room Override dialog ─────────────────────────────────────────────────
  void _showRoomOverrideDialog(BuildContext context, AppState state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'room_override',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: _RoomOverrideDialog(state: state),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Button
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.darkGray),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.lightGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Workload Chart
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherWorkloadChart extends StatefulWidget {
  final List teachers;
  const _TeacherWorkloadChart({required this.teachers});

  @override
  State<_TeacherWorkloadChart> createState() => _TeacherWorkloadChartState();
}

class _TeacherWorkloadChartState extends State<_TeacherWorkloadChart> {
  int? _hoveredTeacher;

  @override
  Widget build(BuildContext context) {
    if (widget.teachers.isEmpty) return const SizedBox.shrink();

    final maxVal = widget.teachers.fold<double>(0, (prev, t) {
      final m = (t.maxUnits as int).toDouble();
      return m > prev ? m : prev;
    });
    final yMax = ((maxVal / 5).ceil() * 5).toDouble().clamp(5.0, double.infinity);
    const ySteps = 5;
    final stepVal = (yMax / ySteps).ceil();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(ySteps + 1, (i) {
                  final val = stepVal * (ySteps - i);
                  return Text('$val',
                      style: GoogleFonts.inter(
                          fontSize: 9, color: AppColors.lightGray));
                }),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CustomPaint(
                  painter: _WorkloadGridPainter(ySteps: ySteps),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.teachers.asMap().entries.map<Widget>((entry) {
                      final i = entry.key;
                      final t = entry.value;
                      final cur = (t.currentUnits as int).toDouble();
                      final max = (t.maxUnits as int).toDouble();
                      final over = cur > max;
                      final curH = (cur / (stepVal * ySteps)).clamp(0.0, 1.0);
                      final maxH = (max / (stepVal * ySteps)).clamp(0.0, 1.0);
                      final isHovered = _hoveredTeacher == i;

                      return GestureDetector(
                        onTap: () => setState(() =>
                        _hoveredTeacher = _hoveredTeacher == i ? null : i),
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredTeacher = i),
                          onExit: (_) => setState(() => _hoveredTeacher = null),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _GradientBar(
                                      fraction: curH,
                                      gradient: over
                                          ? const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [AppColors.conflict, Color(0xFFFF6B6B)])
                                          : const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                                      width: isHovered ? 17 : 14,
                                    ),
                                    const SizedBox(width: 2),
                                    _GradientBar(
                                      fraction: maxH,
                                      gradient: const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
                                      width: isHovered ? 17 : 14,
                                    ),
                                  ],
                                ),
                                if (isHovered)
                                  Positioned(
                                    bottom: (maxH * 150) + 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkGray,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2)),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t.fullName as String,
                                            style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            'Current: ${t.currentUnits}u / Max: ${t.maxUnits}u',
                                            style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: Colors.white70),
                                          ),
                                          if (over)
                                            Text(
                                              '⚠ Overloaded',
                                              style: GoogleFonts.inter(
                                                  fontSize: 9,
                                                  color: const Color(0xFFFF6B6B),
                                                  fontWeight: FontWeight.w600),
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
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 28),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: widget.teachers.map<Widget>((t) {
                  return SizedBox(
                    width: 38,
                    child: Text(
                      t.firstName as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: AppColors.lightGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
              ),
            ),
            const SizedBox(width: 5),
            Text('Current Units',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
            const SizedBox(width: 16),
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])),
            ),
            const SizedBox(width: 5),
            Text('Max Units',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
          ],
        ),
      ],
    );
  }
}

class _GradientBar extends StatelessWidget {
  final double fraction;
  final Gradient gradient;
  final double width;

  const _GradientBar({required this.fraction, required this.gradient, required this.width});

  @override
  Widget build(BuildContext context) {
    const chartH = 150.0;
    final barH = (fraction * chartH).clamp(4.0, chartH);
    return SizedBox(
      width: width,
      height: chartH,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: barH,
          decoration: BoxDecoration(gradient: gradient),
        ),
      ),
    );
  }
}

class _WorkloadGridPainter extends CustomPainter {
  final int ySteps;
  const _WorkloadGridPainter({required this.ySteps});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= ySteps; i++) {
      final y = size.height * i / ySteps;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    paint.color = const Color(0xFFCCCCCC);
    paint.strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_WorkloadGridPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable Donut Chart
// ─────────────────────────────────────────────────────────────────────────────
class _TappableDonutChart extends StatefulWidget {
  final String title;
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;

  const _TappableDonutChart({
    required this.title,
    required this.values,
    required this.colors,
    required this.labels,
  });

  @override
  State<_TappableDonutChart> createState() => _TappableDonutChartState();
}

class _TappableDonutChartState extends State<_TappableDonutChart>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTapSegment(Offset localPos, Size chartSize) {
    final total = widget.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(chartSize.width / 2, chartSize.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = (dx * dx + dy * dy).abs();
    final outerR = (chartSize.width / 2 - 4);
    final innerR = outerR - 20.0;
    if (dist < innerR * innerR || dist > outerR * outerR * 1.2) {
      setState(() => _hoveredIndex = null);
      _animCtrl.reverse();
      return;
    }
    double startAngle = -3.14159 / 2;
    for (int i = 0; i < widget.values.length; i++) {
      final sweep = (widget.values[i] / total) * 2 * 3.14159;
      double endAngle = startAngle + sweep;
      double tapAngle = _atan2(dy, dx);
      if (_angleInRange(tapAngle, startAngle, endAngle)) {
        setState(() => _hoveredIndex = i);
        _animCtrl.forward(from: 0);
        return;
      }
      startAngle = endAngle;
    }
    setState(() {
      _hoveredIndex = _hoveredIndex == null
          ? 0
          : (_hoveredIndex! + 1) % widget.values.length;
    });
    _animCtrl.forward(from: 0);
  }

  double _atan2(double y, double x) {
    if (x > 0) return (y / x < 0 ? -1 : 1) * _approxAtan((y / x).abs()) * (y < 0 ? -1 : 1);
    if (x < 0 && y >= 0) return _approxAtan((y / x).abs()) + 3.14159;
    if (x < 0 && y < 0) return _approxAtan((y / x).abs()) - 3.14159;
    if (x == 0 && y > 0) return 3.14159 / 2;
    if (x == 0 && y < 0) return -3.14159 / 2;
    return 0;
  }

  double _approxAtan(double z) {
    return (3.14159 / 4) * z - z * (z - 1) * (0.2447 + 0.0663 * z);
  }

  bool _angleInRange(double angle, double start, double end) {
    while (angle < -3.14159) angle += 2 * 3.14159;
    while (angle > 3.14159) angle -= 2 * 3.14159;
    while (start < -3.14159) start += 2 * 3.14159;
    while (end > 3.14159) end -= 2 * 3.14159;
    if (start <= end) return angle >= start && angle <= end;
    return angle >= start || angle <= end;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.values.fold(0.0, (a, b) => a + b);
    const chartSize = 130.0;

    return GestureDetector(
      onTapDown: (d) => _onTapSegment(d.localPosition, const Size(chartSize, chartSize)),
      child: Column(
        children: [
          Text(
            widget.title,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.lightGray),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: chartSize,
            height: chartSize + 30,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                SizedBox(
                  width: chartSize,
                  height: chartSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(chartSize, chartSize),
                        painter: _HoverDonutPainter(
                          values: widget.values,
                          colors: widget.colors,
                          total: total,
                          hoveredIndex: _hoveredIndex,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.values.asMap().entries.map((e) {
                          final isHovered = _hoveredIndex == e.key;
                          return Text(
                            '${e.value.toInt()}',
                            style: GoogleFonts.inter(
                              fontSize: isHovered ? 13 : 10,
                              fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                              color: isHovered ? widget.colors[e.key] : AppColors.lightGray,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (_hoveredIndex != null)
                  Positioned(
                    right: -55,
                    top: chartSize * 0.3,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderGray),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(2, 2)),
                          ],
                        ),
                        child: Text(
                          '${widget.labels[_hoveredIndex!]} : ${widget.values[_hoveredIndex!].toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkGray,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.colors.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: widget.colors[e.key], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.labels[e.key]}: ${widget.values[e.key].toInt()}',
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _HoverDonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double total;
  final int? hoveredIndex;

  const _HoverDonutPainter({
    required this.values,
    required this.colors,
    required this.total,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 22.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    double startAngle = -3.14159 / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < values.length; i++) {
      if (total <= 0) continue;
      final sweep = (values[i] / total) * 2 * 3.14159;
      final isHov = hoveredIndex == i;
      final radius = isHov
          ? (size.width / 2 - strokeW / 2 - 2)
          : (size.width / 2 - strokeW / 2 - 6);
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      paint.color = isHov ? colors[i] : colors[i].withValues(alpha: 0.75);
      paint.strokeWidth = isHov ? strokeW + 4 : strokeW;
      canvas.drawArc(rect, startAngle + 0.03, sweep - 0.06, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_HoverDonutPainter old) =>
      old.hoveredIndex != hoveredIndex || old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label, value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.midGray),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationsDialog extends StatefulWidget {
  final AppState state;

  const _NotificationsDialog({required this.state});

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    // Consumer ensures the panel rebuilds in real-time whenever AppState changes —
    // no manual refresh needed when a teacher sends a new chat request.
    return Consumer<AppState>(
      builder: (context, liveState, _) {
        final _rawPending = liveState.chatMessages.where((m) => !m.isResolved).toList();
        final _seenIds = <String>{};
        final pending = _rawPending.where((m) => _seenIds.add(m.id)).toList();
        final _seenR = <String>{};
        final resolved = liveState.chatMessages.where((m) => m.isResolved && _seenR.add(m.id)).toList();

        return Material(
          color: Colors.transparent,
          child: Container(
            width: 380,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const Icon(Icons.notifications, size: 26, color: AppColors.darkGray),
                          if (pending.isNotEmpty)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${pending.length}',
                                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teacher Requests',
                              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                            ),
                            Text(
                              '${pending.length} pending approval',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.lightGray),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Pending Requests',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                      ),
                      const SizedBox(height: 12),

                      if (pending.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No pending requests',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray),
                            ),
                          ),
                        ),

                      ...pending.map((msg) => _NotifRequestCard(
                        message: msg,
                        isExpanded: _expandedId == msg.id,
                        onTap: () => setState(() {
                          _expandedId = _expandedId == msg.id ? null : msg.id;
                        }),
                        onApprove: (response) {
                          // Auto-adjusts the entire system (schedule, rooms, teacher status)
                          liveState.approveTeacherRequest(msg, response);
                          setState(() { _expandedId = null; });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Request approved & schedule adjusted!', style: GoogleFonts.inter()),
                              backgroundColor: AppColors.available,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        onReject: () {
                          liveState.respondToChat(msg.id, 'Your request has been reviewed and unfortunately cannot be approved at this time.');
                          setState(() { _expandedId = null; });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request rejected.', style: GoogleFonts.inter()),
                              backgroundColor: AppColors.conflict,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      )),

                      if (resolved.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                        ),
                        const SizedBox(height: 10),
                        ...resolved.take(5).map((msg) {
                          // Use the explicit wasApproved flag set at action time
                          final isRejected = msg.wasApproved == false;
                          final badgeColor = isRejected ? AppColors.conflict : AppColors.available;
                          final badgeLabel = isRejected ? 'rejected' : 'approved';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgGray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(badgeLabel, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.message.length > 80 ? '${msg.message.substring(0, 80)}...' : msg.message,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray),
                                ),
                                if (msg.adminResponse != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Response: ${msg.adminResponse}',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray),
                                  ),
                                ],
                              ],
                            ),
                          );}),
                      ],
                    ],
                  ),
                ),

                // Footer
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderGray),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Close', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ); // end Material
      }, // end Consumer builder
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Card inside Notifications Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _NotifRequestCard extends StatelessWidget {
  final ChatMessage message;
  final bool isExpanded;
  final VoidCallback onTap;
  final Function(String) onApprove;
  final VoidCallback onReject;

  const _NotifRequestCard({
    required this.message,
    required this.isExpanded,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  Color get _typeColor {
    if (message.message.toLowerCase().contains('emergency')) return AppColors.conflict;
    if (message.message.toLowerCase().contains('absent') || message.message.toLowerCase().contains('absence')) return AppColors.warning;
    return AppColors.red;
  }

  String get _typeLabel {
    if (message.message.toLowerCase().contains('emergency')) return 'emergency';
    if (message.message.toLowerCase().contains('absent') || message.message.toLowerCase().contains('absence')) return 'absence';
    return 'schedule-change';
  }

  IconData get _typeIcon {
    if (message.message.toLowerCase().contains('emergency')) return Icons.warning_amber;
    if (message.message.toLowerCase().contains('absent') || message.message.toLowerCase().contains('absence')) return Icons.event;
    return Icons.swap_horiz;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? AppColors.darkGray.withValues(alpha: 0.4) : AppColors.borderGray,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_typeIcon, color: _typeColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderName,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray),
                        ),
                        Text(
                          'Computer Science',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _typeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _typeLabel,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message.message,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${DateFormat('MMM dd, yyyy HH:mm').format(message.timestamp)}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _ApproveSection(onApprove: onApprove, onReject: onReject),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approve Section
// ─────────────────────────────────────────────────────────────────────────────
class _ApproveSection extends StatefulWidget {
  final Function(String) onApprove;
  final VoidCallback onReject;

  const _ApproveSection({required this.onApprove, required this.onReject});

  @override
  State<_ApproveSection> createState() => _ApproveSectionState();
}

class _ApproveSectionState extends State<_ApproveSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Admin Response (Optional)',
            labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray),
            hintText: 'Add a message for the teacher...',
            hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onReject,
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text('Reject', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.conflict,
                  side: const BorderSide(color: AppColors.conflict),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onApprove(_ctrl.text.trim().isEmpty
                    ? 'Schedule automatically adjusted.'
                    : _ctrl.text.trim()),
                icon: const Icon(Icons.check_circle_outlined, size: 16),
                label: Text('Approve', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.available,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROOM OVERRIDE DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _RoomOverrideDialog extends StatefulWidget {
  final AppState state;
  const _RoomOverrideDialog({required this.state});

  @override
  State<_RoomOverrideDialog> createState() => _RoomOverrideDialogState();
}

class _RoomOverrideDialogState extends State<_RoomOverrideDialog> {
  bool _showAddForm = false;
  bool _saving = false;
  String? _selectedRoomId;
  final _reasonCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() {
      if (isStart) _startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      else _endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _addOverride() async {
    if (_selectedRoomId == null || _reasonCtrl.text.trim().isEmpty ||
        _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all fields', style: GoogleFonts.inter()),
        backgroundColor: AppColors.conflict,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('End date must be after start date', style: GoogleFonts.inter()),
        backgroundColor: AppColors.conflict,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    setState(() => _saving = true);
    final room = widget.state.rooms.firstWhere(
          (r) => r.id == _selectedRoomId,
      orElse: () => widget.state.rooms.first,
    );
    final override = RoomOverride(
      id: '',
      roomId: _selectedRoomId!,
      roomName: room.name,
      reason: _reasonCtrl.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    );
    await widget.state.addRoomOverride(override);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _showAddForm = false;
      _selectedRoomId = null;
      _reasonCtrl.clear();
      _startDate = null;
      _endDate = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Override added — ${room.name} is now blocked', style: GoogleFonts.inter()),
      backgroundColor: AppColors.warning,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd, yyyy HH:mm');
    // Use live data from AppState — no local list
    final overrides = widget.state.roomOverrides;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Room Availability Override',
                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        Text('Block rooms for events, meetings, or maintenance',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.lightGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Add / Cancel toggle button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddForm = !_showAddForm),
                      icon: Icon(_showAddForm ? Icons.close : Icons.add, size: 18),
                      label: Text(_showAddForm ? 'Cancel' : 'Add Room Override',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGray,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  // ── Add form ──────────────────────────────────────────────
                  if (_showAddForm) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create New Override',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                          const SizedBox(height: 14),
                          // Room picker
                          DropdownButtonFormField<String>(
                            value: _selectedRoomId,
                            hint: Text('Select Room', style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: widget.state.rooms.map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text('${r.name} (Floor ${r.floor})', style: GoogleFonts.inter(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedRoomId = v),
                          ),
                          const SizedBox(height: 12),
                          // Reason
                          TextField(
                            controller: _reasonCtrl,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Reason (e.g. Faculty Meeting)',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderGray)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.red)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Date pickers
                          Row(children: [
                            Expanded(child: _dateTile('Start', _startDate, fmt, () => _pickDateTime(true))),
                            const SizedBox(width: 10),
                            Expanded(child: _dateTile('End', _endDate, fmt, () => _pickDateTime(false))),
                          ]),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _addOverride,
                              icon: _saving
                                  ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline, size: 18),
                              label: Text('Create Override',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkGray,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Text('Active Overrides (${overrides.length})',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                  const SizedBox(height: 10),

                  // Empty state
                  if (overrides.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(10)),
                      child: Text('No active room overrides. Rooms are operating on normal schedule.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
                    ),

                  // Override cards — from Firestore via AppState
                  ...overrides.map((ov) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_busy, color: AppColors.warning, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ov.roomName,
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(20)),
                                child: Text(ov.reason,
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                              const SizedBox(height: 8),
                              Text('Start: ${fmt.format(ov.startDate)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
                              const SizedBox(height: 2),
                              Text('End: ${fmt.format(ov.endDate)}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.conflict, size: 20),
                          onPressed: () async {
                            await widget.state.deleteRoomOverride(ov.id);
                            // Restore room to available only if no other override still blocks it
                            final stillBlocked = widget.state.roomOverrides.any((o) => o.roomId == ov.roomId);
                            if (!stillBlocked) {
                              widget.state.updateRoomStatus(ov.roomId, RoomStatus.available, eventNote: null);
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Override removed — ${ov.roomName} is now available', style: GoogleFonts.inter()),
                              backgroundColor: AppColors.available,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ));
                          },
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderGray),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Close', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? dt, DateFormat fmt, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: dt != null ? AppColors.red.withValues(alpha: 0.5) : AppColors.borderGray),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label Date & Time', style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
          const SizedBox(height: 2),
          Text(
            dt != null ? fmt.format(dt) : 'Tap to select',
            style: GoogleFonts.inter(fontSize: 12, color: dt != null ? AppColors.darkGray : AppColors.lightGray),
          ),
        ]),
      ),
    );
  }
}