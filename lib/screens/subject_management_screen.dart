import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/subject.dart';
import '../theme/app_theme.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});
  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  String _search = '';
  Subject? _selected;
  bool _showForm = false;
  Subject? _editingSubject;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final filtered = state.subjects
          .where((s) =>
      s.name.toLowerCase().contains(_search.toLowerCase()) ||
          s.code.toLowerCase().contains(_search.toLowerCase()) ||
          s.department.toLowerCase().contains(_search.toLowerCase()))
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
              tooltip: 'Add Subject',
              onPressed: () {
                final isWide = MediaQuery.sizeOf(context).width > 680;
                if (isWide) {
                  setState(() { _showForm = true; _editingSubject = null; _selected = null; });
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
                Text('Subjects',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
                const SizedBox(height: 2),
                Text('Total: ${state.subjects.length} subjects',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
                  decoration: InputDecoration(
                    hintText: 'Search by name, code, or department…',
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
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.book_outlined, size: 52, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                      _search.isEmpty ? 'No subjects yet' : 'No results for "$_search"',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.lightGray,
                          fontWeight: FontWeight.w500)),
                  if (_search.isEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Tap + to add a subject',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.lightGray)),
                  ],
                ]),
              )
                  : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) => _SubjectTile(
                  subject: filtered[i],
                  isSelected: isWide && _selected?.id == filtered[i].id,
                  onTap: () {
                    if (isWide) {
                      setState(() { _selected = filtered[i]; _showForm = false; _editingSubject = null; });
                    } else {
                      _showBottomDetail(context, state, filtered[i]);
                    }
                  },
                  onEdit: () {
                    final isWide = MediaQuery.sizeOf(context).width > 680;
                    if (isWide) {
                      setState(() { _editingSubject = filtered[i]; _showForm = true; _selected = null; });
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
                            ? _SubjectFormPanel(
                          key: ValueKey(_editingSubject?.id ?? 'new'),
                          existing: _editingSubject,
                          state: state,
                          onSaved: (s) {
                            if (_editingSubject == null) { state.addSubject(s); }
                            else { state.updateSubject(s); }
                            setState(() { _showForm = false; _editingSubject = null; _selected = s; });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_editingSubject == null ? '${s.code} added.' : '${s.code} updated.', style: GoogleFonts.inter()),
                              backgroundColor: AppColors.available,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ));
                          },
                          onCancel: () => setState(() { _showForm = false; _editingSubject = null; }),
                        )
                            : _selected == null
                            ? _EmptyPanel()
                            : _SubjectDetailPanel(
                          subject: _selected!,
                          onEdit: () => setState(() { _editingSubject = _selected; _showForm = true; _selected = null; }),
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

  void _showMobileFormPanel(BuildContext context, AppState state, Subject? editing) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'subject_form',
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
                // Re-provide the same AppState singleton into the dialog's
                // isolated context tree — mirrors fix in room_availability_screen.
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
                    child: _SubjectFormPanel(
                      key: ValueKey(editing?.id ?? 'new'),
                      existing: editing,
                      state: state,
                      onSaved: (s) {
                        if (editing == null) { state.addSubject(s); }
                        else { state.updateSubject(s); }
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(editing == null ? '${s.name} added.' : '${s.name} updated.', style: GoogleFonts.inter()),
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

  void _showBottomDetail(BuildContext context, AppState state, Subject s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _SubjectDetailPanel(
            subject: s,
            scrollController: ctrl,
            onEdit: () {
              Navigator.pop(context);
              setState(() { _editingSubject = s; _showForm = true; _selected = null; });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete(context, state, s);
            },
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, AppState state, Subject s) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Subject', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete ${s.code} – ${s.name}? '
            'This cannot be undone.',
            style: GoogleFonts.inter(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.conflict),
            onPressed: () {
              state.deleteSubject(s.id);
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text('${s.code} deleted.', style: GoogleFonts.inter()),
                backgroundColor: AppColors.conflict,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ));
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────
  void _showDialog(BuildContext context, AppState state, Subject? existing) {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final unitsCtrl = TextEditingController(text: '${existing?.units ?? 3}');
    final hoursCtrl = TextEditingController(text: '${existing?.hours ?? 3}');
    final capCtrl = TextEditingController(text: '${existing?.minRoomCapacity ?? 30}');
    final expCtrl = TextEditingController(text: existing?.requiredExpertise.join(', ') ?? '');

    SubjectType subjType = existing?.type ?? SubjectType.lecture;
    bool projector = existing?.requiresProjector ?? false;
    bool computers = existing?.requiresComputers ?? false;
    String yearLevel = existing?.yearLevel ?? '1st Year';
    String semester = existing?.semester ?? '1st Semester';
    final List<String> selSections = List<String>.from(existing?.sections ?? []);

    const yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
    const semesters = ['1st Semester', '2nd Semester', 'Summer'];
    final allSections = state.sections;

    bool saving = false;
    String? err;

    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(builder: (_, ss) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: Text(existing == null ? 'Add New Subject' : 'Edit Subject',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (err != null) ...[
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
                      Expanded(child: Text(err!,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.conflict))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Code + Units
                Row(children: [
                  Expanded(child: _field(codeCtrl, 'Subject Code', hint: 'e.g. CS101')),
                  const SizedBox(width: 10),
                  Expanded(child: _field(unitsCtrl, 'Units', type: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                _field(nameCtrl, 'Subject Name'),
                const SizedBox(height: 12),
                _field(descCtrl, 'Description', maxLines: 2),
                const SizedBox(height: 12),
                _field(deptCtrl, 'Department'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(hoursCtrl, 'Hours/Week', type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _field(capCtrl, 'Min Room Capacity', type: TextInputType.number)),
                ]),
                const SizedBox(height: 16),

                // ── Year Level ──────────────────────────────────────
                _chipLabel('Year Level'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: yearLevels.map((y) {
                    final sel = yearLevel == y;
                    return GestureDetector(
                      onTap: () => ss(() => yearLevel = y),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.darkGray : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? AppColors.darkGray : AppColors.borderGray),
                        ),
                        child: Text(y,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.lightGray)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Semester ────────────────────────────────────────
                _chipLabel('Semester'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: semesters.map((sem) {
                    final sel = semester == sem;
                    return GestureDetector(
                      onTap: () => ss(() => semester = sem),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.red : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.red : AppColors.borderGray),
                        ),
                        child: Text(sem,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.lightGray)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Sections ────────────────────────────────────────
                _chipLabel('Sections (select all that apply)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: allSections.map((sec) {
                    final sel = selSections.contains(sec);
                    return GestureDetector(
                      onTap: () => ss(() =>
                      sel ? selSections.remove(sec) : selSections.add(sec)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.red.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel ? AppColors.red : AppColors.borderGray,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (sel) ...[
                            const Icon(Icons.check, size: 11, color: AppColors.red),
                            const SizedBox(width: 4),
                          ],
                          Text(sec,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                  color: sel ? AppColors.red : AppColors.midGray)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Required Expertise ──────────────────────────────
                _field(expCtrl, 'Required Expertise (comma-separated)',
                    hint: 'e.g. Programming, Database'),
                const SizedBox(height: 16),

                // ── Subject Type ────────────────────────────────────
                _chipLabel('Subject Type'),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ss(() => subjType = SubjectType.lecture),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: subjType == SubjectType.lecture
                              ? AppColors.darkGray : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: subjType == SubjectType.lecture
                                  ? AppColors.darkGray : AppColors.borderGray),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.menu_book_outlined, size: 16,
                              color: subjType == SubjectType.lecture
                                  ? Colors.white : AppColors.lightGray),
                          const SizedBox(width: 6),
                          Text('Lecture',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: subjType == SubjectType.lecture
                                      ? Colors.white : AppColors.lightGray)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ss(() => subjType = SubjectType.laboratory),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: subjType == SubjectType.laboratory
                              ? AppColors.darkGray : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: subjType == SubjectType.laboratory
                                  ? AppColors.darkGray : AppColors.borderGray),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.science_outlined, size: 16,
                              color: subjType == SubjectType.laboratory
                                  ? Colors.white : AppColors.lightGray),
                          const SizedBox(width: 6),
                          Text('Lab',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: subjType == SubjectType.laboratory
                                      ? Colors.white : AppColors.lightGray)),
                        ]),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Room Requirements ───────────────────────────────
                _chipLabel('Room Requirements'),
                CheckboxListTile(
                  title: Text('Requires Projector', style: GoogleFonts.inter(fontSize: 13)),
                  value: projector,
                  onChanged: (v) => ss(() => projector = v!),
                  activeColor: AppColors.red,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text('Requires Computers', style: GoogleFonts.inter(fontSize: 13)),
                  value: computers,
                  onChanged: (v) => ss(() => computers = v!),
                  activeColor: AppColors.red,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(dCtx),
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
                  onPressed: saving
                      ? null
                      : () {
                    final missingSubj = <String>[];
                    if (codeCtrl.text.trim().isEmpty) missingSubj.add('Subject Code');
                    if (nameCtrl.text.trim().isEmpty) missingSubj.add('Subject Name');
                    if (deptCtrl.text.trim().isEmpty) missingSubj.add('Department');
                    if (missingSubj.isNotEmpty) {
                      ss(() => err = 'Required: ${missingSubj.join(', ')}');
                      return;
                    }
                    ss(() => saving = true);

                    final subject = Subject(
                      id: existing?.id ??
                          's_${DateTime.now().millisecondsSinceEpoch}',
                      code: codeCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      units: int.tryParse(unitsCtrl.text) ?? 3,
                      hours: int.tryParse(hoursCtrl.text) ?? 3,
                      type: subjType,
                      department: deptCtrl.text.trim(),
                      requiredExpertise: expCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      requiresProjector: projector,
                      requiresComputers: computers,
                      minRoomCapacity: int.tryParse(capCtrl.text) ?? 30,
                      yearLevel: yearLevel,
                      semester: semester,
                      sections: List<String>.from(selSections),
                    );

                    if (existing == null) {
                      state.addSubject(subject);
                    } else {
                      state.updateSubject(subject);
                      if (_selected?.id == subject.id) {
                        setState(() => _selected = subject);
                      }
                    }

                    Navigator.pop(dCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          existing == null
                              ? '${subject.code} added.'
                              : '${subject.code} updated.',
                          style: GoogleFonts.inter()),
                      backgroundColor: AppColors.available,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGray,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: saving
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(existing == null ? 'Add Subject' : 'Save Changes',
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ],
        );
      }),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType type = TextInputType.text, String? hint, int maxLines = 1}) {
    return TextField(
      controller: c, keyboardType: type, maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _chipLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightGray)),
  );
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
          child: const Icon(Icons.book_outlined, size: 48, color: AppColors.lightGray),
        ),
        const SizedBox(height: 16),
        Text('Select a subject',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.lightGray)),
        const SizedBox(height: 6),
        Text('Click any subject to view details here',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject detail panel
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectDetailPanel extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ScrollController? scrollController;

  const _SubjectDetailPanel({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isLab = subject.type == SubjectType.laboratory;
    final subjColor = isLab ? AppColors.moderate : AppColors.red;

    return Consumer<AppState>(builder: (_, state, __) {
      final entries = state.scheduleEntries
          .where((e) => e.subject.id == subject.id)
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));

      return Container(
        color: AppColors.bgGray,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // ── Subject header card ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        isLab ? Icons.science_outlined : Icons.menu_book_outlined,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(subject.code,
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(subject.name,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                  ])),
                  Column(children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
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
                const SizedBox(height: 14),
                Row(children: [
                  _badge(subject.typeLabel, subjColor),
                  const SizedBox(width: 8),
                  _badge('${subject.units} units', Colors.white60),
                  const SizedBox(width: 8),
                  _badge('${subject.hours} hrs/wk', Colors.white60),
                ]),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Info card ─────────────────────────────────────────────
            _card([
              _row(Icons.domain_outlined, 'Department', subject.department),
              _row(Icons.school_outlined, 'Year Level', subject.yearLevel),
              _row(Icons.calendar_today_outlined, 'Semester', subject.semester),
              _row(Icons.people_outline, 'Min Capacity',
                  '${subject.minRoomCapacity} students'),
              if (subject.requiresProjector)
                _row(Icons.videocam_outlined, 'Requires', 'Projector'),
              if (subject.requiresComputers)
                _row(Icons.computer_outlined, 'Requires', 'Computers'),
            ]),
            const SizedBox(height: 14),

            // ── Expertise ─────────────────────────────────────────────
            if (subject.requiredExpertise.isNotEmpty) ...[
              _sectionLbl('Required Expertise'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: subject.requiredExpertise.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: subjColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: subjColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(e,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: subjColor, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // ── Sections ────────────────────────────────────────────────
            if (subject.sections.isNotEmpty) ...[
              _sectionLbl('Sections'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: subject.sections.map((sec) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Text(sec,
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: AppColors.midGray)),
                )).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // ── Scheduled classes ─────────────────────────────────────
            _sectionLbl('Scheduled Classes'),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.lightGray),
                  const SizedBox(width: 10),
                  Text('Not yet scheduled.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
                ]),
              )
            else
              ...entries.map((e) => Container(
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
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month_outlined,
                        size: 16, color: AppColors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.day}  ${e.timeStart}–${e.timeEnd}',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.darkGray)),
                        Text(
                            '${e.teacher.fullName} · ${e.section} · Room ${e.room.name}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.lightGray)),
                      ])),
                ]),
              )),
            const SizedBox(height: 20),
          ],
        ),
      );
    });
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: color == Colors.white60 ? 0.15 : 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
          Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
      ])).toList(),
    ),
  );

  Widget _row(IconData icon, String label, String value) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(children: [
          Icon(icon, size: 15, color: AppColors.lightGray),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray))),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkGray)),
        ]),
      );

  Widget _sectionLbl(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray));
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject list tile
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectTile({
    required this.subject,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLab = subject.type == SubjectType.laboratory;
    final typeColor = isLab ? AppColors.moderate : AppColors.red;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? AppColors.darkGray.withValues(alpha: 0.04) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isSelected)
            Container(
              width: 3, height: 44,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  color: AppColors.red, borderRadius: BorderRadius.circular(2)),
            ),
          // Icon badge
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                isLab ? Icons.science_outlined : Icons.menu_book_outlined,
                color: typeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(subject.code,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(subject.typeLabel,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(subject.name,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.darkGray)),
              const SizedBox(height: 4),
              Text(
                  '${subject.department} · ${subject.units}u · ${subject.yearLevel}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
            ]),
          ),
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
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.conflict))
                  ])),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectFormPanel — right-side add/edit panel
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectFormPanel extends StatefulWidget {
  final Subject? existing;
  final AppState state;
  final void Function(Subject) onSaved;
  final VoidCallback onCancel;

  const _SubjectFormPanel({
    super.key,
    required this.existing,
    required this.state,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_SubjectFormPanel> createState() => _SubjectFormPanelState();
}

class _SubjectFormPanelState extends State<_SubjectFormPanel> {
  late TextEditingController _code, _name, _desc, _dept, _units, _hours, _cap, _exp;
  late SubjectType _type;
  late bool _projector, _computers;
  String _yearLevel = '1st Year';
  String _semester = '1st Semester';
  final List<String> _sections = [];
  String? _err;

  static const _yearLevels = ['1st Year','2nd Year','3rd Year','4th Year'];
  static const _semesters  = ['1st Semester','2nd Semester','Summer'];
  // Sections loaded live from AppState — see SectionsManagementScreen.

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code      = TextEditingController(text: e?.code ?? '');
    _name      = TextEditingController(text: e?.name ?? '');
    _desc      = TextEditingController(text: e?.description ?? '');
    _dept      = TextEditingController(text: e?.department ?? '');
    _units     = TextEditingController(text: '${e?.units ?? 3}');
    _hours     = TextEditingController(text: '${e?.hours ?? 3}');
    _cap       = TextEditingController(text: '${e?.minRoomCapacity ?? 30}');
    _exp       = TextEditingController(text: e?.requiredExpertise.join(', ') ?? '');
    _type      = e?.type ?? SubjectType.lecture;
    _projector = e?.requiresProjector ?? false;
    _computers = e?.requiresComputers ?? false;
    _yearLevel = e?.yearLevel ?? '1st Year';
    _semester  = e?.semester ?? '1st Semester';
    if (e != null && e.sections.isNotEmpty) _sections.addAll(e.sections);
  }

  @override
  void dispose() {
    for (final c in [_code,_name,_desc,_dept,_units,_hours,_cap,_exp]) { c.dispose(); }
    super.dispose();
  }

  void _save() {
    if (_code.text.trim().isEmpty || _name.text.trim().isEmpty) {
      setState(() => _err = 'Subject code and name are required.');
      return;
    }
    final s = Subject(
      id: widget.existing?.id ?? 's_${DateTime.now().millisecondsSinceEpoch}',
      code: _code.text.trim(),
      name: _name.text.trim(),
      description: _desc.text.trim(),
      units: int.tryParse(_units.text) ?? 3,
      hours: int.tryParse(_hours.text) ?? 3,
      type: _type,
      department: _dept.text.trim(),
      requiredExpertise: _exp.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      requiresProjector: _projector,
      requiresComputers: _computers,
      minRoomCapacity: int.tryParse(_cap.text) ?? 30,
      yearLevel: _yearLevel,
      semester: _semester,
      sections: List<String>.from(_sections),
    );
    widget.onSaved(s);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(children: [
        // ── Header ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Row(children: [
            Expanded(child: Text(isNew ? 'Add New Subject' : 'Edit Subject',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
            IconButton(icon: const Icon(Icons.close, color: AppColors.lightGray), onPressed: widget.onCancel),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        // ── Form ──────────────────────────────────────────────────
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
              Row(children: [
                Expanded(child: _tf(_code, 'Subject Code', hint: 'e.g. CS101')),
                const SizedBox(width: 10),
                Expanded(child: _tf(_units, 'Units', type: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              _tf(_name, 'Subject Name'),
              const SizedBox(height: 12),
              _tf(_desc, 'Description', maxLines: 2),
              const SizedBox(height: 12),
              _tf(_dept, 'Department'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _tf(_hours, 'Hours/Week', type: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(child: _tf(_cap, 'Min Room Capacity', type: TextInputType.number)),
              ]),
              const SizedBox(height: 16),

              // Year Level
              _lbl('Year Level'),
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
                    child: Text(y, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.lightGray)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Semester
              _lbl('Semester'),
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
                    child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.lightGray)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),

              // Sections
              _lbl('Sections (select all that apply)'),
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
                        border: Border.all(color: sel ? const Color(0xFFCC0000) : AppColors.borderGray, width: sel ? 1.5 : 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (sel) ...[const Icon(Icons.check, size: 11, color: Color(0xFFCC0000)), const SizedBox(width: 4)],
                        Text(sec, style: GoogleFonts.inter(fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? const Color(0xFFCC0000) : AppColors.midGray)),
                      ]),
                    ),
                  );
                }).toList());
              }),
              const SizedBox(height: 16),

              // Required Expertise
              _tf(_exp, 'Required Expertise (comma-separated)', hint: 'e.g. Programming, Database'),
              const SizedBox(height: 16),

              // Subject Type
              _lbl('Subject Type'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _typeBtn('Lecture', Icons.menu_book_outlined, _type == SubjectType.lecture, () => setState(() => _type = SubjectType.lecture))),
                const SizedBox(width: 10),
                Expanded(child: _typeBtn('Lab', Icons.science_outlined, _type == SubjectType.laboratory, () => setState(() => _type = SubjectType.laboratory))),
              ]),
              const SizedBox(height: 14),

              // Room Requirements
              _lbl('Room Requirements'),
              CheckboxListTile(
                title: Text('Requires Projector', style: GoogleFonts.inter(fontSize: 13)),
                value: _projector, onChanged: (v) => setState(() => _projector = v!),
                activeColor: const Color(0xFFCC0000),
                contentPadding: EdgeInsets.zero, dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: Text('Requires Computers', style: GoogleFonts.inter(fontSize: 13)),
                value: _computers, onChanged: (v) => setState(() => _computers = v!),
                activeColor: const Color(0xFFCC0000),
                contentPadding: EdgeInsets.zero, dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // ── Action buttons ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFCCCCCC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkGray)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGray,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(isNew ? 'Add Subject' : 'Save Changes',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _typeBtn(String label, IconData icon, bool sel, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.darkGray : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? AppColors.darkGray : AppColors.borderGray),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: sel ? Colors.white : AppColors.lightGray),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.lightGray)),
          ]),
        ),
      );

  Widget _tf(TextEditingController c, String label,
      {TextInputType type = TextInputType.text, String? hint, int maxLines = 1}) =>
      TextField(
        controller: c, keyboardType: type, maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: GoogleFonts.inter(color: AppColors.lightGray, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderGray)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.darkGray, width: 1.5)),
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      );

  Widget _lbl(String t) => Text(t, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightGray));
}