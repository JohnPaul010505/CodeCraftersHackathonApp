// lib/screens/sections_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SectionsManagementScreen
// Lets the admin add, rename, and delete sections.
// Any section added here automatically appears in the Teacher form and Subject
// form because both read live from AppState.sections.
// ─────────────────────────────────────────────────────────────────────────────
class SectionsManagementScreen extends StatefulWidget {
  const SectionsManagementScreen({super.key});
  @override
  State<SectionsManagementScreen> createState() =>
      _SectionsManagementScreenState();
}

class _SectionsManagementScreenState extends State<SectionsManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Side-panel state (wide screens)
  bool _showForm = false;
  String? _editingSection; // null = adding new

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final filtered = state.sections
          .where((s) => s.toLowerCase().contains(_query.toLowerCase()))
          .toList();

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('Sections',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  final isWide = MediaQuery.sizeOf(ctx).width > 700;
                  if (isWide) {
                    setState(() {
                      _showForm = true;
                      _editingSection = null;
                    });
                  } else {
                    _showMobilePanel(ctx, state, null);
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text('Add Section',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.red,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide && _showForm) {
            return Row(children: [
              Expanded(
                  child: _listPanel(ctx, state, filtered, isWide: isWide)),
              Container(width: 1, color: AppColors.borderGray),
              SizedBox(
                width: 420,
                child: _SectionFormPanel(
                  key: ValueKey(_editingSection ?? '__new__'),
                  existingName: _editingSection,
                  allSections: state.sections,
                  onSaved: (name) {
                    if (_editingSection == null) {
                      state.addSection(name);
                    } else {
                      state.updateSection(_editingSection!, name);
                    }
                    setState(() {
                      _showForm = false;
                      _editingSection = null;
                    });
                    _snack(ctx,
                        _editingSection == null
                            ? 'Section "$name" added.'
                            : 'Section updated to "$name".',
                        AppColors.available);
                  },
                  onCancel: () =>
                      setState(() {
                        _showForm = false;
                        _editingSection = null;
                      }),
                ),
              ),
            ]);
          }

          return _listPanel(ctx, state, filtered, isWide: isWide);
        }),
      );
    });
  }

  // ── Main list panel ─────────────────────────────────────────────────────────
  Widget _listPanel(BuildContext ctx, AppState state, List<String> filtered,
      {required bool isWide}) {
    return Column(children: [
      // ── Header stats ───────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          _statPill(Icons.grid_view_outlined,
              '${state.sections.length} sections', AppColors.darkGray),
          const SizedBox(width: 8),
          _statPill(Icons.school_outlined,
              '${_courseCount(state.sections, 'BSCS')} BSCS', AppColors.red),
          const SizedBox(width: 8),
          _statPill(Icons.computer_outlined,
              '${_courseCount(state.sections, 'BSIT')} BSIT',
              AppColors.midGray),
        ]),
      ),
      // ── Search ─────────────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search sections…',
            hintStyle:
            GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray),
            prefixIcon:
            const Icon(Icons.search, size: 18, color: AppColors.lightGray),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                icon: const Icon(Icons.clear,
                    size: 16, color: AppColors.lightGray),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                })
                : null,
            isDense: true,
            filled: true,
            fillColor: AppColors.bgGray,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      const Divider(height: 1, color: AppColors.borderGray),

      // ── Section grid / list ────────────────────────────────────────────────
      Expanded(
        child: filtered.isEmpty
            ? _emptyState()
            : Center(
          child: ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: isWide ? 860 : double.infinity),
            child: isWide
                ? _grid(ctx, state, filtered)
                : _mobileList(ctx, state, filtered),
          ),
        ),
      ),
    ]);
  }

  // Wide grid view
  Widget _grid(BuildContext ctx, AppState state, List<String> sections) {
    // Group by course prefix (BSCS, BSIT, etc.)
    final groups = <String, List<String>>{};
    for (final s in sections) {
      final prefix = s.split(' ').take(1).join();
      groups.putIfAbsent(prefix, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.entries.map((entry) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Group header
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Row(children: [
              Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(entry.key,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(width: 8),
              Text('${entry.value.length} sections',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.lightGray)),
            ]),
          ),
          // Section chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: entry.value
                .map((sec) => _SectionChip(
              section: sec,
              onEdit: () {
                setState(() {
                  _editingSection = sec;
                  _showForm = true;
                });
              },
              onDelete: () => _confirmDelete(ctx, state, sec),
            ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ]);
      }).toList(),
    );
  }

  // Mobile list view
  Widget _mobileList(
      BuildContext ctx, AppState state, List<String> sections) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final sec = sections[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  sec.split(' ').last, // e.g. "1-A"
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.red),
                ),
              ),
            ),
            title:
            Text(sec, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text(_courseLabel(sec),
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.lightGray)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.lightGray),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              onSelected: (v) {
                if (v == 'edit') _showMobilePanel(ctx, state, sec);
                if (v == 'delete') _confirmDelete(ctx, state, sec);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'edit',
                    child: _popItem(Icons.edit_outlined, 'Rename', AppColors.darkGray)),
                PopupMenuItem(
                    value: 'delete',
                    child: _popItem(
                        Icons.delete_outline, 'Delete', AppColors.conflict)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Mobile slide-in panel ──────────────────────────────────────────────────
  void _showMobilePanel(
      BuildContext context, AppState state, String? existing) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'section_form',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final slide =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
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
                    child: _SectionFormPanel(
                      key: ValueKey(existing ?? '__new__'),
                      existingName: existing,
                      allSections: state.sections,
                      onSaved: (name) {
                        if (existing == null) {
                          state.addSection(name);
                        } else {
                          state.updateSection(existing, name);
                        }
                        Navigator.pop(ctx);
                        _snack(
                            context,
                            existing == null
                                ? 'Section "$name" added.'
                                : 'Section updated to "$name".',
                            AppColors.available);
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

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDelete(BuildContext ctx, AppState state, String section) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.delete_outline, color: AppColors.conflict, size: 20),
          const SizedBox(width: 10),
          Text('Delete Section',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
            'Remove "$section"? This will not affect existing schedule entries.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.midGray)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () {
              state.deleteSection(section);
              Navigator.pop(dCtx);
              _snack(ctx, 'Section "$section" removed.', AppColors.conflict);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.conflict),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _emptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.grid_view_outlined,
          size: 52, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(
          _query.isNotEmpty
              ? 'No sections match "$_query"'
              : 'No sections yet. Tap + Add Section.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.lightGray),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _statPill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 5),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    ]),
  );

  Widget _popItem(IconData icon, String label, Color color) =>
      Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: color)),
      ]);

  int _courseCount(List<String> sections, String prefix) =>
      sections.where((s) => s.startsWith(prefix)).length;

  String _courseLabel(String sec) {
    if (sec.startsWith('BSCS')) return 'Bachelor of Science in Computer Science';
    if (sec.startsWith('BSIT')) return 'Bachelor of Science in Information Technology';
    return 'General';
  }

  void _snack(BuildContext ctx, String msg, Color color) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section chip (wide grid view)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionChip extends StatelessWidget {
  final String section;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SectionChip({
    required this.section,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                section.split(' ').last,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(section,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray)),
            Text(section.split(' ').first,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.lightGray)),
          ]),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 16, color: AppColors.lightGray),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined,
                        size: 15, color: AppColors.darkGray),
                    const SizedBox(width: 8),
                    Text('Rename',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.darkGray)),
                  ])),
              PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline,
                        size: 15, color: AppColors.conflict),
                    const SizedBox(width: 8),
                    Text('Delete',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.conflict)),
                  ])),
            ],
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section form panel (add / rename)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionFormPanel extends StatefulWidget {
  final String? existingName;
  final List<String> allSections;
  final void Function(String name) onSaved;
  final VoidCallback onCancel;

  const _SectionFormPanel({
    super.key,
    required this.existingName,
    required this.allSections,
    required this.onSaved,
    required this.onCancel,
  });

  @override
  State<_SectionFormPanel> createState() => _SectionFormPanelState();
}

