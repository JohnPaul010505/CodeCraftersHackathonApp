import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../models/teacher.dart';
import '../models/schedule.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});
  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  String _search = '';
  Teacher? _selected;
  bool _showForm = false;
  Teacher? _editingTeacher;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final filtered = state.teachers
          .where((t) =>
      t.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          t.department.toLowerCase().contains(_search.toLowerCase()) ||
          t.employeeId.toLowerCase().contains(_search.toLowerCase()))
          .toList();

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 26),
              tooltip: 'Add Teacher',
              onPressed: () {
                final isWide = MediaQuery.sizeOf(context).width > 680;
                if (isWide) {
                  setState(() { _showForm = true; _editingTeacher = null; _selected = null; });
                } else {
                  _showMobileFormPanel(context, Provider.of<AppState>(context, listen: false), null);
                }
              },
            ),
          ],
        ),
        body: LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 680;

          final listPanel = Column(children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Faculty Members',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 2),
                Text('Total: ${state.teachers.length} teachers',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                  decoration: InputDecoration(
                    hintText: 'Search by name, dept, ID…',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray),
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.lightGray),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderGray)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.red, width: 1.5)),
                    filled: true,
                    fillColor: AppColors.bgGray,
                  ),
                ),
              ]),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // ── List ────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                  child: Text('No teachers found.',
                      style: GoogleFonts.inter(color: Colors.grey.shade500)))
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) => _TeacherTile(
                  teacher: filtered[i],
                  isSelected: isWide && _selected?.id == filtered[i].id,
                  onTap: () {
                    if (isWide) {
                      setState(() { _selected = filtered[i]; _showForm = false; _editingTeacher = null; });
                    } else {
                      _showBottomDetail(context, state, filtered[i]);
                    }
                  },
                  onEdit: () {
                    final isWide = MediaQuery.sizeOf(context).width > 680;
                    if (isWide) {
                      setState(() { _editingTeacher = filtered[i]; _showForm = true; _selected = null; });
                    } else {
                      _showMobileFormPanel(context, state, filtered[i]);
                    }
                  },
                  onDelete: () => _confirmDelete(context, state, filtered[i]),
                ),
              ),
            ),
          ]);

          if (isWide) {
            return Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(children: [
                      SizedBox(width: 340, child: listPanel),
                      Container(width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: _showForm
                            ? _TeacherFormPanel(
                          key: ValueKey(_editingTeacher?.id ?? 'new'),
                          existing: _editingTeacher,
                          state: state,
                          onSaved: (t) {
                            if (_editingTeacher == null) { state.addTeacher(t); }
                            else { state.updateTeacher(t); }
                            setState(() { _showForm = false; _editingTeacher = null; _selected = t; });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_editingTeacher == null ? '${t.fullName} added.' : '${t.fullName} updated.', style: GoogleFonts.inter()),
                              backgroundColor: AppColors.available,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ));
                          },
                          onCancel: () => setState(() { _showForm = false; _editingTeacher = null; }),
                        )
                            : _selected == null
                            ? _EmptyPanel()
                            : _DetailPanel(
                          teacher: _selected!,
                          onEdit: () => setState(() { _editingTeacher = _selected; _showForm = true; _selected = null; }),
                          onDelete: () {
                            _confirmDelete(context, state, _selected!);
                            setState(() => _selected = null);
                          },
                        ),
                      ),
                    ])));
          }
          return listPanel;
        }),
      );
    });
  }

  void _showMobileFormPanel(BuildContext context, AppState state, Teacher? editing) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'teacher_form',
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
                // Re-provide the same AppState singleton so that the dialog's
                // isolated context tree sees rooms/subjects added after the last
                // full rebuild — mirrors the fix in room_availability_screen.dart.
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
                    child: _TeacherFormPanel(
                      key: ValueKey(editing?.id ?? 'new'),
                      existing: editing,
                      state: state,
                      onSaved: (t) {
                        if (editing == null) { state.addTeacher(t); }
                        else { state.updateTeacher(t); }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(editing == null ? '${t.fullName} added.' : '${t.fullName} updated.', style: GoogleFonts.inter()),
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

  void _showBottomDetail(BuildContext context, AppState state, Teacher t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _DetailPanel(
            teacher: t,
            scrollController: ctrl,
            onEdit: () {
              Navigator.pop(context);
              setState(() { _editingTeacher = t; _showForm = true; _selected = null; });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete(context, state, t);
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AppState state, Teacher t) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Teacher', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete ${t.fullName}? '
                'This will NOT delete their Firebase account.',
            style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.conflict),
            onPressed: () {
              state.deleteTeacher(t.id);
              Navigator.pop(dCtx);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Empty right panel
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgGray,
    child: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkGray.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, size: 48, color: AppColors.lightGray),
        ),
        const SizedBox(height: 16),
        Text('Select a teacher',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightGray)),
        const SizedBox(height: 6),
        Text('Click any name to view details here',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Right-side detail panel
// ─────────────────────────────────────────────────────────────────────────────
class _DetailPanel extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ScrollController? scrollController;

  const _DetailPanel({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
    this.scrollController,
  });

  // ── Subject tile helper (extracted out of Builder) ──────────────────────────
  Widget _subjectTile({
    required String name,
    required String subtitle,
    required int units,
    required bool isLab,
  }) {
    final color = isLab ? AppColors.moderate : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isLab ? Icons.science_outlined : Icons.menu_book_outlined,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray)),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.lightGray)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.darkGray.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${units}u',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray)),
        ),
      ]),
    );
  }

  // ── Build assigned subjects section ─────────────────────────────────────────
  Widget _buildSubjectsSection(
      List<ScheduleEntry> entries, List<Subject> assignedSubjects) {
    final seenIds = <String>{};
    final scheduleSubjects =
    entries.where((e) => seenIds.add(e.subject.id)).toList();
    final directSubjects =
    assignedSubjects.where((s) => !seenIds.contains(s.id)).toList();

    if (scheduleSubjects.isEmpty && directSubjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.lightGray),
          const SizedBox(width: 10),
          Text('No subjects assigned yet.',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.lightGray)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...scheduleSubjects.map((e) => _subjectTile(
          name: e.subject.name,
          subtitle:
          '${e.subject.code} · ${e.section} · ${e.day} ${e.timeStart}–${e.timeEnd}',
          units: e.subject.units,
          isLab: e.subject.type == SubjectType.laboratory,
        )),
        ...directSubjects.map((s) => _subjectTile(
          name: s.name,
          subtitle: '${s.code} · ${s.yearLevel} · ${s.semester}',
          units: s.units,
          isLab: s.type == SubjectType.laboratory,
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (_, state, __) {
      final entries = state.scheduleEntries
          .where((e) => e.teacher.id == teacher.id)
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
      final liveUnits = entries.fold<int>(0, (s, e) => s + e.subject.units);
      final sectionSet = <String>{
        ...entries.map((e) => e.section),
        ...teacher.sections,
      };
      final liveSections = sectionSet.toList()..sort();
      final yearLevelSet = <String>{
        ...entries.map((e) => e.subject.yearLevel),
        ...teacher.yearLevels,
      };
      final liveYearLevels = yearLevelSet.toList()..sort();
      final isOver = liveUnits > teacher.maxUnits;

      return Container(
        color: AppColors.bgGray,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // ── Profile card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${teacher.firstName[0]}${teacher.lastName.isNotEmpty ? teacher.lastName[0] : ""}',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher.fullName,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(teacher.department,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(teacher.unitType,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ]),
                  ),
                  Column(children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white70, size: 20),
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade300, size: 20),
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ]),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('$liveUnits/${teacher.maxUnits}', 'Units',
                      isOver ? AppColors.conflict : AppColors.available),
                  const SizedBox(width: 8),
                  _stat('${liveSections.length}', 'Sections', Colors.white60),
                  const SizedBox(width: 8),
                  _stat('${entries.length}', 'Classes', Colors.white60),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Info ──────────────────────────────────────────────
            _card([
              _row(Icons.badge_outlined, 'Employee ID', teacher.employeeId),
              _row(Icons.email_outlined, 'Email', teacher.email),
              _row(Icons.work_outline, 'Unit Type', teacher.unitType),
              _row(
                Icons.circle,
                'Status',
                teacher.status == TeacherStatus.active
                    ? 'Active'
                    : teacher.status == TeacherStatus.onLeave
                    ? 'On Leave'
                    : 'Inactive',
                valueColor: teacher.status == TeacherStatus.active
                    ? AppColors.available
                    : teacher.status == TeacherStatus.onLeave
                    ? AppColors.warning
                    : AppColors.conflict,
              ),
              _row(Icons.schedule_outlined, 'Available Days',
                  teacher.availableDays
                      .map((d) => d.substring(0, 3))
                      .join(', ')),
            ]),
            const SizedBox(height: 14),

            // ── Expertise ─────────────────────────────────────────
            if (teacher.expertise.isNotEmpty) ...[
              _sectionLbl('Expertise'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: teacher.expertise
                    .map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.2)),
                  ),
                  child: Text(e,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],

            // ── Year Levels & Semester ─────────────────────────────
            if (liveYearLevels.isNotEmpty || teacher.semester.isNotEmpty) ...[
              _sectionLbl('Year Level & Semester'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ...liveYearLevels.map((y) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.darkGray.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.darkGray.withValues(alpha: 0.2)),
                  ),
                  child: Text(y,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGray)),
                )),
                if (teacher.semester.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.2)),
                    ),
                    child: Text(teacher.semester,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red)),
                  ),
              ]),
              const SizedBox(height: 14),
            ],

            // ── Sections ──────────────────────────────────────────
            if (liveSections.isNotEmpty) ...[
              _sectionLbl('Sections Handled'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: liveSections
                    .map((s) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Text(s,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.midGray)),
                ))
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],

            // ── Assigned Subjects ──────────────────────────────────
            _sectionLbl('Assigned Subjects'),
            const SizedBox(height: 8),
            _buildSubjectsSection(entries, teacher.assignedSubjects),
          ],
        ),
      );
    });
  }

  Widget _stat(String val, String lbl, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        Text(val,
            style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(lbl,
            style:
            GoogleFonts.inter(fontSize: 10, color: Colors.white54)),
      ]),
    ),
  );

  Widget _card(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderGray),
    ),
    child: Column(
      children: rows.asMap().entries.map((entry) => Column(children: [
        entry.value,
        if (entry.key < rows.length - 1)
          Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 16,
              endIndent: 16),
      ])).toList(),
    ),
  );

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.lightGray),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.lightGray))),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? AppColors.darkGray))),
        ]),
      );

  Widget _sectionLbl(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.darkGray));
}


