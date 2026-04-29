import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../models/teacher.dart';
import '../models/room.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Schedule Screen — Calendar view with teacher schedule drill-down
// ─────────────────────────────────────────────────────────────────────────────
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;
  String _filterTeacher = 'All';
  String _filterSection = 'All';
  bool _showAddForm = false;
  ScheduleEntry? _editingEntry;

  static const _fullDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  static const _dayAbbr = ['Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final allTeachers = ['All', ...state.teachers.map((t) => t.fullName).toList()..sort()];
      final allSections = (['All', ...state.sections, ...state.scheduleEntries.map((e) => e.section).where((s) => !state.sections.contains(s))])..sort();

      final filtered = state.scheduleEntries.where((e) {
        if (_filterTeacher != 'All' && e.teacher.fullName != _filterTeacher) return false;
        if (_filterSection != 'All' && e.section != _filterSection) return false;
        return true;
      }).toList();

      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('Class Schedule', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            // Month/Week toggle
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _viewBtn('Month', _isMonthView, () => setState(() { _isMonthView = true; })),
                _viewBtn('Week', !_isMonthView, () => setState(() { _isMonthView = false; })),
              ]),
            ),
            // ── Add Schedule button ──────────────────────────────────
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  final isWide = MediaQuery.sizeOf(ctx).width > 600;
                  if (isWide) {
                    setState(() { _showAddForm = true; _editingEntry = null; });
                  } else {
                    _showMobileAddPanel(ctx, Provider.of<AppState>(ctx, listen: false), null);
                  }
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
                tooltip: 'Add Schedule',
              ),
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, outerConstraints) {
          // ── RIGHT-PANEL FORM (wide screens) ──────────────────────────
          if (_showAddForm && outerConstraints.maxWidth > 600) {
            return Row(children: [
              // Left: full calendar
              Expanded(
                child: _buildCalendarBody(ctx, state, filtered, allTeachers, allSections),
              ),
              Container(width: 1, color: Colors.grey.shade300),
              // Right: add/edit form panel
              SizedBox(
                width: 400,
                child: _ScheduleFormPanel(
                  key: ValueKey(_editingEntry?.id ?? 'new'),
                  existingEntry: _editingEntry,
                  preselectedDay: _selectedDay != null && _selectedDay!.weekday <= 6
                      ? _fullDays[_selectedDay!.weekday - 1] : 'Monday',
                  onSaved: (entry) {
                    if (_editingEntry == null) { state.addScheduleEntry(entry); }
                    else { state.updateScheduleEntry(entry); }
                    setState(() { _showAddForm = false; _editingEntry = null; });
                  },
                  onCancel: () => setState(() { _showAddForm = false; _editingEntry = null; }),
                ),
              ),
            ]);
          }
          // ── NORMAL VIEW ───────────────────────────────────────────────
          return _buildCalendarBody(ctx, state, filtered, allTeachers, allSections);
        }),
      );
    });
  }

  // ── Extracted calendar body ───────────────────────────────────────────────
  Widget _buildCalendarBody(BuildContext ctx, AppState state,
      List<ScheduleEntry> filtered, List<String> allTeachers, List<String> allSections) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      return Center(child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1000.0 : double.infinity),
        child: Column(children: [
          // ── Filters ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: _dropdown('Teacher', _filterTeacher, allTeachers,
                        (v) => setState(() => _filterTeacher = v!))),
                const SizedBox(width: 10),
                Expanded(child: _dropdown('Section', _filterSection, allSections,
                        (v) => setState(() => _filterSection = v!))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => setState(() {
                    _focusedMonth = _isMonthView
                        ? DateTime(_focusedMonth.year, _focusedMonth.month - 1)
                        : _focusedMonth.subtract(const Duration(days: 7));
                    _selectedDay = null;
                  }),
                ),
                Expanded(child: Center(child: Text(
                  _isMonthView
                      ? '${_mn(_focusedMonth.month)} ${_focusedMonth.year}'
                      : 'Week of ${_weekLabel()}',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.darkGray),
                ))),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => setState(() {
                    _focusedMonth = _isMonthView
                        ? DateTime(_focusedMonth.year, _focusedMonth.month + 1)
                        : _focusedMonth.add(const Duration(days: 7));
                    _selectedDay = null;
                  }),
                ),
              ]),
            ]),
          ),
          // ── Calendar ────────────────────────────────────────────────
          Expanded(
            child: _isMonthView
                ? _buildMonthView(filtered)
                : _buildWeekView(filtered),
          ),
          // ── Day detail panel ─────────────────────────────────────────
          if (_selectedDay != null)
            _DayDetailPanel(
              day: _selectedDay!,
              allEntries: filtered,
              onClose: () => setState(() => _selectedDay = null),
              onAdd: () {
                final isWide = MediaQuery.sizeOf(ctx).width > 600;
                if (isWide) {
                  setState(() { _showAddForm = true; _editingEntry = null; });
                } else {
                  _showMobileAddPanel(ctx, state, null);
                }
              },
              onEdit: (e) {
                final isWide = MediaQuery.sizeOf(ctx).width > 600;
                if (isWide) {
                  setState(() { _editingEntry = e; _showAddForm = true; });
                } else {
                  _showMobileAddPanel(ctx, state, e);
                }
              },
              onDelete: (e) { _confirmDelete(ctx, state, e); },
            ),
        ]),
      ));
    });
  }

  Widget _viewBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
          color: active ? AppColors.darkGray : Colors.white60)),
    ),
  );

  Widget _buildMonthView(List<ScheduleEntry> schedule) {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastOfMonth  = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    // ── Find Monday that starts the grid ────────────────────────────────────
    // If month starts on Sunday, jump to Monday (day 2) so Sunday is skipped.
    // Otherwise rewind to the Monday of that week.
    final gridStart = firstOfMonth.weekday == DateTime.sunday
        ? firstOfMonth.add(const Duration(days: 1))
        : firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));

    // ── Find Saturday that ends the grid ────────────────────────────────────
    final gridEnd = lastOfMonth.weekday == DateTime.saturday
        ? lastOfMonth
        : lastOfMonth.add(
        Duration(days: DateTime.saturday - lastOfMonth.weekday));

    // ── Build a flat list of Mon–Sat cells (Sundays are completely skipped) ─
    final cells = <DateTime>[];
    var cur = gridStart;
    while (!cur.isAfter(gridEnd)) {
      if (cur.weekday != DateTime.sunday) cells.add(cur);
      cur = cur.add(const Duration(days: 1));
    }

    final now = DateTime.now();

    return Column(children: [
      // Day headers
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: _dayAbbr.map((d) => Expanded(child: Center(
          child: Text(d, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightGray)),
        ))).toList()),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6, childAspectRatio: 0.9,
              mainAxisSpacing: 4, crossAxisSpacing: 4),
          itemCount: cells.length,
          itemBuilder: (_, idx) {
            final date = cells[idx];
            final inMonth = date.month == _focusedMonth.month;

            // Grey filler for days outside current month
            if (!inMonth) {
              return Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text('${date.day}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade200))),
              );
            }

            // _fullDays: Mon=0 … Sat=5 (weekday 1–6)
            final dayName   = _fullDays[date.weekday - 1];
            final dayEntries = schedule.where((e) => e.day == dayName).toList();
            final isSelected = _selectedDay != null &&
                _selectedDay!.day   == date.day &&
                _selectedDay!.month == date.month &&
                _selectedDay!.year  == date.year;
            final isToday = date.day   == now.day &&
                date.month == now.month &&
                date.year  == now.year;

            return GestureDetector(
              onTap: () => setState(
                      () => _selectedDay = isSelected ? null : date),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.darkGray
                      : isToday
                      ? AppColors.red.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.darkGray
                        : isToday
                        ? AppColors.red.withValues(alpha: 0.4)
                        : AppColors.borderGray,
                    width: isSelected || isToday ? 1.5 : 1,
                  ),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${date.day}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? AppColors.red
                                  : AppColors.darkGray)),
                      if (dayEntries.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.red,
                                shape: BoxShape.circle)),
                        Text('${dayEntries.length}',
                            style: GoogleFonts.inter(
                                fontSize: 9,
                                color: isSelected
                                    ? Colors.white60
                                    : AppColors.lightGray)),
                      ],
                    ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildWeekView(List<ScheduleEntry> schedule) {
    final monday = _focusedMonth.subtract(Duration(days: _focusedMonth.weekday - 1));
    final weekDays = List.generate(6, (i) => monday.add(Duration(days: i)));

    return ListView(padding: const EdgeInsets.all(10), children: weekDays.map((date) {
      if (date.weekday == 7) return const SizedBox();
      final dayName = _fullDays[date.weekday - 1];
      final dayEntries = schedule.where((e) => e.day == dayName).toList()
        ..sort((a, b) => a.timeStart.compareTo(b.timeStart));
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
      final isSelected = _selectedDay?.day == date.day && _selectedDay?.month == date.month;

      return GestureDetector(
        onTap: () => setState(() => _selectedDay = isSelected ? null : date),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.darkGray : isToday ? AppColors.red.withValues(alpha: 0.4) : AppColors.borderGray, width: isSelected ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkGray.withValues(alpha: 0.05) : isToday ? AppColors.red.withValues(alpha: 0.05) : AppColors.bgGray,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              ),
              child: Row(children: [
                Text('$dayName  ${date.day} ${_mn(date.month)}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.darkGray : isToday ? AppColors.red : AppColors.darkGray)),
                const Spacer(),
                Text('${dayEntries.length} class${dayEntries.length != 1 ? 'es' : ''}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              ]),
            ),
            if (dayEntries.isEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text('No classes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)))
            else
              ...dayEntries.map((e) => _entryRow(e)),
          ]),
        ),
      );
    }).toList());
  }

  Widget _entryRow(ScheduleEntry e) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
    child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text('${e.timeStart}–${e.timeEnd}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.subject.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        Text('${e.subject.code} · ${e.teacher.fullName} · ${e.room.name} · ${e.section}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
      ])),
      if (e.hasConflict) const Icon(Icons.warning_amber, color: AppColors.conflict, size: 16),
    ]),
  );

  Widget _dropdown(String hint, String value, List<String> items, void Function(String?) onChange) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.borderGray)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: value, isExpanded: true,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkGray),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChange,
        )),
      );

  void _confirmDelete(BuildContext ctx, AppState state, ScheduleEntry e) {
    showDialog(context: ctx, builder: (dCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text('Delete Schedule?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Text('Remove ${e.subject.code} – ${e.section} on ${e.day}?', style: GoogleFonts.inter(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.conflict),
          onPressed: () {
            // Close the panel first, then delete to avoid stale refs
            Navigator.pop(dCtx);
            setState(() => _selectedDay = null);
            // Small delay to let the panel close before state changes
            Future.microtask(() => state.deleteScheduleEntry(e.id));
          },
          child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    ));
  }

  List<String> _timeSlots() {
    final s = <String>[];
    for (int h = 7; h <= 20; h++) {
      s.add('${h.toString().padLeft(2,'0')}:00');
      s.add('${h.toString().padLeft(2,'0')}:30');
    }
    return s;
  }

  void _showMobileAddPanel(BuildContext context, AppState state, ScheduleEntry? editing) {
    // Capture the shared AppState before the dialog opens — see room_availability_screen
    // for the full explanation of why this ChangeNotifierProvider.value wrapper is needed.
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'schedule_form',
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
              child: Material(
                color: Colors.transparent,
                child: ChangeNotifierProvider<AppState>.value(
                  value: state,
                  child: Container(
                    width: MediaQuery.sizeOf(ctx).width * 0.92,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: _ScheduleFormPanel(
                      key: ValueKey(editing?.id ?? 'new'),
                      existingEntry: editing,
                      preselectedDay: _selectedDay != null && _selectedDay!.weekday <= 6
                          ? _fullDays[_selectedDay!.weekday - 1]
                          : 'Monday',
                      onSaved: (entry) {
                        if (editing == null) { state.addScheduleEntry(entry); }
                        else { state.updateScheduleEntry(entry); }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(editing == null ? 'Class added.' : 'Class updated.', style: GoogleFonts.inter()),
                          backgroundColor: AppColors.available,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ));
                      },
                      onCancel: () => Navigator.pop(ctx),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  String _mn(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
  String _weekLabel() {
    final monday = _focusedMonth.subtract(Duration(days: _focusedMonth.weekday - 1));
    final saturday = monday.add(const Duration(days: 5));
    return '${monday.day} ${_mn(monday.month)} – ${saturday.day} ${_mn(saturday.month)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day Detail Panel — shown at bottom when a calendar day is tapped
// ─────────────────────────────────────────────────────────────────────────────
class _DayDetailPanel extends StatelessWidget {
  final DateTime day;
  final List<ScheduleEntry> allEntries;
  final VoidCallback onClose, onAdd;
  final void Function(ScheduleEntry) onEdit, onDelete;

  static const _fullDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  static const _mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  const _DayDetailPanel({required this.day, required this.allEntries, required this.onClose, required this.onAdd, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dayName = day.weekday <= 6 ? _fullDays[day.weekday - 1] : 'Sunday';
    final entries = allEntries.where((e) => e.day == dayName).toList()
      ..sort((a, b) => a.timeStart.compareTo(b.timeStart));

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Column(children: [
        // Handle bar
        Center(child: Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 6), child: Row(children: [
          Text('$dayName, ${day.day} ${_mn[day.month]} ${day.year}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.lightGray), onPressed: onClose),
        ])),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text('No classes on $dayName', style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)))
              : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('${e.timeStart}\n${e.timeEnd}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red), textAlign: TextAlign.center),
                ),
                title: Text(e.subject.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                subtitle: Text('${e.subject.code} · ${e.teacher.fullName} · ${e.room.name} · ${e.section}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppColors.lightGray),
                  onSelected: (v) {
                    if (v == 'edit') onEdit(e);
                    if (v == 'delete') onDelete(e);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 16), const SizedBox(width: 8), Text('Edit', style: GoogleFonts.inter(fontSize: 13))])),
                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 16, color: AppColors.conflict), const SizedBox(width: 8), Text('Delete', style: GoogleFonts.inter(fontSize: 13, color: AppColors.conflict))])),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teacher Schedule Screen — read-only calendar view for teachers
// ─────────────────────────────────────────────────────────────────────────────
class TeacherScheduleViewScreen extends StatefulWidget {
  final Teacher teacher;
  const TeacherScheduleViewScreen({super.key, required this.teacher});
  @override State<TeacherScheduleViewScreen> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleViewScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _isMonthView = true;

  static const _fullDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  static const _dayAbbr = ['Mon','Tue','Wed','Thu','Fri','Sat'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final schedule = state.getTeacherSchedule(widget.teacher.id);

      return Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.teacher.fullName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(widget.teacher.department, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
          ]),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _vBtn('Month', _isMonthView, () => setState(() => _isMonthView = true)),
                _vBtn('Week', !_isMonthView, () => setState(() => _isMonthView = false)),
              ]),
            ),
          ],
        ),
        body: Column(children: [
          // Stats bar
          Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _stat('${schedule.length}', 'Classes', AppColors.red),
              const SizedBox(width: 16),
              _stat('${schedule.fold<int>(0, (s, e) => s + e.subject.units)}', 'Units', AppColors.available),
              const SizedBox(width: 16),
              _stat('${schedule.where((e) => e.hasConflict).length}', 'Conflicts',
                  schedule.any((e) => e.hasConflict) ? AppColors.conflict : AppColors.available),
              const Spacer(),
              // Navigator
              IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: () => setState(() {
                _focusedMonth = _isMonthView ? DateTime(_focusedMonth.year, _focusedMonth.month - 1) : _focusedMonth.subtract(const Duration(days: 7));
                _selectedDay = null;
              })),
              Text(_isMonthView ? '${_mn(_focusedMonth.month)} ${_focusedMonth.year}' : _weekL(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: () => setState(() {
                _focusedMonth = _isMonthView ? DateTime(_focusedMonth.year, _focusedMonth.month + 1) : _focusedMonth.add(const Duration(days: 7));
                _selectedDay = null;
              })),
            ]),
          ),
          Expanded(child: _isMonthView ? _monthGrid(schedule) : _weekList(schedule)),
          if (_selectedDay != null) _dayPanel(_selectedDay!, schedule),
        ]),
      );
    });
  }

  Widget _vBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppColors.darkGray : Colors.white60))),
  );

  Widget _stat(String val, String label, Color color) => Column(children: [
    Text(val, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
  ]);

  Widget _monthGrid(List<ScheduleEntry> schedule) {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final blanks = first.weekday - 1;

    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: _dayAbbr.map((d) => Expanded(child: Center(child: Text(d, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightGray))))).toList())),
      Expanded(child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, childAspectRatio: 0.9, mainAxisSpacing: 4, crossAxisSpacing: 4),
        itemCount: blanks + daysInMonth,
        itemBuilder: (_, idx) {
          if (idx < blanks) return const SizedBox();
          final day = idx - blanks + 1;
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          if (date.weekday == 7) { return Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Center(child: Text('$day', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade300)))); }
          final dayName = _fullDays[date.weekday - 1];
          final entries = schedule.where((e) => e.day == dayName).toList();
          final isSel = _selectedDay?.day == day && _selectedDay?.month == date.month;
          final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = isSel ? null : date),
            child: Container(
              decoration: BoxDecoration(
                color: isSel ? AppColors.red : isToday ? AppColors.red.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSel ? AppColors.red : isToday ? AppColors.red.withValues(alpha: 0.4) : AppColors.borderGray, width: isSel || isToday ? 1.5 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$day', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : isToday ? AppColors.red : AppColors.darkGray)),
                if (entries.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: isSel ? Colors.white : AppColors.red, shape: BoxShape.circle)),
                ],
              ]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _weekList(List<ScheduleEntry> schedule) {
    final monday = _focusedMonth.subtract(Duration(days: _focusedMonth.weekday - 1));
    final days = List.generate(6, (i) => monday.add(Duration(days: i)));
    return ListView(padding: const EdgeInsets.all(10), children: days.map((date) {
      if (date.weekday == 7) return const SizedBox();
      final dayName = _fullDays[date.weekday - 1];
      final entries = schedule.where((e) => e.day == dayName).toList()..sort((a, b) => a.timeStart.compareTo(b.timeStart));
      final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month;
      return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isToday ? AppColors.red.withValues(alpha: 0.4) : AppColors.borderGray)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: isToday ? AppColors.red.withValues(alpha: 0.05) : AppColors.bgGray, borderRadius: const BorderRadius.vertical(top: Radius.circular(9))),
              child: Row(children: [
                Text('$dayName  ${date.day} ${_mn(date.month)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: isToday ? AppColors.red : AppColors.darkGray)),
                const Spacer(),
                Text('${entries.length} class${entries.length != 1 ? 'es' : ''}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              ])),
          if (entries.isEmpty)
            Padding(padding: const EdgeInsets.all(12), child: Text('No classes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)))
          else
            ...entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${e.timeStart}–${e.timeEnd}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.subject.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                  Text('${e.subject.code} · ${e.room.name} · ${e.section}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                ])),
              ]),
            )),
        ]),
      );
    }).toList());
  }

  Widget _dayPanel(DateTime day, List<ScheduleEntry> schedule) {
    final dayName = day.weekday <= 6 ? _fullDays[day.weekday - 1] : 'Sunday';
    final entries = schedule.where((e) => e.day == dayName).toList()..sort((a, b) => a.timeStart.compareTo(b.timeStart));
    return Container(constraints: const BoxConstraints(maxHeight: 260), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3))]),
      child: Column(children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 8), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderGray, borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 6), child: Row(children: [
          Text('$dayName, ${day.day} ${_mn(day.month)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.lightGray), onPressed: () => setState(() => _selectedDay = null)),
        ])),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(child: entries.isEmpty
            ? Center(child: Text('No classes on $dayName', style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)))
            : ListView.separated(padding: EdgeInsets.zero, itemCount: entries.length, separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text('${e.timeStart}\n${e.timeEnd}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red), textAlign: TextAlign.center)),
                title: Text(e.subject.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                subtitle: Text('${e.subject.code} · ${e.room.name} · ${e.section}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              );
            })),
      ]),
    );
  }

  String _mn(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
  String _weekL() {
    final monday = _focusedMonth.subtract(Duration(days: _focusedMonth.weekday - 1));
    final saturday = monday.add(const Duration(days: 5));
    return '${monday.day} ${_mn(monday.month)} – ${saturday.day} ${_mn(saturday.month)}';
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// _ScheduleFormPanel — right-side add/edit panel for schedule entries
// ─────────────────────────────────────────────────────────────────────────────
class _ScheduleFormPanel extends StatefulWidget {
  final ScheduleEntry? existingEntry;
  final String preselectedDay;
  final void Function(ScheduleEntry) onSaved;
  final VoidCallback onCancel;

  const _ScheduleFormPanel({
    super.key,
    required this.existingEntry,
    required this.preselectedDay,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_ScheduleFormPanel> createState() => _ScheduleFormPanelState();
}

class _ScheduleFormPanelState extends State<_ScheduleFormPanel> {
  // Section is now a dropdown — selected from AppState.sections
  String? _selectedSection;

  static const _fullDays = ['Monday','Tuesday','Wednesday','Thursday','Friday'];

  // ── Persistent selections — survive AppState rebuilds ───────────────────
  Subject? _selectedSubject;
  Teacher? _selectedTeacher;
  Room? _selectedRoom;
  String? _selectedDay;
  String _timeStart = '07:30';
  String _timeEnd = '09:00';
  bool _initialized = false;
  // ✅ NEW: specific date picker
  DateTime? _specificDate;

  static const _monthNames = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.existingEntry?.section;
    _selectedDay = widget.existingEntry?.day ?? widget.preselectedDay;
    _timeStart   = widget.existingEntry?.timeStart ?? '07:30';
    _timeEnd     = widget.existingEntry?.timeEnd ?? '09:00';
  }

  /// Opens date picker and auto-sets the day-of-week from the chosen date.
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E1E1E),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      // Map weekday (1=Mon … 6=Sat, 7=Sun) to day name
      final dayNames = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
      if (picked.weekday <= 6) {
        setState(() {
          _specificDate = picked;
          _selectedDay = dayNames[picked.weekday - 1];
        });
      } else {
        // Sunday — warn and don't set
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sundays are not valid class days.', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
      }
    }
  }

  /// Initialise subject/teacher/room from state on first build only.
  void _initSelectionsIfNeeded(AppState state) {
    if (_initialized) return;
    _initialized = true;
    final existing = widget.existingEntry;
    _selectedSubject = existing?.subject ?? (state.subjects.isNotEmpty ? state.subjects.first : null);
    _selectedTeacher = existing?.teacher ?? (state.teachers.isNotEmpty ? state.teachers.first : null);
    _selectedRoom    = existing?.room    ?? (state.rooms.isNotEmpty    ? state.rooms.first    : null);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (_, state, __) {
      if (state.subjects.isEmpty || state.teachers.isEmpty || state.rooms.isEmpty) {
        return Container(
          color: const Color(0xFFF5F5F5),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.warning_amber_outlined, size: 48, color: AppColors.warning),
                const SizedBox(height: 16),
                Text('Add subjects, teachers, and rooms first.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightGray)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGray),
                  child: Text('Close', style: GoogleFonts.inter()),
                ),
              ]),
            ),
          ),
        );
      }

      // Initialise selections once; after that the user's choices are kept.
      _initSelectionsIfNeeded(state);

      // Guard: if a previously selected item was deleted, fall back to first.
      if (_selectedSubject == null || !state.subjects.any((s) => s.id == _selectedSubject!.id)) {
        _selectedSubject = state.subjects.first;
      }
      if (_selectedTeacher == null || !state.teachers.any((t) => t.id == _selectedTeacher!.id)) {
        _selectedTeacher = state.teachers.first;
      }
      if (_selectedRoom == null || !state.rooms.any((r) => r.id == _selectedRoom!.id)) {
        _selectedRoom = state.rooms.first;
      }

      final existing = widget.existingEntry;

      final timeSlots = <String>[];
      for (int h = 7; h <= 20; h++) {
        timeSlots.add('${h.toString().padLeft(2, '0')}:00');
        timeSlots.add('${h.toString().padLeft(2, '0')}:30');
      }

      return Container(
        color: const Color(0xFFF5F5F5),
        child: Column(children: [
          // ── Header ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(children: [
              Expanded(
                child: Text(existing == null ? 'Add Class Schedule' : 'Edit Schedule',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.lightGray),
                onPressed: widget.onCancel,
              ),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // ── Form ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (existing != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${existing.subject.code} – ${existing.subject.name} · ${existing.day}',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Subject (only for add)
                if (existing == null) ...[
                  _lbl('Subject'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    decoration: _dec(''),
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                    items: state.subjects.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('${s.code} – ${s.name}',
                          style: GoogleFonts.inter(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedSubject = v),
                  ),
                  const SizedBox(height: 14),
                ],

                // Teacher
                _lbl('Teacher'),
                const SizedBox(height: 8),
                DropdownButtonFormField<Teacher>(
                  value: _selectedTeacher,
                  decoration: _dec(''),
                  isExpanded: true,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                  items: state.teachers.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.fullName, style: GoogleFonts.inter(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedTeacher = v),
                ),
                const SizedBox(height: 14),

                // Room
                _lbl('Room'),
                const SizedBox(height: 8),
                DropdownButtonFormField<Room>(
                  value: _selectedRoom,
                  decoration: _dec(''),
                  isExpanded: true,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                  items: state.rooms.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text('${r.name} (${r.typeLabel})',
                        style: GoogleFonts.inter(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRoom = v),
                ),
                const SizedBox(height: 14),

                // ✅ NEW: Specific date picker (auto-sets day below)
                if (existing == null) ...[
                  _lbl('Specific Date (optional)'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _specificDate != null
                              ? AppColors.darkGray
                              : AppColors.borderGray,
                          width: _specificDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: _specificDate != null ? AppColors.darkGray : AppColors.lightGray,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _specificDate != null
                                ? '${_specificDate!.day} ${_monthNames[_specificDate!.month]} ${_specificDate!.year}'
                                : 'Pick a date to auto-select day',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _specificDate != null ? AppColors.darkGray : AppColors.lightGray,
                            ),
                          ),
                        ),
                        if (_specificDate != null)
                          GestureDetector(
                            onTap: () => setState(() => _specificDate = null),
                            child: const Icon(Icons.close, size: 16, color: AppColors.lightGray),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Day (only for add)
                if (existing == null) ...[
                  Row(children: [
                    _lbl('Day'),
                    if (_specificDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.available.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('auto-set from date',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.available)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _fullDays.map((d) {
                      final sel = (_selectedDay ?? widget.preselectedDay) == d;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDay = d;
                          _specificDate = null; // clear date if manually overriding
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.darkGray : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? AppColors.darkGray : AppColors.borderGray),
                          ),
                          child: Text(d.substring(0, 3),
                              style: GoogleFonts.inter(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppColors.lightGray)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Time
                _lbl('Time'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _timeStart,
                      decoration: _dec('Start'),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                      items: timeSlots.map((t) => DropdownMenuItem(
                          value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _timeStart = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _timeEnd,
                      decoration: _dec('End'),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                      items: timeSlots.map((t) => DropdownMenuItem(
                          value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() => _timeEnd = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // Section
                _lbl('Section'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: state.sections.contains(_selectedSection)
                      ? _selectedSection : null,
                  decoration: _dec('Select section'),
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E1E1E)),
                  isExpanded: true,
                  items: state.sections
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
                  ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSection = v),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // ── Actions ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkGray)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // ── Validate all required fields ──────────────────────
                    final schedMissing = <String>[];
                    if (_selectedSubject == null) schedMissing.add('Subject');
                    if (_selectedTeacher == null) schedMissing.add('Teacher');
                    if (_selectedRoom == null) schedMissing.add('Room');
                    if (_selectedSection == null || _selectedSection!.isEmpty) schedMissing.add('Section');
                    if (_selectedDay == null || _selectedDay!.isEmpty) schedMissing.add('Day');
                    if (schedMissing.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_busy_outlined, color: Color(0xFFC62828), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Incomplete Schedule',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700))),
                          ]),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Please complete all required fields:',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A4A4A))),
                              const SizedBox(height: 12),
                              ...schedMissing.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(f, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                                ]),
                              )),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    final entry = existing == null
                        ? ScheduleEntry(
                      id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
                      subject: _selectedSubject!,
                      teacher: _selectedTeacher!,
                      room: _selectedRoom!,
                      section: _selectedSection ?? 'TBA',
                      day: _selectedDay ?? widget.preselectedDay,
                      timeStart: _timeStart,
                      timeEnd: _timeEnd,
                      semester: '1st Semester', academicYear: '2024-2025',
                      hasConflict: false, createdAt: DateTime.now(),
                      specificDate: _specificDate,
                    )
                        : existing.copyWith(
                      teacher: _selectedTeacher,
                      room: _selectedRoom,
                      timeStart: _timeStart,
                      timeEnd: _timeEnd,
                      section: _selectedSection ?? existing.section,
                      updatedAt: DateTime.now(),
                    );
                    widget.onSaved(entry);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGray,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(existing == null ? 'Add' : 'Save Changes',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label.isEmpty ? null : label,
    hintText: label.isEmpty ? null : null,
    labelStyle: GoogleFonts.inter(color: AppColors.lightGray, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkGray, width: 1.5)),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    isDense: true,
  );

  Widget _lbl(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightGray));
}