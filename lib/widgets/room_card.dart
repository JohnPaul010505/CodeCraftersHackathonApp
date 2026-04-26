import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onEdit,
  });

  Color get _statusColor {
    switch (room.status) {
      case RoomStatus.available:
        return AppTheme.availableGreen;
      case RoomStatus.occupied:
        return AppTheme.conflictRed;
      case RoomStatus.maintenance:
        return AppTheme.warningOrange;
      case RoomStatus.event:
        return AppTheme.warningYellow;
    }
  }

  IconData get _statusIcon {
    switch (room.status) {
      case RoomStatus.available:
        return Icons.check_circle_outline;
      case RoomStatus.occupied:
        return Icons.people_outline;
      case RoomStatus.maintenance:
        return Icons.build_outlined;
      case RoomStatus.event:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Status header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon, color: _statusColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      room.statusLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(Icons.edit_outlined,
                          color: _statusColor, size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        room.type == RoomType.laboratory
                            ? Icons.computer_outlined
                            : Icons.meeting_room_outlined,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          room.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chipInfo(Icons.layers_outlined, 'Floor ${room.floor}'),
                      const SizedBox(width: 8),
                      _chipInfo(Icons.people_outline, '${room.capacity} seats'),
                      const SizedBox(width: 8),
                      _chipInfo(
                        room.type == RoomType.laboratory
                            ? Icons.science_outlined
                            : Icons.menu_book_outlined,
                        room.typeLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (room.hasProjector) _equipBadge('Projector'),
                      if (room.hasAirConditioning) _equipBadge('AC'),
                      if (room.hasComputers) _equipBadge('Computers'),
                    ],
                  ),
                  if (room.status == RoomStatus.occupied &&
                      room.currentSubject != null) ...[
                    const Divider(height: 16),
                    _infoRow(Icons.book_outlined, room.currentSubject!),
                    const SizedBox(height: 4),
                    _infoRow(Icons.person_outline, room.currentTeacher ?? ''),
                    const SizedBox(height: 4),
                    _infoRow(Icons.group_outlined, room.currentSection ?? ''),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.access_time_outlined,
                      '${room.currentTimeStart} – ${room.currentTimeEnd}',
                    ),
                  ],
                  if ((room.status == RoomStatus.event ||
                          room.status == RoomStatus.maintenance) &&
                      room.eventNote != null) ...[
                    const Divider(height: 16),
                    _infoRow(Icons.info_outline, room.eventNote!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _equipBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
