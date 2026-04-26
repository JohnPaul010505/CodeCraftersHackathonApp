import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

// =============================================================================
//  ConflictResolutionScreen  (root widget)
// =============================================================================
class ConflictResolutionScreen extends StatefulWidget {
  const ConflictResolutionScreen({super.key});

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  String? _selectedConflictId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final active =
        state.conflicts.where((c) => !c.isResolved).toList();

        // ── If a conflict is selected, show detail view ───────────────
        if (_selectedConflictId != null) {
          final matches = state.conflicts
              .where((c) => c.id == _selectedConflictId)
              .toList();

          if (matches.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
                    (_) => setState(() => _selectedConflictId = null));
            return const SizedBox.shrink();
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF0F0F0),
            appBar: _buildAppBar(context),
            body: ConflictDetailBody(
              conflict: matches.first,
              state: state,
              onBack: () => setState(() => _selectedConflictId = null),
              onResolved: () => setState(() => _selectedConflictId = null),
            ),
          );
        }

        // ── Otherwise show list view ──────────────────────────────────
        return Scaffold(
          backgroundColor: const Color(0xFFF0F0F0),
          appBar: _buildAppBar(context),
          body: ConflictListBody(
            active: active,
            onSelectConflict: (id) =>
                setState(() => _selectedConflictId = id),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkGray,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const SizedBox.shrink(),
    );
  }
}

// =============================================================================
//  ConflictListBody  (list of conflicts – image 9)
// =============================================================================
class ConflictListBody extends StatelessWidget {
  final List<ScheduleConflict> active;
  final void Function(String) onSelectConflict;

  const ConflictListBody({
    super.key,
    required this.active,
    required this.onSelectConflict,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Warning banner ────────────────────────────────────────────
        if (active.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            color: const Color(0xFFFFF8E8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Color(0xFFE8A000), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${active.length} conflict${active.length > 1 ? 's' : ''} '
                        'detected in the current schedule',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8B6000)),
                  ),
                ),
              ],
            ),
          ),

        // ── Conflict Types Monitored card ─────────────────────────────
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conflict Types Monitored',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 14),
              _conflictTypeRow(
                  'Double-booked Rooms',
                  'Same room assigned to multiple classes at the same time'),
              const SizedBox(height: 10),
              _conflictTypeRow(
                  'Teacher Overlap',
                  'Teacher scheduled for multiple classes simultaneously'),
              const SizedBox(height: 10),
              _conflictTypeRow(
                  'Equipment Mismatch',
                  "Room doesn't have required equipment for the subject"),
              const SizedBox(height: 10),
              _conflictTypeRow(
                  'Capacity Mismatch',
                  'Room capacity is insufficient for the class size'),
            ],
          ),
        ),

        // ── Active Conflicts ──────────────────────────────────────────
        if (active.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text('Active Conflicts',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray)),
          ),
          ...active.map(
                (c) => ConflictSummaryCard(
              conflict: c,
              onTap: () => onSelectConflict(c.id),
            ),
          ),
        ] else
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.available.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.available.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.available, size: 22),
                const SizedBox(width: 10),
                Text('No active conflicts!',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.available)),
              ],
            ),
          ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _conflictTypeRow(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkGray)),
        const SizedBox(height: 2),
        Text(desc,
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.lightGray)),
      ],
    );
  }
}

// =============================================================================
//  ConflictSummaryCard  (single card in list)
// =============================================================================
class ConflictSummaryCard extends StatelessWidget {
  final ScheduleConflict conflict;
  final VoidCallback onTap;

  const ConflictSummaryCard({
    super.key,
    required this.conflict,
    required this.onTap,
  });

  bool get _isHigh =>
      conflict.type == ConflictType.doubleBookedRoom ||
          conflict.type == ConflictType.roomCapacityMismatch;

