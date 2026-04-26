import 'package:flutter/material.dart';
import 'teacher_chatbot_screen.dart';

/// Shown when the teacher taps the chat FAB.
/// Logo-only splash — same animations as SplashScreen, navigates to chatbot.
class ChatbotSplashScreen extends StatefulWidget {
  const ChatbotSplashScreen({super.key});

  @override
  State<ChatbotSplashScreen> createState() => _ChatbotSplashScreenState();
}

class _ChatbotSplashScreenState extends State<ChatbotSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgFadeCtrl;
  late AnimationController _logoScaleCtrl;
  late AnimationController _logoRotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _bgFadeAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoRotateAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _bgFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _bgFadeAnim =
        CurvedAnimation(parent: _bgFadeCtrl, curve: Curves.easeIn);

    _logoScaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoScaleCtrl, curve: Curves.elasticOut));

    _logoRotateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoRotateAnim = Tween<double>(begin: -0.08, end: 0.0).animate(
        CurvedAnimation(parent: _logoRotateCtrl, curve: Curves.easeOutBack));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 18.0, end: 50.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _ringAnim = Tween<double>(begin: 0, end: 1.0).animate(_ringCtrl);

    _runSequence();
  }

  Future<void> _runSequence() async {
    _bgFadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _logoScaleCtrl.forward();
    _logoRotateCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _goToChatbot();
  }

  void _goToChatbot() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const TeacherChatbotScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final fade =
          CurvedAnimation(parent: animation, curve: Curves.easeIn);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgFadeCtrl.dispose();
    _logoScaleCtrl.dispose();
    _logoRotateCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _bgFadeAnim,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [
                Color(0xFF2B0000),
                Color(0xFF1C1C1C),
                Color(0xFF080808),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation:
                Listenable.merge([_glowCtrl, _pulseCtrl, _ringCtrl]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning outer dashed ring
                      Transform.rotate(
                        angle: _ringAnim.value * 2 * 3.14159265,
                        child: CustomPaint(
                          size: const Size(230, 230),
                          painter: _SplashRingPainter(
                            color: const Color(0xFFCC0000),
                            opacity: 0.35,
                          ),
                        ),
                      ),
                      // Counter-spinning second ring
                      Transform.rotate(
                        angle:
                        -_ringAnim.value * 2 * 3.14159265 * 0.6,
                        child: CustomPaint(
                          size: const Size(210, 210),
                          painter: _SplashRingPainter(
                            color: const Color(0xFF888888),
                            opacity: 0.2,
                          ),
                        ),
                      ),
                      // Glow halo
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCC0000)
                                  .withValues(alpha: 0.6),
                              blurRadius: _glowAnim.value,
                              spreadRadius: _glowAnim.value * 0.25,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF1111)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // CSS logo — elastic pop + rotation + pulse
                      ScaleTransition(
                        scale: _logoScaleAnim,
                        child: RotationTransition(
                          turns: _logoRotateAnim,
                          child: Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCC0000)
                                      .withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/css_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed spinning ring painter ──────────────────────────────────────────────
class _SplashRingPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _SplashRingPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashCount = 20;
    const dashAngle = 3.14159265 * 2 / dashCount;
    const gapFraction = 0.35;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * (1 - gapFraction),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashRingPainter old) =>
      old.color != color || old.opacity != opacity;
}