class _SectionFormPanelState extends State<_SectionFormPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl;
  bool _saving = false;

  // Quick-fill presets for common naming patterns
  static const _courseOptions = ['BSCS', 'BSIT', 'BSED', 'BSA', 'BSBA'];
  static const _yearOptions = ['1', '2', '3', '4'];
  static const _sectionLetters = ['A', 'B', 'C', 'D', 'E'];

  String _course = 'BSCS';
  String _year = '1';
  String _letter = 'A';

  @override
  void initState() {
    super.initState();
    _ctrl =
        TextEditingController(text: widget.existingName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _applyPreset() {
    _ctrl.text = '$_course $_year-$_letter';
    setState(() {});
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    widget.onSaved(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingName != null;
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: Text(isEdit ? 'Rename Section' : 'Add New Section',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Quick-fill builder ─────────────────────────────────────────
            if (!isEdit) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: kCardDecoration(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Fill',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightGray,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 12),

                      // Course row
                      Text('Course',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.midGray)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _courseOptions.map((c) {
                          final sel = _course == c;
                          return GestureDetector(
                            onTap: () => setState(() => _course = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.red.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.red
                                        : AppColors.borderGray,
                                    width: sel ? 1.5 : 1),
                              ),
                              child: Text(c,
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: sel
                                          ? AppColors.red
                                          : AppColors.midGray)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Year row
                      Text('Year Level',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.midGray)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _yearOptions.map((y) {
                          final sel = _year == y;
                          return GestureDetector(
                            onTap: () => setState(() => _year = y),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.red.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.red
                                        : AppColors.borderGray,
                                    width: sel ? 1.5 : 1),
                              ),
                              child: Text('Year $y',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: sel
                                          ? AppColors.red
                                          : AppColors.midGray)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Section letter row
                      Text('Section Letter',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.midGray)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: _sectionLetters.map((l) {
                          final sel = _letter == l;
                          return GestureDetector(
                            onTap: () => setState(() => _letter = l),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.red.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.red
                                        : AppColors.borderGray,
                                    width: sel ? 1.5 : 1),
                              ),
                              child: Center(
                                child: Text(l,
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? AppColors.red
                                            : AppColors.midGray)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Apply preset button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _applyPreset,
                          icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                          label: Text(
                              'Fill "$_course $_year-$_letter"',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(height: 16),
            ],

            // ── Manual name field ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: kCardDecoration(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Section Name',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightGray,
                        letterSpacing: 0.6)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ctrl,
                  style: GoogleFonts.inter(fontSize: 14),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. BSCS 1-A',
                    hintStyle: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.lightGray),
                    prefixIcon: const Icon(Icons.label_outline,
                        size: 18, color: AppColors.lightGray),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Section name is required.';
                    if (val == widget.existingName) return null;
                    if (widget.allSections.contains(val))
                      return '"$val" already exists.';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Format tip: COURSE YEAR-LETTER  (e.g. BSCS 1-A, BSIT 2-B)',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.lightGray),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Action buttons ─────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.inter()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : Icon(isEdit ? Icons.save_outlined : Icons.add,
                      size: 18),
                  label: Text(isEdit ? 'Save Changes' : 'Add Section',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}