  @override
  Widget build(BuildContext context) {
    final borderColor =
    _isHigh ? AppColors.conflict : const Color(0xFFE8A000);
    final badgeColor =
    _isHigh ? AppColors.conflict : const Color(0xFFE8A000);
    final severity = _isHigh ? 'HIGH' : 'MEDIUM';
    final severityIcon =
    _isHigh ? Icons.error_outline : Icons.warning_amber_outlined;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(severityIcon, color: badgeColor, size: 20),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(severity,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        conflict.typeLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.midGray,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(conflict.description,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Text('Tap to resolve this conflict',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.lightGray)),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  ConflictDetailBody  (detail + resolution view – images 10 & 11)
// =============================================================================
class ConflictDetailBody extends StatefulWidget {
  final ScheduleConflict conflict;
  final AppState state;
  final VoidCallback onBack;
  final VoidCallback onResolved;

  const ConflictDetailBody({
    super.key,
    required this.conflict,
    required this.state,
    required this.onBack,
    required this.onResolved,
  });

  @override
  State<ConflictDetailBody> createState() => ConflictDetailBodyState();
}

class ConflictDetailBodyState extends State<ConflictDetailBody> {
  Room? _selectedRoom;
  String? _selectedTimeSlot;

  @override
  Widget build(BuildContext context) {
    final availableRooms = widget.state.rooms
        .where((r) => r.status == RoomStatus.available)
        .toList();

    final timeSlots = _buildTimeSlots();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Conflict Details card ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: const Border(
                left: BorderSide(color: AppColors.conflict, width: 4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conflict Details',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Text(
                'Type: ${widget.conflict.typeLabel.toUpperCase()}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.lightGray),
              ),
              const SizedBox(height: 6),
              Text(
                widget.conflict.description,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.darkGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Current Assignment ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4)
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Assignment',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              Divider(height: 20, color: Colors.grey.shade200),
              _assignRow(
                'Subject',
                '${widget.conflict.conflictingEntry1.subject.code}'
                    ' - ${widget.conflict.conflictingEntry1.subject.name}',
              ),
              const SizedBox(height: 6),
              _assignRow(
                'Teacher',
                widget.conflict.conflictingEntry1.teacher.fullName,
              ),
              const SizedBox(height: 6),
              _assignRow(
                'Room',
                '${widget.conflict.conflictingEntry1.room.name}'
                    ' (Capacity: ${widget.conflict.conflictingEntry1.room.capacity})',
              ),
              const SizedBox(height: 6),
              _assignRow(
                'Time',
                '${widget.conflict.conflictingEntry1.day} '
                    '${widget.conflict.conflictingEntry1.timeStart}'
                    ' - ${widget.conflict.conflictingEntry1.timeEnd}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Suggested Solutions ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6B6B6B),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suggested Solutions',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 10),
              if (availableRooms.isEmpty)
                Text('No available rooms at this time.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white70))
              else
                ...availableRooms.take(3).map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${_buildSuggestion(r)}',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Resolution Options ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4)
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resolution Options',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 14),

              // Change Room
              _buildRoomDropdown(availableRooms),
              const SizedBox(height: 12),

              // Change Time Slot
              _buildTimeSlotDropdown(timeSlots),
              const SizedBox(height: 20),

              // Apply Resolution
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: (_selectedRoom != null ||
                      _selectedTimeSlot != null)
                      ? () => _applyResolution(context)
                      : null,
                  icon: const Icon(Icons.check_circle_outline,
                      size: 18),
                  label: Text('Apply Resolution',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    (_selectedRoom != null || _selectedTimeSlot != null)
                        ? AppColors.available
                        : Colors.grey.shade300,
                    foregroundColor:
                    (_selectedRoom != null || _selectedTimeSlot != null)
                        ? Colors.white
                        : Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Mark as Resolved
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _markResolved(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.available),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Mark as Resolved',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.available,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Back button
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text('Back to all conflicts',
              style: GoogleFonts.inter(fontSize: 13)),
          style:
          TextButton.styleFrom(foregroundColor: AppColors.lightGray),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Dropdown builders (avoid generic nullable issues) ────────────────────

  Widget _buildRoomDropdown(List<Room> availableRooms) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Room>(
          value: _selectedRoom,
          isExpanded: true,
          hint: Text('Change Room',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.lightGray)),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.lightGray),
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.darkGray),
          items: availableRooms
              .map(
                (r) => DropdownMenuItem<Room>(
              value: r,
              child: Text(
                  '${r.name} (Capacity: ${r.capacity})',
                  style: GoogleFonts.inter(fontSize: 14)),
            ),
          )
              .toList(),
          onChanged: (Room? v) => setState(() => _selectedRoom = v),
        ),
      ),
    );
  }

  Widget _buildTimeSlotDropdown(List<String> timeSlots) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeSlot,
          isExpanded: true,
          hint: Text('Change Time Slot',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.lightGray)),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.lightGray),
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.darkGray),
          items: timeSlots
              .map(
                (ts) => DropdownMenuItem<String>(
              value: ts,
              child: Text(ts,
                  style: GoogleFonts.inter(fontSize: 14)),
            ),
          )
              .toList(),
          onChanged: (String? v) =>
              setState(() => _selectedTimeSlot = v),
        ),
      ),
    );
  }

  // ── Other helpers ─────────────────────────────────────────────────────────

  Widget _assignRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
            fontSize: 13, color: AppColors.darkGray),
        children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  String _buildSuggestion(Room r) {
    final e = widget.conflict.conflictingEntry1;
    const slots = [
      '09:30 - 11:00',
      '11:00 - 12:30',
      '13:30 - 15:00',
    ];
    final idx = widget.state.rooms.indexOf(r) % slots.length;
    if (widget.conflict.type == ConflictType.roomCapacityMismatch ||
        widget.conflict.type == ConflictType.doubleBookedRoom) {
      return '${r.name} (Capacity: ${r.capacity}) is available during this time slot';
    }
    return '${r.name} (Capacity: ${r.capacity}) is available'
        ' ${e.day} ${slots[idx]}';
  }

  List<String> _buildTimeSlots() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];
    const times = [
      '08:00 - 09:30',
      '09:30 - 11:00',
      '11:00 - 12:30',
      '13:30 - 15:00',
      '15:00 - 16:30',
    ];
    final result = <String>[];
    for (final d in days) {
      for (final t in times) {
        result.add('$d $t');
      }
    }
    return result;
  }

  void _applyResolution(BuildContext context) {
    final entry = widget.conflict.conflictingEntry1;
    ScheduleEntry updated = entry;

    if (_selectedRoom != null) {
      updated = updated.copyWith(room: _selectedRoom);
    }
    if (_selectedTimeSlot != null) {
      // Format: "Monday 08:00 - 09:30"
      final parts = _selectedTimeSlot!.split(' ');
      if (parts.length >= 4) {
        final day = parts[0];
        final ts = parts[1];
        final te = parts[3];
        updated = updated.copyWith(day: day, timeStart: ts, timeEnd: te);
      }
    }

    widget.state.updateScheduleEntry(updated);
    widget.state.resolveConflict(widget.conflict.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resolution applied successfully!',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.available,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
    widget.onResolved();
  }

  void _markResolved(BuildContext context) {
    widget.state.resolveConflict(widget.conflict.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conflict marked as resolved.',
            style: GoogleFonts.inter()),
        backgroundColor: AppColors.available,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
    widget.onResolved();
  }
}