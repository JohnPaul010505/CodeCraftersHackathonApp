import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _bgFadeCtrl;
  late AnimationController _logoScaleCtrl;
  late AnimationController _logoRotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _textSlideCtrl;
  late AnimationController _loadingCtrl;
  late AnimationController _ringCtrl;

  // ── Animations ────────────────────────────────────────────────────────────
  late Animation<double> _bgFadeAnim;
  late Animation<double> _logoScaleAnim;
  late Animation<double> _logoRotateAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _textFadeAnim;
  late Animation<double> _loadingAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    // 1. Background radial gradient fade in
    _bgFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _bgFadeAnim =
        CurvedAnimation(parent: _bgFadeCtrl, curve: Curves.easeIn);

    // 2. Logo scale — elastic pop
    _logoScaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoScaleCtrl, curve: Curves.elasticOut));

    // 3. Logo slight rotation on entrance
    _logoRotateCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoRotateAnim = Tween<double>(begin: -0.08, end: 0.0).animate(
        CurvedAnimation(parent: _logoRotateCtrl, curve: Curves.easeOutBack));

    // 4. Continuous gentle pulse
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // 5. Glow radius breathing
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 18.0, end: 50.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // 6. "Welcome" text slide up + fade
    _textSlideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textSlideAnim = Tween<Offset>(
            begin: const Offset(0, 0.9), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textSlideCtrl, curve: Curves.easeOutCubic));
    _textFadeAnim =
        CurvedAnimation(parent: _textSlideCtrl, curve: Curves.easeIn);

    // 7. Loading progress bar
    _loadingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _loadingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loadingCtrl, curve: Curves.easeInOut));

    // 8. Spinning outer ring
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _ringAnim = Tween<double>(begin: 0, end: 1.0).animate(_ringCtrl);

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Step 1: Background fades in
    _bgFadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));

    // Step 2: Logo pops in with rotation
    _logoScaleCtrl.forward();
    _logoRotateCtrl.forward();

    // Step 3: Text slides up after logo settles
    await Future.delayed(const Duration(milliseconds: 500));
    _textSlideCtrl.forward();

    // Step 4: Loading bar starts
    await Future.delayed(const Duration(milliseconds: 200));
    _loadingCtrl.forward();

    // Step 5: Navigate after ~2.8 seconds total
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);
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
    _textSlideCtrl.dispose();
    _loadingCtrl.dispose();
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
                Color(0xFF2B0000), // dark red center
                Color(0xFF1C1C1C), // dark grey mid
                Color(0xFF080808), // near-black outer
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── Logo block ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation:
                      Listenable.merge([_glowCtrl, _pulseCtrl, _ringCtrl]),
                  builder: (context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Spinning outer decorative ring
                        Transform.rotate(
                          angle: _ringAnim.value * 2 * 3.14159265,
                          child: CustomPaint(
                            size: const Size(230, 230),
                            painter: _SpinningRingPainter(
                              color: const Color(0xFFCC0000),
                              opacity: 0.35,
                            ),
                          ),
                        ),

                        // Counter-spinning second ring (slower)
                        Transform.rotate(
                          angle: -_ringAnim.value * 2 * 3.14159265 * 0.6,
                          child: CustomPaint(
                            size: const Size(210, 210),
                            painter: _SpinningRingPainter(
                              color: const Color(0xFF888888),
                              opacity: 0.2,
                            ),
                          ),
                        ),

                        // Glow halo behind logo
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

                        // Logo itself
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

                const SizedBox(height: 52),

                // ── Welcome text ───────────────────────────────────────────
                SlideTransition(
                  position: _textSlideAnim,
                  child: FadeTransition(
                    opacity: _textFadeAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Flanking lines + Welcome
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _gradientLine(leftToRight: false),
                            const SizedBox(width: 16),
                            Text(
                              'Welcome',
                              style: GoogleFonts.poppins(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFCC0000)
                                        .withValues(alpha: 0.8),
                                    blurRadius: 16,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            _gradientLine(leftToRight: true),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Three decorative dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(const Color(0xFFCC0000), 8),
                            const SizedBox(width: 8),
                            _dot(const Color(0xFF666666), 5),
                            const SizedBox(width: 8),
                            _dot(const Color(0xFFCC0000), 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Loading bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 0),
                  child: FadeTransition(
                    opacity: _textFadeAnim,
                    child: Column(
                      children: [
                        // Track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedBuilder(
                            animation: _loadingAnim,
                            builder: (_, __) {
                              return LinearProgressIndicator(
                                value: _loadingAnim.value,
                                minHeight: 5,
                                backgroundColor: const Color(0xFF2A2A2A),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFCC0000),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedBuilder(
                          animation: _loadingAnim,
                          builder: (_, __) {
                            final pct =
                                (_loadingAnim.value * 100).toInt();
                            return Text(
                              pct < 100
                                  ? 'Loading... $pct%'
                                  : 'Ready',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF888888),
                                letterSpacing: 1.5,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Footer label ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: FadeTransition(
                    opacity: _textFadeAnim,
                    child: Text(
                      'Smart Academic Scheduling System',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF555555),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientLine({required bool leftToRight}) {
    return Container(
      width: 38,
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: leftToRight
              ? [const Color(0xFFCC0000), Colors.transparent]
              : [Colors.transparent, const Color(0xFFCC0000)],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

// ── Custom painter for spinning dashed ring ────────────────────────────────
class _SpinningRingPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _SpinningRingPainter({
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw dashed arc segments around the circle
    const dashCount = 20;
    const dashAngle = 3.14159265 * 2 / dashCount;
    const gapFraction = 0.35;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpinningRingPainter oldDelegate) => false;
}
