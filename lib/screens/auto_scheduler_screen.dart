import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/teacher.dart';
import '../theme/app_theme.dart';

class AutoSchedulerScreen extends StatefulWidget {
  const AutoSchedulerScreen({super.key});

  @override
  State<AutoSchedulerScreen> createState() => _AutoSchedulerScreenState();
}

class _AutoSchedulerScreenState extends State<AutoSchedulerScreen>
    with TickerProviderStateMixin {
  bool _isRunning = false;
  bool _isDone = false;
  int _generatedCount = 0;
  double _progress = 0;
  String _statusMessage = 'Ready to generate schedule';
  late AnimationController _pulseController;

  final List<String> _steps = [
    'Analyzing teacher availability...',
    'Matching subject requirements...',
    'Checking room equipment compatibility...',
    'Assigning time slots...',
    'Running conflict detection...',
    'Optimizing schedule distribution...',
    'Finalizing semester schedule...',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runAutoScheduler() async {
    setState(() {
      _isRunning = true;
      _isDone = false;
      _progress = 0;
      _currentStep = 0;
      _statusMessage = _steps[0];
    });

    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _currentStep = i;
        _statusMessage = _steps[i];
        _progress = (i + 1) / _steps.length;
      });
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final count = await appState.runAutoScheduler();

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isDone = true;
      _generatedCount = count;
      _statusMessage = 'Schedule generated successfully!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: const Text('Auto Scheduler'),
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.redDark, AppColors.redLight],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto Scheduling Engine',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'AI-powered semester schedule generator',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Automatically generates a complete conflict-free semester schedule by intelligently matching:',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Teacher expertise & availability',
                    'Subject type (Lab vs Lecture) requirements',
                    'Room equipment compatibility',
                    'Room capacity requirements',
                    'Time slot constraints',
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(item,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.white)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Progress
            if (_isRunning || _isDone) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isRunning)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.red,
                            ),
                          ),
                        if (_isDone)
                          const Icon(Icons.check_circle,
                              color: AppColors.available, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isDone
                                  ? AppColors.available
                                  : AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.bgGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isDone
                              ? AppColors.available
                              : AppColors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red,
                      ),
                    ),
                    if (_isRunning) ...[
                      const SizedBox(height: 16),
                      Column(
                        children: List.generate(_steps.length, (i) {
                          final done = i < _currentStep;
                          final active = i == _currentStep;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  done
                                      ? Icons.check_circle
                                      : active
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: done
                                      ? AppColors.available
                                      : active
                                          ? AppColors.red
                                          : Colors.grey.shade300,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _steps[i],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: done
                                        ? AppColors.available
                                        : active
                                            ? AppColors.red
                                            : Colors.grey.shade400,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Result
            if (_isDone) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.available.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.available.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.available.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.celebration,
                          color: AppColors.available, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Generated!',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.available,
                            ),
                          ),
                          Text(
                            '$_generatedCount schedule entries created successfully.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.available,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Generate button
            if (!_isRunning) ...[
              Consumer<AppState>(
                builder: (context, state, _) => Column(
                  children: [
                    // Pre-check
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pre-flight Checks',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          _checkRow('Teachers loaded',
                              state.teachers.isNotEmpty),
                          _checkRow(
                              'Rooms configured', state.rooms.isNotEmpty),
                          _checkRow('Subjects defined',
                              state.subjects.isNotEmpty),
                          _checkRow('Active teachers available',
                              state.teachers.any((t) =>
                                  t.status == TeacherStatus.active)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _runAutoScheduler,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          'Generate Semester Schedule',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? AppColors.available : AppColors.conflict,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: ok ? AppColors.darkGray : AppColors.conflict)),
        ],
      ),
    );
  }
}
