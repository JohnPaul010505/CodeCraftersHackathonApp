import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import 'room_manager_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RoomAvailabilityScreen
// ─────────────────────────────────────────────────────────────────────────────
class RoomAvailabilityScreen extends StatefulWidget {
  const RoomAvailabilityScreen({super.key});
  @override
  State<RoomAvailabilityScreen> createState() => _RoomAvailabilityScreenState();
}

class _RoomAvailabilityScreenState extends State<RoomAvailabilityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _floorFilter;
  String? _equipFilter;
  int _statusIdx = 0; // 0=All, 1=Available, 2=Unavailable
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));

    // Re-evaluate schedule-based occupancy every 60 seconds so both
    // admin and teacher views stay in sync without manual refresh.
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });

    // On first load, pull the latest room statuses from Firestore so
    // any admin change made in a different session is picked up immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadRoomsFromFirestore();
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  RoomType? get _typeFilter {
    if (_tab.index == 1) return RoomType.lecture;
    if (_tab.index == 2) return RoomType.laboratory;
    return null;
  }

  // Real-time: is room currently occupied based on today's schedule?
  bool _isCurrentlyOccupied(Room room, List<ScheduleEntry> allSchedule) {
    final now = DateTime.now();
    final todayName = _dayName(now.weekday);
    if (todayName == null) return false;
    final nowMin = now.hour * 60 + now.minute;
    return allSchedule.any((e) =>
    e.room.id == room.id &&
        e.day == todayName &&
        _toMin(e.timeStart) <= nowMin &&
        nowMin < _toMin(e.timeEnd));
  }

  ScheduleEntry? _currentClass(Room room, List<ScheduleEntry> allSchedule) {
    final now = DateTime.now();
    final todayName = _dayName(now.weekday);
    if (todayName == null) return null;
    final nowMin = now.hour * 60 + now.minute;
    try {
      return allSchedule.firstWhere((e) =>
      e.room.id == room.id &&
          e.day == todayName &&
          _toMin(e.timeStart) <= nowMin &&
          nowMin < _toMin(e.timeEnd));
    } catch (_) { return null; }
  }

  ScheduleEntry? _nextClass(Room room, List<ScheduleEntry> allSchedule) {
    final now = DateTime.now();
    final todayName = _dayName(now.weekday);
    if (todayName == null) return null;
    final nowMin = now.hour * 60 + now.minute;
    final upcoming = allSchedule.where((e) =>
    e.room.id == room.id && e.day == todayName && _toMin(e.timeStart) > nowMin).toList()
      ..sort((a, b) => _toMin(a.timeStart).compareTo(_toMin(b.timeStart)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  String? _dayName(int weekday) {
    const map = {1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday'};
    return map[weekday];
  }

  int _toMin(String t) { final p = t.split(':'); return int.parse(p[0]) * 60 + int.parse(p[1]); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final isAdmin = state.isAdmin;
      final allSchedule = state.scheduleEntries;
      final floors = state.rooms.map((r) => r.floor).toSet().toList()..sort();

      // Filter rooms
      var filtered = state.rooms.where((r) {
        if (_typeFilter != null && r.type != _typeFilter) return false;
        if (_floorFilter != null && r.floor != _floorFilter) return false;
        if (_equipFilter == 'projector' && !r.hasProjector) return false;
        if (_equipFilter == 'ac' && !r.hasAirConditioning) return false;
        if (_equipFilter == 'computers' && !r.hasComputers) return false;
        return true;
      }).toList();

      // Real-time availability: treat manually-set occupied/event/maintenance as unavailable
      final rtAvail = filtered.where((r) {
        if (r.status == RoomStatus.event || r.status == RoomStatus.maintenance || r.status == RoomStatus.occupied) return false;
        return !_isCurrentlyOccupied(r, allSchedule);
      }).toList();
      final rtUnavail = filtered.where((r) {
        if (r.status == RoomStatus.event || r.status == RoomStatus.maintenance || r.status == RoomStatus.occupied) return true;
        return _isCurrentlyOccupied(r, allSchedule);
      }).toList();

      final display = _statusIdx == 1 ? rtAvail : _statusIdx == 2 ? rtUnavail : filtered;
      final now = DateTime.now();

      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Rooms', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Live · ${DateFormat('EEE, MMM d · h:mm a').format(now)}',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ]),
          actions: [
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _showRoomPanel(ctx),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: Text('Add Room', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          final maxW = isWide ? 900.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(children: [
                // ── Filter panel ────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(children: [
                    // Type tabs
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(color: AppColors.darkGray, borderRadius: BorderRadius.circular(6)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.lightGray,
                        labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
                        tabs: const [Tab(text: 'ALL'), Tab(text: 'LECTURE'), Tab(text: 'LAB')],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Floor + Equipment row
                    Row(children: [
                      Expanded(child: _filterDropdown<int?>(
                        _floorFilter, [null, ...floors],
                            (v) => setState(() => _floorFilter = v),
                            (v) => v == null ? 'All Floors' : 'Floor $v',
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _filterDropdown<String?>(
                        _equipFilter, [null, 'projector', 'ac', 'computers'],
                            (v) => setState(() => _equipFilter = v),
                            (v) => v == null ? 'All Equipment' : v == 'projector' ? 'Projector' : v == 'ac' ? 'Air Con.' : 'Computers',
                      )),
                    ]),
                    const SizedBox(height: 10),
                    // Status chips + legend
                    Row(children: [
                      _chip(0, 'All', filtered.length),
                      const SizedBox(width: 6),
                      _chip(1, 'Available', rtAvail.length),
                      const SizedBox(width: 6),
                      _chip(2, 'Unavailable', rtUnavail.length),
                      const Spacer(),
                      _dot(AppColors.available, 'Free'),
                      const SizedBox(width: 8),
                      _dot(AppColors.conflict, 'Busy'),
                    ]),
                    const SizedBox(height: 10),
                    // Summary bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.circle, size: 10, color: AppColors.available),
                        const SizedBox(width: 6),
                        Text('${rtAvail.length} rooms free right now',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.available)),
                        const Spacer(),
                        Text('${display.length} shown', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ]),
                ),
                Divider(height: 1, color: Colors.grey.shade200),

                // ── Room list ────────────────────────────────────────────────
                Expanded(
                  child: display.isEmpty
                      ? _emptyState()
                      : isWide
                      ? _wideGrid(ctx, display, allSchedule, isAdmin, state)
                      : _narrowList(ctx, display, allSchedule, isAdmin, state),
                ),
              ]),
            ),
          );
        }),
      );
    });
  }

  // Wide grid (web) — 2 columns
  Widget _wideGrid(BuildContext ctx, List<Room> rooms, List<ScheduleEntry> schedule, bool isAdmin, AppState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      // mainAxisExtent gives a fixed pixel height per cell so cards with event-note
      // rows or class blocks can never overflow regardless of screen width.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisExtent: 270, mainAxisSpacing: 12, crossAxisSpacing: 12),
      itemCount: rooms.length,
      itemBuilder: (_, i) => _RoomCard(
        room: rooms[i],
        currentClass: _currentClass(rooms[i], schedule),
        nextClass: _nextClass(rooms[i], schedule),
        isAdmin: isAdmin,
        onTap: () => _openCalendar(ctx, rooms[i]),
        onEdit: isAdmin ? () => _showRoomPanel(ctx, rooms[i]) : null,
        onStatusChange: isAdmin ? (s) => state.updateRoomStatus(rooms[i].id, s) : null,
      ),
    );
  }

  // Narrow list (mobile)
  Widget _narrowList(BuildContext ctx, List<Room> rooms, List<ScheduleEntry> schedule, bool isAdmin, AppState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: rooms.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RoomCard(
        room: rooms[i],
        currentClass: _currentClass(rooms[i], schedule),
        nextClass: _nextClass(rooms[i], schedule),
        isAdmin: isAdmin,
        onTap: () => _openCalendar(ctx, rooms[i]),
        onEdit: isAdmin ? () => _showRoomPanel(ctx, rooms[i]) : null,
        onStatusChange: isAdmin ? (s) => state.updateRoomStatus(rooms[i].id, s) : null,
      ),
    );
  }


  void _showRoomPanel(BuildContext context, [Room? room]) {
    // Capture AppState from the outer context BEFORE the dialog opens so the
    // same singleton is injected into the dialog's isolated widget tree.
    final appState = Provider.of<AppState>(context, listen: false);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'room_panel',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Material(
                color: Colors.transparent,
                // ── KEY FIX ──────────────────────────────────────────────
                // showGeneralDialog creates a new route whose context may not
                // inherit InheritedWidgets from the caller. We explicitly
                // re-provide the same AppState instance so that any
                // Provider.of<AppState>() call inside RoomManagerScreen hits
                // the correct, shared singleton — ensuring that addRoom() /
                // updateRoom() mutate the same _rooms list that every other
                // screen (Schedule, Teachers, Subjects) reads from.
                child: ChangeNotifierProvider<AppState>.value(
                  value: appState,
                  child: Container(
                    width: 420,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: RoomManagerScreen(room: room),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCalendar(BuildContext ctx, Room room) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomCalendarScreen(room: room)));
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.meeting_room_outlined, size: 52, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('No rooms match your filters', style: GoogleFonts.inter(fontSize: 15, color: AppColors.lightGray)),
  ]));

  Widget _chip(int idx, String label, int count) {
    final active = _statusIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _statusIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.darkGray : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.darkGray : AppColors.borderGray),
        ),
        child: Text('$label ($count)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.lightGray)),
      ),
    );
  }

  Widget _dot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
  ]);

  Widget _filterDropdown<T>(T value, List<T> items, void Function(T) onChange, String Function(T) label) =>
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderGray)),
        child: DropdownButtonHideUnderline(child: DropdownButton<T>(
          value: value, isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkGray),
          icon: const Icon(Icons.expand_more, size: 16),
          items: items.map((v) => DropdownMenuItem<T>(value: v, child: Text(label(v), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) { if (v != null || null is T) onChange(v as T); },
        )),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Card
// ─────────────────────────────────────────────────────────────────────────────
class _RoomCard extends StatelessWidget {
  final Room room;
  final ScheduleEntry? currentClass;
  final ScheduleEntry? nextClass;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final void Function(RoomStatus)? onStatusChange;

  const _RoomCard({required this.room, this.currentClass, this.nextClass,
    required this.isAdmin, required this.onTap, this.onEdit, this.onStatusChange});

  bool get _rtOccupied => currentClass != null;

  Color get _statusColor {
    if (room.status == RoomStatus.event) return AppColors.warning;
    if (room.status == RoomStatus.maintenance) return AppColors.moderate;
    if (room.status == RoomStatus.occupied || _rtOccupied) return AppColors.conflict;
    return AppColors.available;
  }

  String get _statusLabel {
    if (room.status == RoomStatus.event) return 'Event';
    if (room.status == RoomStatus.maintenance) return 'Maintenance';
    if (room.status == RoomStatus.occupied) return _rtOccupied ? 'Occupied Now' : 'Occupied';
    return _rtOccupied ? 'Occupied Now' : 'Available';
  }

  IconData get _statusIcon {
    if (room.status == RoomStatus.event) return Icons.event_outlined;
    if (room.status == RoomStatus.maintenance) return Icons.build_outlined;
    if (room.status == RoomStatus.occupied || _rtOccupied) return Icons.people_alt_outlined;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _statusColor.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [BoxShadow(color: _statusColor.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Status header bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(children: [
              Icon(_statusIcon, size: 14, color: _statusColor),
              const SizedBox(width: 6),
              Text(_statusLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor)),
              const Spacer(),
              // Admin popup
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, size: 18, color: _statusColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'available') onStatusChange?.call(RoomStatus.available);
                    if (v == 'occupied') onStatusChange?.call(RoomStatus.occupied);
                    if (v == 'maintenance') onStatusChange?.call(RoomStatus.maintenance);
                    if (v == 'event') onStatusChange?.call(RoomStatus.event);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: _popItem(Icons.edit_outlined, 'Edit Room', AppColors.darkGray)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'available', child: _popItem(Icons.check_circle_outline, 'Set Available', AppColors.available)),
                    PopupMenuItem(value: 'occupied', child: _popItem(Icons.people_outline, 'Set Occupied', AppColors.conflict)),
                    PopupMenuItem(value: 'maintenance', child: _popItem(Icons.build_outlined, 'Maintenance', AppColors.warning)),
                    PopupMenuItem(value: 'event', child: _popItem(Icons.event_outlined, 'School Event', AppColors.moderate)),
                  ],
                )
              else
                Icon(Icons.chevron_right, size: 16, color: _statusColor.withValues(alpha: 0.6)),
            ]),
          ),

          // ── Room info ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(room.type == RoomType.laboratory ? Icons.science_outlined : Icons.meeting_room_outlined,
                    size: 18, color: AppColors.darkGray),
                const SizedBox(width: 8),
                Text(room.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.borderGray), borderRadius: BorderRadius.circular(20)),
                  child: Text(room.typeLabel, style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
                ),
              ]),
              const SizedBox(height: 3),
              Text('Floor ${room.floor} · Capacity: ${room.capacity} seats',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
              const SizedBox(height: 6),
              // Equipment chips
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (room.hasProjector) _eqChip(Icons.tv_outlined, 'Projector'),
                if (room.hasAirConditioning) _eqChip(Icons.ac_unit_outlined, 'AC'),
                if (room.hasComputers) _eqChip(Icons.computer_outlined, 'Computers'),
              ]),

              // Current class info
              if (_rtOccupied && currentClass != null) ...[
                const SizedBox(height: 8),
                _classBlock(
                  label: 'Current Class',
                  color: AppColors.conflict,
                  entry: currentClass!,
                ),
              ] else if (room.status == RoomStatus.occupied && !_rtOccupied) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.conflict.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.conflict.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.people_alt_outlined, size: 13, color: AppColors.conflict),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Manually set as occupied',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray))),
                  ]),
                ),
              ] else if (room.status == RoomStatus.event && room.eventNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.event_outlined, size: 13, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(child: Text(room.eventNote!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray))),
                  ]),
                ),
              ] else if (room.status == RoomStatus.maintenance && room.eventNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.moderate.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Icon(Icons.build_outlined, size: 13, color: AppColors.moderate),
                    const SizedBox(width: 6),
                    Expanded(child: Text(room.eventNote!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.midGray))),
                  ]),
                ),
              ],

              // Next class
              if (!_rtOccupied && nextClass != null && room.status == RoomStatus.available) ...[
                const SizedBox(height: 8),
                _classBlock(label: 'Next Class', color: AppColors.warning, entry: nextClass!),
              ],

              // Tap hint
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.calendar_month_outlined, size: 12, color: AppColors.lightGray),
                const SizedBox(width: 4),
                Text('Tap to view schedule', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _classBlock({required String label, required Color color, required ScheduleEntry entry}) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text('${entry.subject.code} · ${entry.section}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          Text('${entry.teacher.fullName} · ${entry.timeStart}–${entry.timeEnd}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
        ]),
      );

  Widget _eqChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(border: Border.all(color: AppColors.borderGray), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.lightGray), const SizedBox(width: 3),
      Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.midGray)),
    ]),
  );

  Widget _popItem(IconData icon, String label, Color color) => Row(children: [
    Icon(icon, size: 16, color: color), const SizedBox(width: 8),
    Text(label, style: GoogleFonts.inter(fontSize: 13, color: color)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Room Calendar Screen — Compact, responsive
// ─────────────────────────────────────────────────────────────────────────────
class RoomCalendarScreen extends StatefulWidget {
  final Room room;
  const RoomCalendarScreen({super.key, required this.room});
  @override State<RoomCalendarScreen> createState() => _RoomCalendarScreenState();
}

class _RoomCalendarScreenState extends State<RoomCalendarScreen> {
  DateTime _focus = DateTime.now();
  bool _monthly = true;
  DateTime? _selected;

  static const _days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  static const _abbr = ['Mon','Tue','Wed','Thu','Fri','Sat'];
  static const _months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  String? _toDay(int wd) { const m = {1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday'}; return m[wd]; }
  int _toMin(String t) { final p = t.split(':'); return int.parse(p[0]) * 60 + int.parse(p[1]); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final sched = state.getRoomSchedule(widget.room.id);
      final overrides = state.getRoomOverrides(widget.room.id);
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Room ${widget.room.name}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${widget.room.typeLabel} · Floor ${widget.room.floor}', style: GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _tBtn('M', _monthly, () => setState(() { _monthly = true; _selected = null; })),
                _tBtn('W', !_monthly, () => setState(() { _monthly = false; _selected = null; })),
              ]),
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 700;
          return Center(child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 860.0 : double.infinity),
            child: Column(children: [
              // Navigator row
              Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => setState(() {
                    _focus = _monthly ? DateTime(_focus.year, _focus.month - 1) : _focus.subtract(const Duration(days: 7));
                    _selected = null;
                  })),
                  Expanded(child: Center(child: Text(
                    _monthly ? '${_months[_focus.month]} ${_focus.year}' : _weekLabel(),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                  ))),
                  IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => setState(() {
                    _focus = _monthly ? DateTime(_focus.year, _focus.month + 1) : _focus.add(const Duration(days: 7));
                    _selected = null;
                  })),
                ]),
              ),
              Expanded(child: _monthly ? _monthGrid(sched, overrides) : _weekList(sched, overrides)),
              if (_selected != null) _dayPanel(_selected!, sched, overrides),
            ]),
          ));
        }),
      );
    });
  }

  Widget _tBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
          color: active ? AppColors.darkGray : Colors.white60)),
    ),
  );

  Widget _monthGrid(List<ScheduleEntry> sched, List<RoomOverride> overrides) {
    // Build a list of Mon–Sat cells, skipping Sundays entirely so days align correctly.
    final first = DateTime(_focus.year, _focus.month, 1);
    final daysInMonth = DateTime(_focus.year, _focus.month + 1, 0).day;
    // Monday of the week that contains the 1st
    final startMonday = first.subtract(Duration(days: first.weekday - 1));

    final List<DateTime?> cells = []; // null = blank cell (prev/next month)
    var cur = startMonday;
    bool monthDone = false;
    while (!monthDone || cells.length % 6 != 0) {
      if (cur.weekday != 7) { // skip Sunday
        if (cur.month == _focus.month) {
          cells.add(cur);
          if (cur.day == daysInMonth) monthDone = true;
        } else {
          cells.add(null); // blank outside this month
        }
      }
      cur = cur.add(const Duration(days: 1));
      if (cells.length > 60) break; // safety
    }

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(children: _abbr.map((d) => Expanded(child: Center(
              child: Text(d, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.lightGray))))).toList())),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6, childAspectRatio: 1.0, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: cells.length,
        itemBuilder: (_, idx) {
          final date = cells[idx];
          // Blank cell (outside month)
          if (date == null) {
            return Container(
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            );
          }
          final day = date.day;
          final dayName = _toDay(date.weekday);
          final entries = dayName != null ? sched.where((e) => e.day == dayName).toList() : <ScheduleEntry>[];
          final isSel = _selected != null &&
              _selected!.day == day &&
              _selected!.month == date.month &&
              _selected!.year == date.year;
          final now = DateTime.now();
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
          final blockingOverrides = overrides.where((o) => o.coversDate(date)).toList();
          final isBlocked = blockingOverrides.isNotEmpty;

          Color bgColor = isSel ? AppColors.red
              : isBlocked ? AppColors.warning.withValues(alpha: 0.1)
              : isToday ? AppColors.red.withValues(alpha: 0.08)
              : Colors.white;
          Color borderColor = isSel ? AppColors.red
              : isBlocked ? AppColors.warning.withValues(alpha: 0.6)
              : isToday ? AppColors.red.withValues(alpha: 0.5)
              : AppColors.borderGray;

          return GestureDetector(
            onTap: () => setState(() => _selected = isSel ? null : date),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: isSel ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isSel ? Colors.white
                        : isBlocked ? AppColors.warning
                        : isToday ? AppColors.red
                        : AppColors.darkGray)),
                if (isBlocked && !isSel) ...[
                  const SizedBox(height: 1),
                  const Icon(Icons.block_outlined, size: 9, color: AppColors.warning),
                ] else if (entries.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(width: 5, height: 5, decoration: BoxDecoration(
                      color: isSel ? Colors.white : AppColors.red, shape: BoxShape.circle)),
                  Text('${entries.length}', style: GoogleFonts.inter(fontSize: 9,
                      color: isSel ? Colors.white70 : AppColors.lightGray)),
                ],
              ]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _weekList(List<ScheduleEntry> sched, List<RoomOverride> overrides) {
    final monday = _focus.subtract(Duration(days: _focus.weekday - 1));
    final weekDays = List.generate(6, (i) => monday.add(Duration(days: i)));
    return ListView(padding: const EdgeInsets.all(10), children: weekDays.map((date) {
      if (date.weekday == 7) return const SizedBox();
      final dayName = _toDay(date.weekday)!;
      final entries = sched.where((e) => e.day == dayName).toList()..sort((a, b) => _toMin(a.timeStart).compareTo(_toMin(b.timeStart)));
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
      final blockingOverrides = overrides.where((o) => o.coversDate(date)).toList();
      final isBlocked = blockingOverrides.isNotEmpty;
      return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isBlocked ? AppColors.warning.withValues(alpha: 0.6)
              : isToday ? AppColors.red.withValues(alpha: 0.4) : AppColors.borderGray)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: isBlocked ? AppColors.warning.withValues(alpha: 0.08)
                      : isToday ? AppColors.red.withValues(alpha: 0.05) : const Color(0xFFF2F2F7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9))),
              child: Row(children: [
                if (isBlocked) ...[
                  const Icon(Icons.event_busy, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                ],
                Text('$dayName  ${date.day} ${_months[date.month]}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                        color: isBlocked ? AppColors.warning : isToday ? AppColors.red : AppColors.darkGray)),
                const Spacer(),
                if (isBlocked)
                  Text('Blocked', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600))
                else
                  Text('${entries.length} class${entries.length != 1 ? "es" : ""}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              ])),
          // Show override banners
          ...blockingOverrides.map((ov) => Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.block_outlined, size: 13, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(child: Text('${ov.reason}  (${_fmtTime(ov.startDate)} – ${_fmtTime(ov.endDate)})',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600))),
            ]),
          )),
          if (entries.isEmpty && !isBlocked)
            Padding(padding: const EdgeInsets.all(12), child: Text('No scheduled classes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)))
          else if (entries.isNotEmpty)
            ...entries.map((e) => _entryTile(e)),
          if (blockingOverrides.isNotEmpty && entries.isEmpty)
            const SizedBox(height: 8),
        ]),
      );
    }).toList());
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Widget _dayPanel(DateTime day, List<ScheduleEntry> sched, List<RoomOverride> overrides) {
    final dayName = day.weekday <= 6 ? _days[day.weekday - 1] : 'Sunday';
    final entries = sched.where((e) => e.day == dayName).toList()..sort((a, b) => _toMin(a.timeStart).compareTo(_toMin(b.timeStart)));
    return Container(constraints: const BoxConstraints(maxHeight: 260), decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))]),
      child: Column(children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 6), child: Row(children: [
          Text('$dayName, ${day.day} ${_months[day.month]} ${day.year}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.lightGray),
              onPressed: () => setState(() => _selected = null)),
        ])),
        // Override banners for this day
        ...overrides.where((o) => o.coversDate(day)).map((ov) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.event_busy, size: 14, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Room Override: ${ov.reason}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
              Text('${_fmtTime(ov.startDate)} – ${_fmtTime(ov.endDate)}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
            ])),
          ]),
        )),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(child: entries.isEmpty
            ? Center(child: Text('No classes scheduled for Room ${widget.room.name} on $dayName',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray), textAlign: TextAlign.center))
            : ListView(children: entries.map(_entryTile).toList())),
      ]),
    );
  }

  Widget _entryTile(ScheduleEntry e) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text('${e.timeStart}\n${e.timeEnd}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red), textAlign: TextAlign.center)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.subject.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        Text('${e.subject.code} · ${e.teacher.fullName} · ${e.section}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
      ])),
    ]),
  );

  String _weekLabel() {
    final monday = _focus.subtract(Duration(days: _focus.weekday - 1));
    final saturday = monday.add(const Duration(days: 5));
    return '${monday.day} ${_months[monday.month]} – ${saturday.day} ${_months[saturday.month]}';
  }
}