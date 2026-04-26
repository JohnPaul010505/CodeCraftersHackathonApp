// lib/screens/room_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

class RoomManagerScreen extends StatefulWidget {
  final Room? room;
  const RoomManagerScreen({super.key, this.room});
  @override
  State<RoomManagerScreen> createState() => _State();
}

class _State extends State<RoomManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _floorCtrl, _capCtrl, _noteCtrl;
  late RoomType _type;
  late bool _projector, _ac, _computers;
  late RoomStatus _status;
  bool _saving = false;

  bool get isEdit => widget.room != null;

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _nameCtrl  = TextEditingController(text: r?.name ?? '');
    _floorCtrl = TextEditingController(text: r != null ? '${r.floor}' : '');
    _capCtrl   = TextEditingController(text: r != null ? '${r.capacity}' : '');
    _noteCtrl  = TextEditingController(text: r?.eventNote ?? '');
    _type      = r?.type ?? RoomType.lecture;
    _projector = r?.hasProjector ?? false;
    _ac        = r?.hasAirConditioning ?? false;
    _computers = r?.hasComputers ?? false;
    _status    = r?.status ?? RoomStatus.available;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _capCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 300));
    final state = Provider.of<AppState>(context, listen: false);
    final room = Room(
      id: widget.room?.id ?? 'r_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      floor: int.tryParse(_floorCtrl.text) ?? 1,
      capacity: int.tryParse(_capCtrl.text) ?? 30,
      type: _type,
      hasProjector: _projector,
      hasAirConditioning: _ac,
      hasComputers: _computers,
      status: _status,
      eventNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (isEdit) {
      state.updateRoom(room);
    } else {
      state.addRoom(room);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isEdit ? 'Room updated.' : 'Room added.',
          style: GoogleFonts.inter()),
      backgroundColor: AppColors.available,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Room' : 'Add Room',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.darkGray,
        foregroundColor: Colors.white,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Room Details ──────────────────────────────────────────
                  _SectionHeader('Room Details'),
                  Container(
                    decoration: kCardDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _Field(_nameCtrl, 'Room Name / Code',
                            Icons.meeting_room_outlined,
                            hint: 'e.g. 1A, LEC-201, LAB-301',
                            validator: (v) =>
                            v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _Field(_floorCtrl, 'Floor',
                                Icons.layers_outlined,
                                type: TextInputType.number,
                                validator: (v) =>
                                v!.isEmpty ? 'Required' : null),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(_capCtrl, 'Capacity',
                                Icons.people_outline,
                                type: TextInputType.number,
                                validator: (v) =>
                                v!.isEmpty ? 'Required' : null),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Room Type ────────────────────────────────────────────
                  _SectionHeader('Room Type'),
                  Row(children: [
                    _TypeOption(
                      type: RoomType.lecture,
                      icon: Icons.menu_book_outlined,
                      label: 'Lecture Room',
                      selected: _type == RoomType.lecture,
                      onTap: () => setState(() => _type = RoomType.lecture),
                    ),
                    const SizedBox(width: 12),
                    _TypeOption(
                      type: RoomType.laboratory,
                      icon: Icons.science_outlined,
                      label: 'Laboratory',
                      selected: _type == RoomType.laboratory,
                      onTap: () => setState(() => _type = RoomType.laboratory),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Equipment ────────────────────────────────────────────
                  _SectionHeader('Equipment'),
                  Container(
                    decoration: kCardDecoration(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(children: [
                      _EquipCheck(
                        label: 'Projector',
                        value: _projector,
                        onChange: (v) => setState(() => _projector = v!),
                      ),
                      const Divider(height: 1, color: AppColors.borderGray),
                      _EquipCheck(
                        label: 'Air Conditioning',
                        value: _ac,
                        onChange: (v) => setState(() => _ac = v!),
                      ),
                      const Divider(height: 1, color: AppColors.borderGray),
                      _EquipCheck(
                        label: 'Computers / Lab Equipment',
                        value: _computers,
                        onChange: (v) => setState(() => _computers = v!),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // ── Availability Status ──────────────────────────────────
                  _SectionHeader('Availability Status'),
                  Container(
                    decoration: kCardDecoration(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        RoomStatus.available,
                        RoomStatus.event,
                        RoomStatus.maintenance,
                      ].map((s) {
                        final isLast = s == RoomStatus.maintenance;
                        return Column(
                          children: [
                            RadioListTile<RoomStatus>(
                              value: s,
                              groupValue: _status,
                              title: Text(_statusLabel(s),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.darkGray)),
                              onChanged: (v) =>
                                  setState(() => _status = v!),
                              activeColor: AppColors.red,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              dense: true,
                            ),
                            if (!isLast)
                              const Divider(
                                  height: 1, color: AppColors.borderGray),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  if (_status == RoomStatus.event ||
                      _status == RoomStatus.maintenance) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: kCardDecoration(),
                      padding: const EdgeInsets.all(16),
                      child: _Field(
                          _noteCtrl, 'Reason / Note', Icons.info_outline),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Save button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(isEdit
                          ? Icons.save_outlined
                          : Icons.add_circle_outline),
                      label: Text(
                          isEdit ? 'Save Changes' : 'Add Room',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGray,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  if (isEdit) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.conflict, size: 18),
                        label: Text('Delete Room',
                            style: GoogleFonts.inter(
                                color: AppColors.conflict,
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side:
                          const BorderSide(color: AppColors.conflict),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          title: Text('Delete Room?',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Text(
              'This will permanently delete ${widget.room!.name}.',
              style: GoogleFonts.inter(fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text('Cancel', style: GoogleFonts.inter())),
            ElevatedButton(
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .updateRoomStatus(
                    widget.room!.id, RoomStatus.maintenance);
                Navigator.pop(dCtx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.conflict),
              child: Text('Delete', style: GoogleFonts.inter()),
            ),
          ],
        ));
  }

  String _statusLabel(RoomStatus s) {
    switch (s) {
      case RoomStatus.available:
        return 'Available';
      case RoomStatus.occupied:
        return 'Occupied';
      case RoomStatus.event:
        return 'Unavailable – School Event';
      case RoomStatus.maintenance:
        return 'Unavailable – Maintenance';
    }
  }
}

// ── Micro-widgets ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.lightGray,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final String? hint;
  final String? Function(String?)? validator;

  const _Field(
      this.ctrl,
      this.label,
      this.icon, {
        this.type = TextInputType.text,
        this.hint,
        this.validator,
      });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 17, color: AppColors.lightGray),
      ),
      validator: validator,
    );
  }
}

class _TypeOption extends StatelessWidget {
  final RoomType type;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.darkGray : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.darkGray : AppColors.borderGray,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.lightGray,
                  size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.lightGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EquipCheck extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChange;

  const _EquipCheck({
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray)),
      value: value,
      onChanged: onChange,
      activeColor: AppColors.red,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}