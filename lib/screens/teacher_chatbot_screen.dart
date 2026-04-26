import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/schedule.dart';
import '../theme/app_theme.dart';

class TeacherChatbotScreen extends StatefulWidget {
  const TeacherChatbotScreen({super.key});

  @override
  State<TeacherChatbotScreen> createState() => _TeacherChatbotScreenState();
}

class _TeacherChatbotScreenState extends State<TeacherChatbotScreen>
    with TickerProviderStateMixin {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _ringAnim;

  final List<_ChatBubble> _localMessages = [];

  final List<_QuickReply> _quickReplies = [
    _QuickReply('Report Absence',  Icons.sick_outlined,            'absence'),
    _QuickReply('Schedule Change', Icons.swap_horiz_outlined,      'reschedule'),
    _QuickReply('Advance Class',   Icons.event_available_outlined, 'advance'),
    _QuickReply('Cancel Class',    Icons.event_busy_outlined,      'cancel'),
  ];

  static const String _welcomeText =
      'Hello! I\'m your Smart Schedule Assistant. I can help you with:\n\n'
      '• Reporting absence or emergency\n'
      '• Requesting schedule changes\n'
      '• Advancing or cancelling a class\n\n'
      'Tap any option below or type your concern.';

  AppState? _appStateRef;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 18.0, end: 48.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _ringAnim = Tween<double>(begin: 0, end: 1.0).animate(_ringCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
      _appStateRef = Provider.of<AppState>(context, listen: false);
      _appStateRef!.addListener(_onAppStateChanged);
      _checkAdminResponses(_appStateRef!);
    });
  }

  @override
  void dispose() {
    _appStateRef?.removeListener(_onAppStateChanged);
    _msgController.dispose();
    _scrollController.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Persistence ───────────────────────────────────────────────────────────
  void _loadHistory() {
    final appState = Provider.of<AppState>(context, listen: false);
    final teacher = appState.currentTeacher;

    void seedWelcome() {
      if (_localMessages.isEmpty) {
        _localMessages.add(_ChatBubble(
          isBot: true, text: _welcomeText,
          time: DateTime.now().subtract(const Duration(minutes: 2)),
        ));
      }
    }

    if (teacher == null) { seedWelcome(); setState(() {}); return; }

    final saved = appState.getTeacherLocalHistory(teacher.id);
    if (saved.isNotEmpty) {
      setState(() { _localMessages..clear()..addAll(saved.map(_ChatBubble.fromMap)); });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
    } else {
      seedWelcome();
      setState(() {});
      _saveHistory(appState, teacher.id);
    }
  }

  void _saveHistory(AppState appState, String teacherId) {
    appState.saveTeacherLocalHistory(teacherId, _localMessages.map((b) => b.toMap()).toList());
  }

  // ── Admin-response listener ───────────────────────────────────────────────
  void _onAppStateChanged() {
    if (!mounted) return;
    _checkAdminResponses(Provider.of<AppState>(context, listen: false));
  }

  void _checkAdminResponses(AppState appState) {
    final teacher = appState.currentTeacher;
    if (teacher == null) return;
    bool changed = false;
    for (final msg in appState.chatMessages.where((m) => m.senderId == teacher.id && m.isResolved)) {
      if (appState.isMessageNotified(teacher.id, msg.id)) continue;
      appState.markMessageNotified(teacher.id, msg.id);
      final approved = msg.wasApproved == true;
      final note = (msg.adminResponse ?? '').trim();
      _localMessages.add(_ChatBubble(
        isBot: true,
        isAdminResponse: true,
        text: approved
            ? '✅ Your request has been APPROVED!\n\n'
            '${note.isNotEmpty ? "💬 Admin note: ${note}\n\n" : ""}'
            '📋 Your schedule has been automatically adjusted.'
            : '❌ Your request has been REJECTED.\n\n'
            '${note.isNotEmpty ? "💬 Admin note: ${note}\n\n" : ""}'
            '📋 Please contact the admin if you need further assistance.',
        time: DateTime.now(),
      ));
      changed = true;
    }
    if (changed && mounted) {
      setState(() {});
      _saveHistory(appState, teacher.id);
      _scrollDown();
    }
  }

  // ── New chat ──────────────────────────────────────────────────────────────
  void _startNewChat() {
    final appState = Provider.of<AppState>(context, listen: false);
    final teacher = appState.currentTeacher;
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.add_circle_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Text('New Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ]),
        content: Text('This will clear the current chat and start fresh. Continue?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.midGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              // Small delay ensures dialog pop completes before setState
              await Future.delayed(const Duration(milliseconds: 50));
              if (!mounted) return;
              setState(() {
                _localMessages.clear();
                _localMessages.add(_ChatBubble(isBot: true, text: _welcomeText, time: DateTime.now()));
              });
              if (teacher != null) _saveHistory(appState, teacher.id);
              _scrollDown();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: Text('Start New', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────────────────
  Future<String?> _pickDate(BuildContext ctx, {String title = 'Select Date'}) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      helpText: title,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.red, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const d = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return '${d[picked.weekday - 1]}, ${m[picked.month - 1]} ${picked.day}, ${picked.year}';
  }

  Future<String?> _pickTime(BuildContext ctx, {String title = 'Select Time'}) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.now(),
      helpText: title,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.red, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
    final min = picked.minute.toString().padLeft(2, '0');
    final p = picked.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$min $p';
  }

  // ── Animated dialog launcher ─────────────────────────────────────────────
  Future<T?> _showAnimated<T>(Widget Function(BuildContext ctx) builder) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.80, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  Future<void> _showAbsenceDialog() async {
    final subjectCtrl = TextEditingController();
    final reasonCtrl  = TextEditingController();
    String? date, time;
    await _showAnimated((dCtx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: _dialogTitle('Report Absence', Icons.sick_outlined, AppColors.conflict),
            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Subject / Class Affected *'),  const SizedBox(height: 6),
                _field(subjectCtrl, 'e.g. CS101 – BSCS 1-A', Icons.book_outlined),
                const SizedBox(height: 14),
                _lbl('Date of Absence *'),           const SizedBox(height: 6),
                _tile(date ?? 'Tap to select date', Icons.calendar_today_outlined, date == null,
                        () async { final v = await _pickDate(ctx, title: 'Date of Absence'); if (v != null) ss(() => date = v); }),
                const SizedBox(height: 14),
                _lbl('Class Time *'),                const SizedBox(height: 6),
                _tile(time ?? 'Tap to select time', Icons.access_time_outlined, time == null,
                        () async { final v = await _pickTime(ctx, title: 'Class Time'); if (v != null) ss(() => time = v); }),
                const SizedBox(height: 14),
                _lbl('Reason for Absence *'),        const SizedBox(height: 6),
                _textarea(reasonCtrl, 'e.g. Medical emergency, fever, family matter...'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
              ElevatedButton.icon(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty || date == null || time == null || reasonCtrl.text.trim().isEmpty) {
                    _snack('Please fill in all fields.'); return;
                  }
                  Navigator.pop(dCtx);
                  _sendStructured(
                    '🚨 ABSENCE REPORT\n\n📚 Subject: ${subjectCtrl.text.trim()}\n📅 Date: $date\n⏰ Time: $time\n📝 Reason: ${reasonCtrl.text.trim()}',
                    'Your absence has been reported to the administrator.\n\n'
                        '📚 Subject: ${subjectCtrl.text.trim()}\n📅 Date: $date  ⏰ $time\n📝 Reason: ${reasonCtrl.text.trim()}\n\n'
                        'A substitute teacher will be arranged. You\'ll be notified once confirmed.\n\n📋 Status: Pending Admin Approval',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.conflict),
              ),
            ],
          )),
    ),
    ),
    );
  }

  Future<void> _showScheduleChangeDialog() async {
    final subjectCtrl = TextEditingController();
    final reasonCtrl  = TextEditingController();
    String? currentDate, newDate, newTime;
    await _showAnimated((dCtx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: _dialogTitle('Schedule Change', Icons.swap_horiz_outlined, AppColors.moderate),
            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Subject / Class to Reschedule *'), const SizedBox(height: 6),
                _field(subjectCtrl, 'e.g. CS201 – BSCS 2-A', Icons.book_outlined),
                const SizedBox(height: 14),
                _lbl('Current Date *'), const SizedBox(height: 6),
                _tile(currentDate ?? 'Tap to select current date', Icons.event_outlined, currentDate == null,
                        () async { final v = await _pickDate(ctx, title: 'Current Date'); if (v != null) ss(() => currentDate = v); }),
                const SizedBox(height: 14),
                _lbl('Preferred New Date *'), const SizedBox(height: 6),
                _tile(newDate ?? 'Tap to select preferred date', Icons.event_available_outlined, newDate == null,
                        () async { final v = await _pickDate(ctx, title: 'Preferred New Date'); if (v != null) ss(() => newDate = v); }),
                const SizedBox(height: 14),
                _lbl('Preferred New Time *'), const SizedBox(height: 6),
                _tile(newTime ?? 'Tap to select preferred time', Icons.access_time_outlined, newTime == null,
                        () async { final v = await _pickTime(ctx, title: 'Preferred New Time'); if (v != null) ss(() => newTime = v); }),
                const SizedBox(height: 14),
                _lbl('Reason for Change *'), const SizedBox(height: 6),
                _textarea(reasonCtrl, 'e.g. Department seminar, conflict with exam...'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
              ElevatedButton.icon(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty || currentDate == null || newDate == null || newTime == null || reasonCtrl.text.trim().isEmpty) {
                    _snack('Please fill in all fields.'); return;
                  }
                  Navigator.pop(dCtx);
                  _sendStructured(
                    '🔄 SCHEDULE CHANGE REQUEST\n\n📚 Subject: ${subjectCtrl.text.trim()}\n📅 Current: $currentDate\n📅 New: $newDate  ⏰ $newTime\n📝 Reason: ${reasonCtrl.text.trim()}',
                    'Your schedule change request has been submitted!\n\n'
                        '📚 Subject: ${subjectCtrl.text.trim()}\n📅 From: $currentDate\n📅 To: $newDate  ⏰ $newTime\n📝 Reason: ${reasonCtrl.text.trim()}\n\n'
                        'The admin will review and confirm the new schedule.\n\n📋 Status: Pending Admin Approval',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.moderate),
              ),
            ],
          )),
    ),
    ),
    );
  }

  Future<void> _showAdvanceClassDialog() async {
    final subjectCtrl = TextEditingController();
    final reasonCtrl  = TextEditingController();
    String? originalDate, advDate, advTime;
    await _showAnimated((dCtx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: _dialogTitle('Advance Class', Icons.event_available_outlined, AppColors.available),
            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Subject / Class to Advance *'), const SizedBox(height: 6),
                _field(subjectCtrl, 'e.g. CS101 – BSCS 1-A', Icons.book_outlined),
                const SizedBox(height: 14),
                _lbl('Original Scheduled Date *'), const SizedBox(height: 6),
                _tile(originalDate ?? 'Tap to select original date', Icons.event_outlined, originalDate == null,
                        () async { final v = await _pickDate(ctx, title: 'Original Scheduled Date'); if (v != null) ss(() => originalDate = v); }),
                const SizedBox(height: 14),
                _lbl('Advance To — New Date *'), const SizedBox(height: 6),
                _tile(advDate ?? 'Tap to select advance date', Icons.event_available_outlined, advDate == null,
                        () async { final v = await _pickDate(ctx, title: 'Advance to Date'); if (v != null) ss(() => advDate = v); }),
                const SizedBox(height: 14),
                _lbl('New Class Time *'), const SizedBox(height: 6),
                _tile(advTime ?? 'Tap to select new time', Icons.access_time_outlined, advTime == null,
                        () async { final v = await _pickTime(ctx, title: 'New Class Time'); if (v != null) ss(() => advTime = v); }),
                const SizedBox(height: 14),
                _lbl('Reason for Advancing *'), const SizedBox(height: 6),
                _textarea(reasonCtrl, 'e.g. Holiday on original date, special event...'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
              ElevatedButton.icon(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty || originalDate == null || advDate == null || advTime == null || reasonCtrl.text.trim().isEmpty) {
                    _snack('Please fill in all fields.'); return;
                  }
                  Navigator.pop(dCtx);
                  _sendStructured(
                    '⏩ ADVANCE CLASS REQUEST\n\n📚 Subject: ${subjectCtrl.text.trim()}\n📅 Original: $originalDate\n📅 Advance To: $advDate  ⏰ $advTime\n📝 Reason: ${reasonCtrl.text.trim()}',
                    'Your advance class request has been submitted!\n\n'
                        '📚 Subject: ${subjectCtrl.text.trim()}\n📅 Original Date: $originalDate\n📅 New Date: $advDate  ⏰ $advTime\n📝 Reason: ${reasonCtrl.text.trim()}\n\n'
                        'The admin will confirm the room and updated schedule.\n\n📋 Status: Pending Admin Approval',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.available),
              ),
            ],
          )),
    ),
    ),
    );
  }

  Future<void> _showCancelClassDialog() async {
    final subjectCtrl = TextEditingController();
    final reasonCtrl  = TextEditingController();
    String? date, time;
    await _showAnimated((dCtx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: _dialogTitle('Cancel Class', Icons.event_busy_outlined, AppColors.conflict),
            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Cancellations require admin approval. Students will be notified once approved.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.darkGray),
                    )),
                  ]),
                ),
                const SizedBox(height: 14),
                _lbl('Subject / Class to Cancel *'), const SizedBox(height: 6),
                _field(subjectCtrl, 'e.g. CS202 – BSCS 3-A', Icons.book_outlined),
                const SizedBox(height: 14),
                _lbl('Date of Class *'), const SizedBox(height: 6),
                _tile(date ?? 'Tap to select date', Icons.calendar_today_outlined, date == null,
                        () async { final v = await _pickDate(ctx, title: 'Date of Class'); if (v != null) ss(() => date = v); }),
                const SizedBox(height: 14),
                _lbl('Class Time *'), const SizedBox(height: 6),
                _tile(time ?? 'Tap to select time', Icons.access_time_outlined, time == null,
                        () async { final v = await _pickTime(ctx, title: 'Class Time'); if (v != null) ss(() => time = v); }),
                const SizedBox(height: 14),
                _lbl('Reason for Cancellation *'), const SizedBox(height: 6),
                _textarea(reasonCtrl, 'e.g. Holiday, no available room, personal emergency...'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
              ElevatedButton.icon(
                onPressed: () {
                  if (subjectCtrl.text.trim().isEmpty || date == null || time == null || reasonCtrl.text.trim().isEmpty) {
                    _snack('Please fill in all fields.'); return;
                  }
                  Navigator.pop(dCtx);
                  _sendStructured(
                    '❌ CANCEL CLASS REQUEST\n\n📚 Subject: ${subjectCtrl.text.trim()}\n📅 Date: $date  ⏰ $time\n📝 Reason: ${reasonCtrl.text.trim()}',
                    'Your class cancellation has been submitted.\n\n'
                        '📚 Subject: ${subjectCtrl.text.trim()}\n📅 Date: $date  ⏰ $time\n📝 Reason: ${reasonCtrl.text.trim()}\n\n'
                        'Students will be notified once the admin approves.\n\n⚠️ Status: Pending Admin Approval',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.conflict),
              ),
            ],
          )),
    ),
    ),
    );
  }

  Future<void> _showRoomInfoDialog() async {
    final roomCtrl    = TextEditingController();
    final purposeCtrl = TextEditingController();
    String? date, time;
    await _showAnimated((dCtx) => StatefulBuilder(builder: (ctx, ss) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: _dialogTitle('Room Info / Request', Icons.meeting_room_outlined, AppColors.red),
            content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lbl('Room Name / Number *'), const SizedBox(height: 6),
                _field(roomCtrl, 'e.g. 2F, LAB-301, LEC-201', Icons.meeting_room_outlined),
                const SizedBox(height: 14),
                _lbl('Preferred Date *'), const SizedBox(height: 6),
                _tile(date ?? 'Tap to select date', Icons.calendar_today_outlined, date == null,
                        () async { final v = await _pickDate(ctx, title: 'Preferred Date'); if (v != null) ss(() => date = v); }),
                const SizedBox(height: 14),
                _lbl('Preferred Time *'), const SizedBox(height: 6),
                _tile(time ?? 'Tap to select time', Icons.access_time_outlined, time == null,
                        () async { final v = await _pickTime(ctx, title: 'Preferred Time'); if (v != null) ss(() => time = v); }),
                const SizedBox(height: 14),
                _lbl('Purpose / Subject *'), const SizedBox(height: 6),
                _textarea(purposeCtrl, 'e.g. Make-up class for CS101, special lab session...'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text('Cancel', style: GoogleFonts.inter())),
              ElevatedButton.icon(
                onPressed: () {
                  if (roomCtrl.text.trim().isEmpty || date == null || time == null || purposeCtrl.text.trim().isEmpty) {
                    _snack('Please fill in all fields.'); return;
                  }
                  Navigator.pop(dCtx);
                  _sendStructured(
                    '🏫 ROOM REQUEST\n\n🚪 Room: ${roomCtrl.text.trim()}\n📅 Date: $date  ⏰ $time\n📝 Purpose: ${purposeCtrl.text.trim()}',
                    'Your room request has been forwarded to the admin.\n\n'
                        '🚪 Room: ${roomCtrl.text.trim()}\n📅 Date: $date  ⏰ $time\n📝 Purpose: ${purposeCtrl.text.trim()}\n\n'
                        'The admin will confirm availability and assign the room.\n\n📋 Status: Pending Admin Approval',
                  );
                },
                icon: const Icon(Icons.send, size: 16),
                label: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
              ),
            ],
          )),
    ),
    ),
    );
  }

  // ── Dialog helper widgets ─────────────────────────────────────────────────
  Widget _dialogTitle(String label, IconData icon, Color color) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 20),
    ),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
  ]);

  Widget _lbl(String t) => Text(t,
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray));

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c,
    style: GoogleFonts.inter(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, size: 18, color: AppColors.lightGray),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  Widget _textarea(TextEditingController c, String hint) => TextField(
    controller: c,
    maxLines: 3,
    style: GoogleFonts.inter(fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.all(12),
    ),
  );

  Widget _tile(String label, IconData icon, bool empty, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
                color: empty ? AppColors.borderGray : AppColors.red,
                width: empty ? 1 : 1.5),
            borderRadius: BorderRadius.circular(10),
            color: empty ? Colors.white : AppColors.red.withValues(alpha: 0.04),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: empty ? AppColors.lightGray : AppColors.red),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
                style: GoogleFonts.inter(fontSize: 13,
                    color: empty ? Colors.grey.shade400 : AppColors.darkGray))),
            if (!empty) const Icon(Icons.check_circle, size: 16, color: AppColors.available),
          ]),
        ),
      );

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: AppColors.conflict,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Routing ───────────────────────────────────────────────────────────────
  void _handleQuickReply(String keyword) {
    switch (keyword) {
      case 'absence':    _showAbsenceDialog();        break;
      case 'reschedule': _showScheduleChangeDialog();  break;
      case 'advance':    _showAdvanceClassDialog();    break;
      case 'cancel':     _showCancelClassDialog();     break;

    }
  }

  // ── Send helpers ──────────────────────────────────────────────────────────
  Future<void> _sendStructured(String userMsg, String botReply) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final teacher = appState.currentTeacher;
    if (teacher == null) return;

    setState(() {
      _localMessages.add(_ChatBubble(isBot: false, text: userMsg, time: DateTime.now()));
      _isSending = true;
    });
    _saveHistory(appState, teacher.id);
    _scrollDown();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    setState(() {
      _localMessages.add(_ChatBubble(isBot: true, text: botReply, time: DateTime.now(), isRequest: true));
      _isSending = false;
    });

    appState.sendChatMessage(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: teacher.id,
      senderName: teacher.fullName,
      message: userMsg,
      isFromTeacher: true,
      timestamp: DateTime.now(),
      isResolved: false,
    ));
    _saveHistory(appState, teacher.id);
    _scrollDown();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final teacher = appState.currentTeacher;
    if (teacher == null) return;

    setState(() {
      _localMessages.add(_ChatBubble(isBot: false, text: text.trim(), time: DateTime.now()));
      _isSending = true;
    });
    _msgController.clear();
    _saveHistory(appState, teacher.id);
    _scrollDown();

    await Future.delayed(const Duration(milliseconds: 1200));
    final response = _generateResponse(text.trim().toLowerCase());

    if (!mounted) return;
    setState(() {
      _localMessages.add(_ChatBubble(
          isBot: true, text: response.message, time: DateTime.now(), isRequest: response.isRequest));
      _isSending = false;
    });

    if (response.isRequest) {
      appState.sendChatMessage(ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: teacher.id,
        senderName: teacher.fullName,
        message: text.trim(),
        isFromTeacher: true,
        timestamp: DateTime.now(),
        isResolved: false,
      ));
    }
    _saveHistory(appState, teacher.id);
    _scrollDown();
  }

  _BotResponse _generateResponse(String msg) {
    if (msg.contains('absent') || msg.contains('sick') || msg.contains('emergency') || msg.contains('absence'))
      return _BotResponse(message: 'To report an absence, tap the "Report Absence" button below to fill in the subject, date, time, and reason.', isRequest: false);
    if (msg.contains('reschedule') || msg.contains('schedule change') || msg.contains('move') || msg.contains('transfer'))
      return _BotResponse(message: 'To request a schedule change, tap "Schedule Change" below and provide the class details, new date/time, and reason.', isRequest: false);
    if (msg.contains('advance'))
      return _BotResponse(message: 'To advance a class, tap "Advance Class" below and fill in the subject, original date, new date/time, and reason.', isRequest: false);
    if (msg.contains('cancel'))
      return _BotResponse(message: 'To cancel a class, tap "Cancel Class" below and provide the subject, date, time, and reason.', isRequest: false);

    // Greetings and unrelated messages — redirect only, never log to admin
    return _BotResponse(
      message: 'Hi! 👋 I can only assist with scheduling concerns.\n\nPlease use the quick buttons below:\n• 🤒 Report Absence\n• 🔄 Schedule Change\n• ⏩ Advance Class\n• ❌ Cancel Class',
      isRequest: false,
    );
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final teacher = state.currentTeacher;
      final myMessages = teacher != null
          ? state.chatMessages.where((m) => m.senderId == teacher.id).toList()
          : <ChatMessage>[];

      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          title: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withValues(alpha: 0.6), width: 1.5),
              ),
              child: ClipOval(child: Image.asset('assets/images/css_logo.png', fit: BoxFit.cover)),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Schedule Assistant', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              Text('AI-powered support',  style: GoogleFonts.inter(fontSize: 10, color: Colors.white60)),
            ]),
          ]),
          actions: [
            // ＋ New chat button
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
              tooltip: 'New Chat',
              onPressed: _startNewChat,
            ),
            // History button — only when teacher has sent requests
            if (myMessages.isNotEmpty)
              Stack(children: [
                IconButton(icon: const Icon(Icons.history_outlined), onPressed: () => _showHistory(context, myMessages)),
                Positioned(right: 8, top: 8, child: Container(width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle))),
              ]),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(children: [
          // Animated background logo
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowCtrl, _ringCtrl]),
              builder: (context, _) => Center(child: Stack(alignment: Alignment.center, children: [
                // Outer red dashed ring — rotates clockwise
                Transform.rotate(
                    angle: _ringAnim.value * 2 * 3.14159265,
                    child: CustomPaint(size: const Size(340, 340),
                        painter: _ChatRingPainter(color: const Color(0xFFCC0000), opacity: 0.55))),
                // Inner grey dashed ring — rotates counter-clockwise
                Transform.rotate(
                    angle: -_ringAnim.value * 2 * 3.14159265 * 0.65,
                    child: CustomPaint(size: const Size(295, 295),
                        painter: _ChatRingPainter(color: const Color(0xFFAAAAAA), opacity: 0.30))),
                // Pulsing red glow halo behind the logo
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCC0000).withValues(alpha: 0.55),
                        blurRadius: _glowAnim.value,
                        spreadRadius: _glowAnim.value * 0.18,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF2222).withValues(alpha: 0.25),
                        blurRadius: _glowAnim.value * 0.4,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                // Logo — completely static, no rotation
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFCC0000).withValues(alpha: 0.35), width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/css_logo.png', fit: BoxFit.cover),
                  ),
                ),
              ])),
            ),
          ),

          // Chat UI
          Column(children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _localMessages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isSending && i == _localMessages.length) return const _TypingIndicator();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MessageBubble(bubble: _localMessages[i]),
                  );
                },
              ),
            ),

            // Quick replies — always visible above the input bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Text('Quick Actions',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                            letterSpacing: 1.0)),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final qr = _quickReplies[i];
                        const chipColors = [
                          Color(0xFFEF5350), // Report Absence — red
                          Color(0xFFFF7043), // Schedule Change — deep orange
                          Color(0xFF43A047), // Advance Class   — green
                          Color(0xFFFFA726), // Cancel Class    — amber
                          Color(0xFF42A5F5), // Room Info       — blue
                        ];
                        final color = chipColors[i % chipColors.length];
                        return GestureDetector(
                          onTap: () => _handleQuickReply(qr.keyword),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.45),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(qr.icon, size: 12, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(qr.label,
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: SafeArea(
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      maxLines: null,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your message or concern...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white38),
                        filled: true, fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(_msgController.text),
                    child: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: AppColors.red.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                      ]),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ]),
      );
    });
  }

  void _showHistory(BuildContext context, List<ChatMessage> messages) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('Request History', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final msg = messages[i];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(DateFormat('MMM d, h:mm a').format(msg.timestamp),
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.lightGray)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: msg.isResolved ? AppColors.available.withValues(alpha: 0.1) : AppColors.moderate.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(msg.isResolved ? 'Resolved' : 'Pending',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                          color: msg.isResolved ? AppColors.available : AppColors.moderate)),
                ),
              ]),
              const SizedBox(height: 6),
              Text(msg.message, style: GoogleFonts.inter(fontSize: 13)),
              if (msg.adminResponse != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 14, color: AppColors.red),
                    const SizedBox(width: 6),
                    Expanded(child: Text(msg.adminResponse!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.red))),
                  ]),
                ),
              ],
            ]);
          },
        )),
      ]),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatBubble bubble;
  const _MessageBubble({required this.bubble});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: bubble.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (bubble.isBot) ...[
          Container(width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withValues(alpha: 0.5), width: 1.5)),
            child: ClipOval(child: Image.asset('assets/images/css_logo.png', fit: BoxFit.cover)),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubble.isBot ? Colors.white.withValues(alpha: 0.50) : AppColors.darkGray.withValues(alpha: 0.50),
              border: bubble.isBot ? Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1) : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(bubble.isBot ? 4 : 16),
                bottomRight: Radius.circular(bubble.isBot ? 16 : 4),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bubble.text, style: GoogleFonts.inter(fontSize: 13,
                  color: bubble.isBot ? const Color(0xFF1A1A1A) : Colors.white, height: 1.5)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat('h:mm a').format(bubble.time),
                    style: GoogleFonts.inter(fontSize: 9,
                        color: bubble.isBot ? Colors.grey.shade400 : Colors.white60)),
                if (bubble.isRequest) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.send, size: 10, color: bubble.isBot ? AppColors.red : Colors.white60),
                ],
              ]),
            ]),
          ),
        ),
        if (!bubble.isBot) const SizedBox(width: 8),
      ],
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
      Future.delayed(Duration(milliseconds: i * 150), () { if (mounted) c.repeat(reverse: true); });
      return c;
    });
  }

  @override void dispose() { for (final c in _controllers) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(width: 32, height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: AppColors.red.withValues(alpha: 0.5), width: 1.5)),
        child: ClipOval(child: Image.asset('assets/images/css_logo.png', fit: BoxFit.cover)),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.50),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
            AnimatedBuilder(animation: _controllers[i], builder: (_, __) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6, height: 6 + (_controllers[i].value * 6),
              decoration: BoxDecoration(color: AppColors.darkGray.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)),
            )),
        )),
      ),
    ]);
  }
}

