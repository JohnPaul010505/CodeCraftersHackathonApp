// conflict_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';
import 'conflict_resolution_screen.dart';

class ConflictDetectionScreen extends StatelessWidget {
  const ConflictDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final active = state.conflicts.where((c) => !c.isResolved).toList();
        final resolved = state.conflicts.where((c) => c.isResolved).toList();

        return Scaffold(
          backgroundColor: AppColors.bgGray,
          appBar: AppBar(
            title: const Text('Conflict Detection'),
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
          ),
          body: state.conflicts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.available.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline,
                            size: 52, color: AppColors.available),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Conflicts Detected',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.available,
                        ),
                      ),
                      Text(
                        'Your schedule is conflict-free.',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.lightGray),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (active.isNotEmpty) ...[
                      _sectionHeader(
                          'Active Conflicts (${active.length})', AppColors.conflict),
                      const SizedBox(height: 12),
                      ...active.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConflictCard(
                              conflict: c,
                              onResolve: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ConflictResolutionScreen(),
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (resolved.isNotEmpty) ...[
                      _sectionHeader(
                          'Resolved (${resolved.length})', AppColors.available),
                      const SizedBox(height: 12),
                      ...resolved.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConflictCard(conflict: c),
                          )),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
            )),
      ],
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final ScheduleConflict conflict;
  final VoidCallback? onResolve;

  const _ConflictCard({required this.conflict, this.onResolve});

  @override
  Widget build(BuildContext context) {
    final color =
        conflict.isResolved ? AppColors.available : AppColors.conflict;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(
                  conflict.isResolved
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.typeLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    conflict.isResolved ? 'Resolved' : 'Active',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conflict.description,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.darkGray)),
                const SizedBox(height: 12),
                _entryRow('Entry 1', conflict.conflictingEntry1),
                const SizedBox(height: 8),
                _entryRow('Entry 2', conflict.conflictingEntry2),
                if (!conflict.isResolved && onResolve != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.build_outlined, size: 16),
                      label: Text('Resolve Conflict',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.conflict,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryRow(String label, ScheduleEntry entry) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightGray)),
          const SizedBox(height: 4),
          Text(
            '${entry.subject.code} | ${entry.teacher.fullName} | ${entry.room.name} | ${entry.day} ${entry.timeRange}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.darkGray),
          ),
        ],
      ),
    );
  }
}
