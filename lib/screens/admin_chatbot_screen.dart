import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class AdminChatbotScreen extends StatefulWidget {
  const AdminChatbotScreen({super.key});
  @override
  State<AdminChatbotScreen> createState() => _AdminChatbotScreenState();
}

class _AdminChatbotScreenState extends State<AdminChatbotScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final pending = state.chatMessages.where((m) => !m.isResolved).toList();
      final resolved = state.chatMessages.where((m) => m.isResolved).toList();

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          title: Row(children: [
            const Text('Teacher Requests'),
            const SizedBox(width: 10),
            if (pending.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.conflict, borderRadius: BorderRadius.circular(20)),
                child: Text('${pending.length} new',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
          ]),
          backgroundColor: AppColors.red,
          foregroundColor: Colors.white,
        ),
        body: state.chatMessages.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No teacher requests yet',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
          Text('Teacher messages will appear here',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400)),
        ]))
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              _sectionHeader('Pending Approval (${pending.length})', AppColors.moderate),
              const SizedBox(height: 12),
              ...pending.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(
                  message: msg,
                  onApprove: (response) => _handleApprove(context, state, msg, response),
                  onDecline: () => _handleDecline(context, state, msg),
                ),
              )),
              const SizedBox(height: 16),
            ],
            if (resolved.isNotEmpty) ...[
              _sectionHeader('Resolved (${resolved.length})', AppColors.available),
              const SizedBox(height: 12),
              ...resolved.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RequestCard(message: msg),
              )),
            ],
          ],
        ),
      );
    });
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
    ]);
  }

  void _handleApprove(BuildContext context, AppState state, ChatMessage msg, String response) {
    // approveTeacherRequest handles the auto-action AND marks resolved in Firestore
    state.approveTeacherRequest(msg, response);
    final aiAction = _parseAiAction(msg.message);
    _showAiActionPopup(context, msg, aiAction, approved: true);
  }

  void _handleDecline(BuildContext context, AppState state, ChatMessage msg) {
    state.respondToChat(msg.id, 'Request has been declined by the admin.');
    _showAiActionPopup(context, msg, 'Request declined and teacher notified.', approved: false);
  }

  /// Parses the request message to determine what the AI did
  String _parseAiAction(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('absent') || lower.contains('absence')) {
      return 'Absence noted. Affected classes marked as "pending substitute". Teacher\'s schedule has been flagged for the indicated date. Admin may assign a substitute manually.';
    }
    if (lower.contains('advance schedul')) {
      return 'Advance scheduling request logged. The requested date and room preference have been forwarded to the scheduling queue. Admin may confirm room assignment.';
    }
    if (lower.contains('cancel')) {
      return 'Class cancellation recorded. The affected schedule entry has been flagged. Students and sections will be notified upon full admin confirmation.';
    }
    if (lower.contains('reschedule') || lower.contains('schedule change')) {
      return 'Schedule change request processed. The original time slot has been flagged as "pending reschedule". New schedule will be applied once the admin confirms room and time availability.';
    }
    return 'Request has been reviewed and forwarded to the relevant scheduling queue. Teacher has been notified of the admin\'s decision.';
  }

  /// Shows a modal popup describing what the AI did after approval/decline
  void _showAiActionPopup(BuildContext context, ChatMessage msg, String aiAction, {required bool approved}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (approved ? AppColors.available : AppColors.conflict).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  approved ? Icons.smart_toy_outlined : Icons.cancel_outlined,
                  color: approved ? AppColors.available : AppColors.conflict,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  approved ? 'AI Action Completed' : 'Request Declined',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                ),
                Text(
                  'From: ${msg.senderName}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightGray),
                ),
              ])),
            ]),
            const SizedBox(height: 20),
            Divider(color: AppColors.borderGray),
            const SizedBox(height: 14),

            // Original request
            Text('Original Request', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightGray, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(10)),
              child: Text(msg.message, style: GoogleFonts.inter(fontSize: 13, color: AppColors.darkGray, height: 1.5)),
            ),
            const SizedBox(height: 14),

            // AI Action
            Text('What the AI Did', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                color: approved ? AppColors.available : AppColors.conflict, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (approved ? AppColors.available : AppColors.conflict).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (approved ? AppColors.available : AppColors.conflict).withValues(alpha: 0.25)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(approved ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16, color: approved ? AppColors.available : AppColors.conflict),
                const SizedBox(width: 8),
                Expanded(child: Text(aiAction, style: GoogleFonts.inter(fontSize: 13,
                    color: approved ? AppColors.available : AppColors.conflict, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 14),

            // Timestamp
            Row(children: [
              Icon(Icons.access_time_outlined, size: 13, color: AppColors.lightGray),
              const SizedBox(width: 4),
              Text(DateFormat('MMM d, yyyy · h:mm a').format(DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
            ]),
            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: approved ? AppColors.available : AppColors.conflict,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Understood', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onApprove;
  final VoidCallback? onDecline;

  const _RequestCard({required this.message, this.onApprove, this.onDecline});

  @override
  Widget build(BuildContext context) {
    final isPending = !message.isResolved;
    final borderColor = isPending ? AppColors.moderate.withValues(alpha: 0.3) : AppColors.available.withValues(alpha: 0.3);
    final headerColor = isPending ? AppColors.moderate.withValues(alpha: 0.07) : AppColors.available.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: headerColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text(message.senderName[0], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.red)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.senderName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              Text(DateFormat('EEE, MMM d · h:mm a').format(message.timestamp),
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.lightGray)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPending ? AppColors.moderate.withValues(alpha: 0.15) : AppColors.available.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isPending ? 'Pending' : 'Resolved',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                      color: isPending ? AppColors.moderate : AppColors.available)),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bgGray, borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(child: Text(message.message, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.darkGray, height: 1.5))),
              ]),
            ),

            // Admin response
            if (message.adminResponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.available.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.available.withValues(alpha: 0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.available),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message.adminResponse!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.available, height: 1.5))),
                ]),
              ),
            ],

            // Actions
            if (isPending && onApprove != null && onDecline != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: onDecline,
                  icon: const Icon(Icons.close, size: 16),
                  label: Text('Decline', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.conflict,
                    side: const BorderSide(color: AppColors.conflict),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: ElevatedButton.icon(
                  onPressed: () => _showApproveDialog(context, onApprove!),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text('Approve & Respond', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  void _showApproveDialog(BuildContext context, Function(String) onApprove) {
    final ctrl = TextEditingController(text: 'Your request has been approved. Schedule has been updated accordingly.');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle, color: AppColors.available),
          const SizedBox(width: 10),
          Text('Approve Request', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Write a response to the teacher:', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightGray)),
          const SizedBox(height: 10),
          TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Response message')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              onApprove(ctrl.text.trim().isEmpty ? 'Approved.' : ctrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
            child: Text('Confirm & Send', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}