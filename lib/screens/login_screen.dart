import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'admin_shell.dart';
import 'teacher_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
            CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 14.0, end: 38.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat();
    _ringAnim = Tween<double>(begin: 0, end: 1.0).animate(_ringCtrl);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _login() async {
    _safeSetState(() {
      _isLoading = false;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    _safeSetState(() => _isLoading = true);

    try {
      await (_isAdmin ? _loginAdmin() : _loginTeacher())
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw Exception(
              'Request timed out. Check your connection and try again.');
        },
      );
    } on FirebaseAuthException catch (e) {
      _safeSetState(() => _errorMessage = _friendlyAuthError(e.code));
    } catch (e) {
      _safeSetState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _loginAdmin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ── Local bypass (admin / admin123) ───────────────────────────────────
    if (email == 'admin' && password == 'admin123') {
      if (!mounted) return;
      Provider.of<AppState>(context, listen: false).setAdminLoggedIn();
      Navigator.pushReplacement(context, _fadeRoute(const AdminShell()));
      return;
    }

    // ── Firebase auth ─────────────────────────────────────────────────────
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    final role = doc.data()?['role'] ?? 'teacher';

    if (role != 'admin') {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _safeSetState(
              () => _errorMessage = 'This account is not an Administrator.');
      return;
    }

    if (!mounted) return;
    Provider.of<AppState>(context, listen: false).setAdminLoggedIn();
    Navigator.pushReplacement(context, _fadeRoute(const AdminShell()));
  }

  Future<void> _loginTeacher() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final appState = Provider.of<AppState>(context, listen: false);

    // ── Step 1: Check local mock teachers ────────────────────────────────
    final localMatch = appState.teachers
        .where((t) => t.email == email && t.password == password)
        .toList();

    if (localMatch.isNotEmpty) {
      if (!mounted) return;
      appState.setTeacherLoggedInFromFirestore(
        localMatch.first.id,
        {
          'firstName': localMatch.first.firstName,
          'lastName': localMatch.first.lastName,
          'email': localMatch.first.email,
          'employeeId': localMatch.first.employeeId,
          'department': localMatch.first.department,
          'expertise': localMatch.first.expertise,
          'unitType': localMatch.first.unitType,
          'maxUnits': localMatch.first.maxUnits,
          'currentUnits': localMatch.first.currentUnits,
          'availableDays': localMatch.first.availableDays,
          'availableTimeStart': localMatch.first.availableTimeStart,
          'availableTimeEnd': localMatch.first.availableTimeEnd,
        },
      );
      Navigator.pushReplacement(
          context, _fadeRoute(const TeacherDashboardScreen()));
      return;
    }

    // ── Step 2: Check Firestore teachers directly (no Firebase Auth needed)
    // Handles any teacher added by admin through the app — no Firebase
    // Console setup required for new teachers ever again.
    final firestoreSnap = await FirebaseFirestore.instance
        .collection('teachers')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (firestoreSnap.docs.isNotEmpty) {
      if (!mounted) return;
      appState.setTeacherLoggedInFromFirestore(
          firestoreSnap.docs.first.id, firestoreSnap.docs.first.data());
      Navigator.pushReplacement(
          context, _fadeRoute(const TeacherDashboardScreen()));
      return;
    }

    // ── Step 3: Fall back to Firebase Auth ───────────────────────────────
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final snap = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isNotEmpty) {
        appState.setTeacherLoggedInFromFirestore(
            snap.docs.first.id, snap.docs.first.data());
      } else {
        appState.setTeacherLoggedInFromFirebase(
          uid: credential.user!.uid,
          email: email,
          displayName:
          credential.user!.displayName ?? email.split('@').first,
        );
      }

      Navigator.pushReplacement(
          context, _fadeRoute(const TeacherDashboardScreen()));
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e.code));
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Wait a moment, then try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      case 'operation-not-allowed':
        return 'Sign-in is currently disabled. Contact your admin.';
      default:
        return 'Sign in failed ($code). Please try again.';
    }
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogoSection(),
                      const SizedBox(height: 36),
                      _buildLoginCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _ringCtrl]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _ringAnim.value * 2 * 3.14159265,
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _DashedRingPainter(
                    color: const Color(0xFFCC0000), opacity: 0.4),
              ),
            ),
            Transform.rotate(
              angle: -_ringAnim.value * 2 * 3.14159265 * 0.7,
              child: CustomPaint(
                size: const Size(126, 126),
                painter: _DashedRingPainter(
                    color: const Color(0xFF888888), opacity: 0.25),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCC0000).withValues(alpha: 0.55),
                    blurRadius: _glowAnim.value,
                    spreadRadius: _glowAnim.value * 0.2,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF2222).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFCC0000).withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/css_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCC0000).withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Global Reciprocal College Scheduling',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1a1a1a),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to manage your schedules',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),

              // Role toggle
              Text('Login as',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    _roleTab(
                      label: 'ADMINISTRATOR',
                      icon: Icons.admin_panel_settings_outlined,
                      isSelected: _isAdmin,
                      onTap: () => _switchRole(true),
                    ),
                    _roleTab(
                      label: 'TEACHER',
                      icon: Icons.school_outlined,
                      isSelected: !_isAdmin,
                      onTap: () => _switchRole(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Email *',
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFCC0000), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFFCC0000)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFCC0000), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                // ── FIXED: allow 'admin' as a special case ──────────────
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (v.trim() == 'admin') return null; // local bypass
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFCC0000), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                    const BorderSide(color: Color(0xFFCC0000)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFFCC0000), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFCC0000).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFCC0000)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFCC0000), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFCC0000)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _safeSetState(() => _errorMessage = null),
                        child: const Icon(Icons.close,
                            color: Color(0xFFCC0000), size: 16),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a1a1a),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    const Color(0xFF1a1a1a).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text('Signing in...',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70)),
                    ],
                  )
                      : Text(
                    'Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _isAdmin
                    ? 'Administrator accounts are managed by the system.'
                    : 'Teacher accounts are created by your Administrator.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchRole(bool isAdmin) {
    setState(() {
      _isAdmin = isAdmin;
      _emailController.clear();
      _passwordController.clear();
      _errorMessage = null;
      _isLoading = false;
    });
  }

  Widget _roleTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF1a1a1a)
                      : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1a1a1a)
                      : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double opacity;
  const _DashedRingPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashCount = 18;
    const dashAngle = 3.14159265 * 2 / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * 0.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