// ── Dashed ring painter ───────────────────────────────────────────────────────
class _ChatRingPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _ChatRingPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()..color = color.withValues(alpha: opacity)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    const dashCount = 20;
    const dashAngle = 3.14159265 * 2 / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * dashAngle, dashAngle * 0.65, false, paint);
    }
  }

  @override bool shouldRepaint(_) => false;
}

// ── Data models ───────────────────────────────────────────────────────────────
class _BotResponse {
  final String message;
  final bool isRequest;
  const _BotResponse({required this.message, required this.isRequest});
}

class _ChatBubble {
  final bool isBot;
  final String text;
  final DateTime time;
  final bool isRequest;
  final bool isAdminResponse;
  const _ChatBubble({
    required this.isBot,
    required this.text,
    required this.time,
    this.isRequest = false,
    this.isAdminResponse = false,
  });

  Map<String, dynamic> toMap() => {
    'isBot': isBot, 'text': text,
    'time': time.millisecondsSinceEpoch,
    'isRequest': isRequest,
    'isAdminResponse': isAdminResponse,
  };

  static _ChatBubble fromMap(Map<String, dynamic> m) => _ChatBubble(
    isBot: m['isBot'] as bool,
    text: m['text'] as String,
    time: DateTime.fromMillisecondsSinceEpoch(m['time'] as int),
    isRequest: (m['isRequest'] as bool?) ?? false,
    isAdminResponse: (m['isAdminResponse'] as bool?) ?? false,
  );
}

class _QuickReply {
  final String label;
  final IconData icon;
  final String keyword;
  const _QuickReply(this.label, this.icon, this.keyword);
}