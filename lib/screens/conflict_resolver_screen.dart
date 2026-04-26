// lib/screens/conflict_resolver_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class ConflictResolverScreen extends StatefulWidget {
  const ConflictResolverScreen({super.key});

  @override
  State<ConflictResolverScreen> createState() => _ConflictResolverScreenState();
}

class _ConflictResolverScreenState extends State<ConflictResolverScreen>
    with TickerProviderStateMixin {
  bool _isResolving = false;
  List<_ResolveResult> _results = [];
  bool _done = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Time slot helpers ─────────────────────────────────────────────────────

  /// Converts "HH:mm" to total minutes from midnight.
  int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Converts total minutes back to "HH:mm".
  String _fromMinutes(int mins) {
    final h = (mins ~/ 60).toString().padLeft(2, '0');
    final m = (mins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Returns true if [aStart, aEnd) overlaps [bStart, bEnd).
  bool _timesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart < bEnd && bStart < aEnd;
  }

  /// Tries to find a new time slot for [entry] (same day, same duration)
  /// that doesn't conflict with anything else in [allEntries].
  /// Returns the new (timeStart, timeEnd) or null if none found.
  (String, String)? _findFreeSlot(
      ScheduleEntry entry,
      List<ScheduleEntry> allEntries,
      ) {
    final durationMins =
        _toMinutes(entry.timeEnd) - _toMinutes(entry.timeStart);
    // Try slots from 07:00 to 21:00 in 30-min increments
    for (int start = 7 * 60; start + durationMins <= 21 * 60; start += 30) {
      final end = start + durationMins;
      bool conflict = false;
      for (final other in allEntries) {
        if (other.id == entry.id) continue;
        if (other.day != entry.day) continue;
        final oStart = _toMinutes(other.timeStart);
        final oEnd = _toMinutes(other.timeEnd);
        // Teacher conflict
        if (other.teacher.id == entry.teacher.id &&
            _timesOverlap(start, end, oStart, oEnd)) {
          conflict = true;
          break;
        }
        // Room conflict
        if (other.room.id == entry.room.id &&
            _timesOverlap(start, end, oStart, oEnd)) {
          conflict = true;
          break;
        }
      }
      if (!conflict) {
        return (_fromMinutes(start), _fromMinutes(end));
      }
    }
    return null;
  }

  // ── Main resolve algorithm ────────────────────────────────────────────────
  Future<void> _resolveAll() async {
    final state = Provider.of<AppState>(context, listen: false);
    final unresolved = state.conflicts.where((c) => !c.isResolved).toList();

    if (unresolved.isEmpty) return;

    setState(() {
      _isResolving = true;
      _results = [];
      _done = false;
    });

    // Work on a mutable copy of schedule entries
    final workingEntries = List<ScheduleEntry>.from(state.scheduleEntries);
    final newResults = <_ResolveResult>[];
    // Track teachers already notified to avoid duplicates
    final notifiedTeachers = <String>{};

    for (final conflict in unresolved) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      // Pick the second entry to reschedule (keep the first as anchor)
      final toReschedule = conflict.conflictingEntry2;

      final slot = _findFreeSlot(toReschedule, workingEntries);

      if (slot != null) {
        final (newStart, newEnd) = slot;

        // Apply change to working copy
        final idx = workingEntries.indexWhere((e) => e.id == toReschedule.id);
        if (idx != -1) {
          workingEntries[idx] = workingEntries[idx].copyWith(
            timeStart: newStart,
            timeEnd: newEnd,
            hasConflict: false,
            updatedAt: DateTime.now(),
          );
        }

        // Persist the change in AppState
        state.updateScheduleEntry(
          toReschedule.copyWith(
            timeStart: newStart,
            timeEnd: newEnd,
            hasConflict: false,
            updatedAt: DateTime.now(),
          ),
        );

        // Resolve conflict in state
        state.resolveConflict(conflict.id);

        // Notify teacher via chat (once per unique teacher)
        final teacherId = toReschedule.teacher.id;
        if (!notifiedTeachers.contains(teacherId)) {
          notifiedTeachers.add(teacherId);
          state.sendChatMessage(ChatMessage(
            id: 'resolver_${conflict.id}_${DateTime.now().millisecondsSinceEpoch}',
            senderId: 'admin',
            senderName: 'Administrator',
            message:
            '🔧 CONFLICT RESOLVED — AUTO SCHEDULE ADJUSTMENT\n\n'
                '📚 Subject: ${toReschedule.subject.code} – ${toReschedule.subject.name}\n'
                '📅 Day: ${toReschedule.day}\n'
                '⏰ New Time: $newStart – $newEnd\n'
                '🚪 Room: ${toReschedule.room.name}\n\n'
                'The system automatically resolved your schedule conflict by '
                'moving the class to a conflict-free time slot. '
                'Please check your updated schedule.',
            isFromTeacher: false,
            timestamp: DateTime.now(),
            isResolved: true,
            adminResponse:
            '✅ Conflict auto-resolved. New time: $newStart – $newEnd on ${toReschedule.day}.',
            wasApproved: true,
          ));
        }

        newResults.add(_ResolveResult(
          subject: '${toReschedule.subject.code} – ${toReschedule.subject.name}',
          teacher: toReschedule.teacher.fullName,
          day: toReschedule.day,
          oldTime: '${toReschedule.timeStart} – ${toReschedule.timeEnd}',
          newTime: '$newStart – $newEnd',
          room: toReschedule.room.name,
          conflictType: conflict.typeLabel,
          success: true,
        ));
      } else {
        // Could not find a free slot
        newResults.add(_ResolveResult(
          subject: '${toReschedule.subject.code} – ${toReschedule.subject.name}',
          teacher: toReschedule.teacher.fullName,
          day: toReschedule.day,
          oldTime: '${toReschedule.timeStart} – ${toReschedule.timeEnd}',
          newTime: null,
          room: toReschedule.room.name,
          conflictType: conflict.typeLabel,
          success: false,
        ));
      }

      if (mounted) {
        setState(() => _results = List.from(newResults));
      }
    }

    if (mounted) {
      setState(() {
        _isResolving = false;
        _done = true;
      });
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final unresolved = state.conflicts.where((c) => !c.isResolved).toList();
      final resolved   = state.conflicts.where((c) => c.isResolved).toList();

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          title: const Text('Conflict Resolver'),
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          actions: [
            if (unresolved.isNotEmpty && !_isResolving)
              TextButton.icon(
                onPressed: _resolveAll,
                icon: const Icon(Icons.auto_fix_high, color: Colors.white, size: 18),
                label: Text('Auto-Resolve All',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: unresolved.isEmpty && !_done && _results.isEmpty
            ? _buildEmpty(resolved)
            : Column(
          children: [
            // ── Status strip ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              color: _isResolving
                  ? AppColors.darkGray
                  : _done
                  ? (_results.any((r) => r.success)
                  ? AppColors.available
                  : AppColors.conflict)
                  : AppColors.conflict.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (_isResolving)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: const Icon(Icons.auto_fix_high, color: Colors.white70, size: 18),
                      ),
                    )
                  else
                    Icon(
                      _done ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isResolving
                          ? 'Analyzing and resolving conflicts…'
                          : _done
                          ? '${_results.where((r) => r.success).length} of ${_results.length} conflicts resolved'
                          : '${unresolved.length} unresolved conflict${unresolved.length > 1 ? 's' : ''} detected',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isResolving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Resolution results ─────────────────────────────
                  if (_results.isNotEmpty) ...[
                    _sectionLabel('Resolution Results'),
                    const SizedBox(height: 10),
                    ..._results.map((r) => _ResultCard(result: r)),
                    const SizedBox(height: 20),
                  ],

                  // ── Unresolved list ────────────────────────────────
                  if (unresolved.isNotEmpty && !_done) ...[
                    _sectionLabel('Unresolved Conflicts (${unresolved.length})'),
                    const SizedBox(height: 10),
                    ...unresolved.map((c) => _ConflictCard(conflict: c)),
                    const SizedBox(height: 16),

                    // Big resolve button if not yet resolving
                    if (!_isResolving)
                      _ResolveButton(onTap: _resolveAll),
                    const SizedBox(height: 20),
                  ],

                  // ── Already resolved ───────────────────────────────
                  if (resolved.isNotEmpty) ...[
                    _sectionLabel('Already Resolved (${resolved.length})'),
                    const SizedBox(height: 10),
                    ...resolved.map((c) => _ConflictCard(conflict: c)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEmpty(List<ScheduleConflict> resolved) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.available.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 52, color: AppColors.available),
            ),
            const SizedBox(height: 16),
            Text('No Active Conflicts',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.available)),
            const SizedBox(height: 6),
            Text('All schedules are conflict-free.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.lightGray)),
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('${resolved.length} conflict${resolved.length > 1 ? 's' : ''} previously resolved.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
    ]),
  );
}

// ── Resolution result card ──────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _ResolveResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.success ? AppColors.available : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            Icon(result.success ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.success ? 'Resolved — Time adjusted' : 'Could not auto-resolve',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(result.conflictType,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.subject,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 2),
              Text('${result.teacher} · ${result.room} · ${result.day}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
              if (result.success && result.newTime != null) ...[
                const SizedBox(height: 10),
                Row(children: [
                  // Old time — strikethrough
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.conflict.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(result.oldTime,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.conflict,
                          decoration: TextDecoration.lineThrough,
                        )),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 14, color: AppColors.lightGray),
                  ),
                  // New time — green
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.available.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(result.newTime!,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.available)),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.notifications_outlined, size: 13, color: AppColors.available),
                  const SizedBox(width: 5),
                  Text('Teacher notified automatically',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.available)),
                ]),
              ] else if (!result.success) ...[
                const SizedBox(height: 8),
                Text('No conflict-free slot found on ${result.day}. Manual resolution required.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Unresolved / resolved conflict card ────────────────────────────────────
class _ConflictCard extends StatelessWidget {
  final ScheduleConflict conflict;
  const _ConflictCard({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final color = conflict.isResolved ? AppColors.available : AppColors.conflict;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Row(children: [
            Icon(conflict.isResolved ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(conflict.typeLabel,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(conflict.isResolved ? 'Resolved' : 'Active',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conflict.description,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.midGray)),
              const SizedBox(height: 8),
              _entryRow('Entry 1', conflict.conflictingEntry1),
              const SizedBox(height: 6),
              _entryRow('Entry 2', conflict.conflictingEntry2),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _entryRow(String label, ScheduleEntry e) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lightGray)),
          const SizedBox(height: 3),
          Text(
            '${e.subject.code} | ${e.teacher.fullName} | ${e.room.name} | ${e.day} ${e.timeRange}',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }
}

// ── Big hero resolve button ─────────────────────────────────────────────────
class _ResolveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResolveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF990000), AppColors.red],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: AppColors.red.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(children: [
          const Icon(Icons.auto_fix_high, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text('Auto-Resolve All Conflicts',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text('AI will adjust conflicting times & notify teachers',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
        ]),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _ResolveResult {
  final String subject;
  final String teacher;
  final String day;
  final String oldTime;
  final String? newTime;
  final String room;
  final String conflictType;
  final bool success;

  const _ResolveResult({
    required this.subject,
    required this.teacher,
    required this.day,
    required this.oldTime,
    required this.newTime,
    required this.room,
    required this.conflictType,
    required this.success,
  });
}