// ─────────────────────────────────────────────────────────────────────────────
// Teacher list tile
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherTile extends StatelessWidget {
  final Teacher teacher;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherTile({
    required this.teacher,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? AppColors.darkGray.withValues(alpha: 0.04) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (isSelected)
            Container(
              width: 3, height: 42,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  color: AppColors.red, borderRadius: BorderRadius.circular(2)),
            ),
          // Avatar with initials
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.darkGray : AppColors.bgGray,
              shape: BoxShape.circle,
              border: isSelected ? null : Border.all(color: AppColors.borderGray),
            ),
            child: Center(
              child: Text(
                '${teacher.firstName[0]}${teacher.lastName.isNotEmpty ? teacher.lastName[0] : ""}',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.midGray),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(teacher.fullName,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            Text(teacher.department,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
            const SizedBox(height: 4),
            Consumer<AppState>(builder: (_, st, __) {
              final lu = st.scheduleEntries
                  .where((e) => e.teacher.id == teacher.id)
                  .fold<int>(0, (s, e) => s + e.subject.units);
              final over = lu > teacher.maxUnits;
              // Sections: merge from schedule + teacher profile
              final secCount = <String>{
                ...st.scheduleEntries.where((e) => e.teacher.id == teacher.id).map((e) => e.section),
                ...teacher.sections,
              }.length;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _badge('$lu/${teacher.maxUnits}u',
                      over ? AppColors.conflict : AppColors.available),
                  const SizedBox(width: 6),
                  _badge(_statusLbl(teacher.status), _statusColor(teacher.status)),
                ]),
                if (secCount > 0 || teacher.yearLevels.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    if (secCount > 0) ...[
                      const Icon(Icons.groups_outlined, size: 11, color: AppColors.lightGray),
                      const SizedBox(width: 3),
                      Text('$secCount section${secCount != 1 ? "s" : ""}',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
                      const SizedBox(width: 8),
                    ],
                    if (teacher.yearLevels.isNotEmpty) ...[
                      const Icon(Icons.school_outlined, size: 11, color: AppColors.lightGray),
                      const SizedBox(width: 3),
                      Text(teacher.yearLevels.join(', '),
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.lightGray)),
                    ],
                  ]),
                ],
              ]);
            }),
          ])),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.lightGray),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 16),
                    const SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.inter(fontSize: 13))
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 16, color: AppColors.conflict),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.conflict))
                  ])),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );

  Color _statusColor(TeacherStatus s) {
    switch (s) {
      case TeacherStatus.active: return AppColors.available;
      case TeacherStatus.inactive: return AppColors.lightGray;
      case TeacherStatus.onLeave: return AppColors.warning;
    }
  }

  String _statusLbl(TeacherStatus s) {
    switch (s) {
      case TeacherStatus.active: return 'Active';
      case TeacherStatus.inactive: return 'Inactive';
      case TeacherStatus.onLeave: return 'On Leave';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TeacherFormPanel — right-side slide-in add/edit form
// ─────────────────────────────────────────────────────────────────────────────
class _TeacherFormPanel extends StatefulWidget {
  final Teacher? existing;
  final AppState state;
  final void Function(Teacher) onSaved;
  final VoidCallback onCancel;

  const _TeacherFormPanel({
    super.key,
    required this.existing,
    required this.state,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_TeacherFormPanel> createState() => _TeacherFormPanelState();
}

class _TeacherFormPanelState extends State<_TeacherFormPanel> {
  late TextEditingController _name, _email, _emp, _dept, _exp, _units, _pass;
  late String _unitType;
  late TeacherStatus _status;
  late List<String> _days;
  String _yearLevel = '1st Year';
  String _semester = '1st Semester';
  final List<String> _sections = [];
  final List<String> _selectedSubjectIds = [];
  bool _saving = false;
  String? _err;

  static const _allDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
  static const _yearLevels = ['1st Year','2nd Year','3rd Year','4th Year'];
  static const _semesters = ['1st Semester','2nd Semester','Summer'];
  // Sections are loaded live from AppState so newly added sections appear here
  // automatically without any code change — see SectionsManagementScreen.

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name   = TextEditingController(text: e?.fullName ?? '');
    _email  = TextEditingController(text: e?.email ?? '');
    _emp    = TextEditingController(text: e?.employeeId ?? '');
    _dept   = TextEditingController(text: e?.department ?? '');
    _exp    = TextEditingController(text: e?.expertise.join(', ') ?? '');
    _units  = TextEditingController(text: '${e?.maxUnits ?? 21}');
    _pass   = TextEditingController();
    _unitType = e?.unitType ?? 'Regular';
    _status   = e?.status ?? TeacherStatus.active;
    _days     = List.from(e?.availableDays ?? ['Monday','Tuesday','Wednesday','Thursday','Friday']);
    // Pre-fill year level, semester, sections when editing
    if (e != null) {
      if (e.yearLevels.isNotEmpty) _yearLevel = e.yearLevels.first;
      if (e.semester.isNotEmpty)   _semester  = e.semester;
      if (e.sections.isNotEmpty)   _sections.addAll(e.sections);
      if (e.assignedSubjects.isNotEmpty) _selectedSubjectIds.addAll(e.assignedSubjects.map((s) => s.id));
    }
  }

  @override
  void dispose() {
    for (final c in [_name,_email,_emp,_dept,_exp,_units,_pass]) { c.dispose(); }
    super.dispose();
  }

  String _statusLbl(TeacherStatus s) {
    switch (s) {
      case TeacherStatus.active: return 'Active';
      case TeacherStatus.inactive: return 'Inactive';
      case TeacherStatus.onLeave: return 'On Leave';
    }
  }

  String _authErrMsg(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already has an account.';
      case 'invalid-email': return 'Invalid email.';
      case 'weak-password': return 'Password too weak (min 6 chars).';
      default: return 'Auth error: $code';
    }
  }


  List<String> _missingTeacherFields() {
    final m = <String>[];
    if (_name.text.trim().isEmpty) m.add('Full Name');
    if (_email.text.trim().isEmpty) m.add('Email Address');
    if (_dept.text.trim().isEmpty) m.add('Department');
    if (_emp.text.trim().isEmpty) m.add('Employee ID');
    if (_days.isEmpty) m.add('Available Days (select at least one)');
    return m;
  }

  void _showValidationError(List<String> missing) {
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
            child: const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Incomplete Form',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please fill in all required fields:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4A4A4A))),
            const SizedBox(height: 12),
            ...missing.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFC62828), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500))),
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
  }

  Future<void> _save() async {
    final missing = _missingTeacherFields();
    if (missing.isNotEmpty) {
      _showValidationError(missing);
      return;
    }
    setState(() { _saving = true; _err = null; });
    try {
      final parts = _name.text.trim().split(' ');
      final first = parts.isNotEmpty ? parts.first : _name.text.trim();
      final last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      String tid = widget.existing?.id ?? 't_${DateTime.now().millisecondsSinceEpoch}';
      final appState = Provider.of<AppState>(context, listen: false);

      // Calculate currentUnits from assigned subjects
      final assignedSubjects = appState.subjects
          .where((s) => _selectedSubjectIds.contains(s.id)).toList();
      final calculatedUnits = assignedSubjects.fold<int>(0, (acc, s) => acc + s.units);

      // Password to use
      final passwordToSave = _pass.text.trim().isEmpty
          ? (widget.existing?.password ?? 'teacher123')
          : _pass.text.trim();

      if (widget.existing == null) {
        // ── NEW TEACHER ────────────────────────────────────────────────────
        try {
          final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: passwordToSave,
          );
          tid = cred.user!.uid;
          await cred.user!.updateDisplayName('$first $last');
          await FirebaseFirestore.instance.collection('users').doc(tid).set({
            'uid': tid, 'email': _email.text.trim(), 'role': 'teacher',
            'firstName': first, 'lastName': last,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } on FirebaseAuthException catch (e) {
          // Firebase Auth failed — still save to Firestore directly so
          // the Firestore-based login (email+password check) still works.
          setState(() { _err = 'Firebase Auth skipped (${_authErrMsg(e.code)}). Teacher saved locally.'; });
        }

        // ── Save to Firestore teachers collection (always, even if Auth failed)
        await FirebaseFirestore.instance.collection('teachers').doc(tid).set({
          'uid': tid, 'firstName': first, 'lastName': last,
          'email': _email.text.trim(), 'employeeId': _emp.text.trim(),
          'department': _dept.text.trim(),
          'expertise': _exp.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'unitType': _unitType,
          'maxUnits': int.tryParse(_units.text) ?? 21,
          // ✅ FIX: save password so Firestore-based login works
          'password': passwordToSave,
          // ✅ FIX: save assignedSubjectIds so subjects show after restart
          'assignedSubjectIds': _selectedSubjectIds,
          // ✅ FIX: save calculated units instead of hardcoded 0
          'currentUnits': calculatedUnits,
          'status': 'active', 'availableDays': _days,
          'availableTimeStart': '07:00', 'availableTimeEnd': '18:00', 'role': 'teacher',
          'yearLevel': _yearLevel, 'yearLevels': [_yearLevel],
          'semester': _semester, 'sections': _sections,
          'createdAt': FieldValue.serverTimestamp(),
        });

      } else {
        // ── EDIT EXISTING TEACHER ──────────────────────────────────────────
        try {
          await FirebaseFirestore.instance.collection('teachers').doc(widget.existing!.id).update({
            'firstName': first, 'lastName': last,
            'email': _email.text.trim(), 'employeeId': _emp.text.trim(),
            'department': _dept.text.trim(),
            'expertise': _exp.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            'unitType': _unitType, 'maxUnits': int.tryParse(_units.text) ?? 21,
            'availableDays': _days,
            'yearLevel': _yearLevel, 'semester': _semester, 'sections': _sections,
            'yearLevels': [_yearLevel],
            // ✅ FIX: save assignedSubjectIds and updated units on edit too
            'assignedSubjectIds': _selectedSubjectIds,
            'currentUnits': calculatedUnits,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }

      // ── Build Teacher object ──────────────────────────────────────────────
      final t = Teacher(
        id: tid, firstName: first, lastName: last,
        email: _email.text.trim(), employeeId: _emp.text.trim(),
        department: _dept.text.trim(),
        expertise: _exp.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        unitType: _unitType, maxUnits: int.tryParse(_units.text) ?? 21,
        // ✅ FIX: use calculated units instead of 0
        currentUnits: calculatedUnits,
        status: _status, availableDays: _days,
        availableTimeStart: '07:00', availableTimeEnd: '18:00',
        assignedSubjects: assignedSubjects,
        password: passwordToSave,
        sections: List<String>.from(_sections),
        yearLevels: [_yearLevel],
        semester: _semester,
      );

      // ── Auto-create schedule entries for assigned subjects ────────────────
      // Each assigned subject gets a basic schedule entry so the teacher
      // can see their classes immediately on the dashboard.
      if (_selectedSubjectIds.isNotEmpty) {
        final timeSlots = [
          ['07:30', '09:00'], ['09:00', '10:30'], ['10:30', '12:00'],
          ['13:00', '14:30'], ['14:30', '16:00'], ['16:00', '17:30'],
        ];
        final availableDays = _days.isNotEmpty ? _days : ['Monday'];
        int slotIdx = 0;
        int dayIdx  = 0;

        for (final subject in assignedSubjects) {
          // Skip if a schedule entry already exists for this teacher+subject
          final alreadyScheduled = appState.scheduleEntries.any(
                (e) => e.teacher.id == tid && e.subject.id == subject.id,
          );
          if (alreadyScheduled) continue;

          // Find a compatible room
          final room = appState.rooms.firstWhere(
                (r) => subject.matchesRoom(r.type) && r.capacity >= subject.minRoomCapacity,
            orElse: () => appState.rooms.first,
          );

          final section = _sections.isNotEmpty ? _sections.first : 'TBA';
          final day     = availableDays[dayIdx % availableDays.length];
          final slot    = timeSlots[slotIdx % timeSlots.length];

          final entry = ScheduleEntry(
            id: 'auto_${tid}_${subject.id}_${DateTime.now().millisecondsSinceEpoch}',
            subject: subject,
            teacher: t,
            room: room,
            section: section,
            day: day,
            timeStart: slot[0],
            timeEnd: slot[1],
            semester: _semester,
            academicYear: '2024-2025',
            hasConflict: false,
            createdAt: DateTime.now(),
          );

          appState.addScheduleEntry(entry);

          // Advance to next slot/day to avoid stacking all subjects at same time
          slotIdx++;
          if (slotIdx % timeSlots.length == 0) dayIdx++;
        }
      }

      widget.onSaved(t);
    } catch (e) {
      setState(() { _err = 'Something went wrong: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(children: [
        // ── Header ─────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(children: [
            Expanded(
              child: Text(isNew ? 'Add New Teacher' : 'Edit Teacher',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.lightGray),
              onPressed: widget.onCancel,
            ),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        // ── Form ───────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_err != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.conflict.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.conflict.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.conflict, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_err!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.conflict))),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              _tf(_name, 'Full Name'),
              const SizedBox(height: 12),
              _tf(_dept, 'Department'),
              const SizedBox(height: 12),
              _tf(_email, 'Email Address', type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _tf(_emp, 'Employee ID'),
              const SizedBox(height: 12),
              _tf(_exp, 'Expertise (comma separated)', maxLines: 2),
              const SizedBox(height: 12),

              // Unit Type
              DropdownButtonFormField<String>(
                initialValue: _unitType,
                decoration: _dec('Unit Type'),
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                items: ['Regular','Part-time','Overload']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.inter(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _unitType = v!),
              ),
              const SizedBox(height: 12),
              _tf(_units, 'Max Units', type: TextInputType.number),
              const SizedBox(height: 12),

              // Status
              DropdownButtonFormField<TeacherStatus>(
                initialValue: _status,
                decoration: _dec('Status'),
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                items: TeacherStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(_statusLbl(s), style: GoogleFonts.inter(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),

              // Available Days
              _label('Available Days'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _allDays.map((d) {
                final sel = _days.contains(d);
                return GestureDetector(
                  onTap: () => setState(() => sel ? _days.remove(d) : _days.add(d)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.darkGray : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.darkGray : AppColors.borderGray),
                    ),
                    child: Text(d.substring(0, 3),
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.lightGray)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Year Level
              _label('Year Level Handled'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: _yearLevels.map((y) {
                final sel = _yearLevel == y;
                return GestureDetector(
                  onTap: () => setState(() => _yearLevel = y),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.darkGray : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.darkGray : AppColors.borderGray),
                    ),
                    child: Text(y,
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.lightGray)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Semester
              _label('Semester'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: _semesters.map((s) {
                final sel = _semester == s;
                return GestureDetector(
                  onTap: () => setState(() => _semester = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFCC0000) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? const Color(0xFFCC0000) : AppColors.borderGray),
                    ),
                    child: Text(s,
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : AppColors.lightGray)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Sections
              _label('Sections (select all that apply)'),
              const SizedBox(height: 8),
              Consumer<AppState>(builder: (ctx, liveState, _) {
                final allSections = liveState.sections;
                return Wrap(spacing: 6, runSpacing: 6, children: allSections.map((sec) {
                  final sel = _sections.contains(sec);
                  return GestureDetector(
                    onTap: () => setState(() => sel ? _sections.remove(sec) : _sections.add(sec)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFCC0000).withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? const Color(0xFFCC0000) : AppColors.borderGray,
                            width: sel ? 1.5 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (sel) ...[
                          const Icon(Icons.check, size: 11, color: Color(0xFFCC0000)),
                          const SizedBox(width: 4),
                        ],
                        Text(sec,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? const Color(0xFFCC0000) : AppColors.midGray)),
                      ]),
                    ),
                  );
                }).toList());
              }),
              const SizedBox(height: 16),


              // Assigned Subjects
              _label('Assigned Subjects (select all that apply)'),
              const SizedBox(height: 8),
              Consumer<AppState>(builder: (ctx, appState, _) {
                final allSubjects = appState.subjects;
                return Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allSubjects.map((subj) {
                    final sel = _selectedSubjectIds.contains(subj.id);
                    return GestureDetector(
                      onTap: () => setState(() =>
                      sel ? _selectedSubjectIds.remove(subj.id) : _selectedSubjectIds.add(subj.id)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFCC0000).withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? const Color(0xFFCC0000) : AppColors.borderGray,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (sel) ...[
                            const Icon(Icons.check, size: 11, color: Color(0xFFCC0000)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(child: Text(
                            '${subj.code} – ${subj.name}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? const Color(0xFFCC0000) : AppColors.midGray),
                            overflow: TextOverflow.ellipsis,
                          )),
                        ]),
                      ),
                    );
                  }).toList(),
                );
              }),
              const SizedBox(height: 16),
              // Password (new only)
              if (isNew) ...[
                _tf(_pass, 'Password (for login)', obscure: true),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.info_outline, size: 12, color: AppColors.lightGray),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Creates their Firebase login automatically.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray))),
                ]),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        // ── Action buttons ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : widget.onCancel,
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
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isNew ? 'Add Teacher' : 'Save Changes',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _tf(TextEditingController c, String label,
      {TextInputType type = TextInputType.text, int maxLines = 1, bool obscure = false}) =>
      TextField(
        controller: c, keyboardType: type, maxLines: maxLines, obscureText: obscure,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: _dec(label),
      );

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(color: AppColors.lightGray, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderGray)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.darkGray, width: 1.5)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  Widget _label(String t) => Text(t,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightGray));
}