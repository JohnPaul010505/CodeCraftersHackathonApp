// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final isAdmin = state.isAdmin;
      final teacher = state.currentTeacher;

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('Settings',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        body: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile banner ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.darkGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings_outlined
                                    : Icons.person_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdmin
                                        ? 'Administrator'
                                        : teacher?.fullName ?? 'Teacher',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAdmin
                                        ? 'Full system access'
                                        : teacher?.department ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : 'Teacher',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _sectionLabel('APPLICATION'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: kCardDecoration(),
                        child: Column(children: [
                          _Tile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Alerts and conflict warnings',
                            onTap: () {},
                            isFirst: true,
                          ),
                          const Divider(height: 1, color: AppColors.borderGray, indent: 54),
                          _Tile(
                            icon: Icons.language_outlined,
                            title: 'Language',
                            subtitle: 'English',
                            onTap: () {},
                            isLast: true,
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      _sectionLabel('DATA & PRIVACY'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: kCardDecoration(),
                        child: Column(children: [
                          _Tile(
                            icon: Icons.backup_outlined,
                            title: 'Backup & Restore',
                            subtitle: 'Export all system data',
                            onTap: () {},
                            isFirst: true,
                          ),
                          const Divider(height: 1, color: AppColors.borderGray, indent: 54),
                          _Tile(
                            icon: Icons.security_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'View data usage policy',
                            onTap: () {},
                            isLast: true,
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      _sectionLabel('SUPPORT'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: kCardDecoration(),
                        child: Column(children: [
                          _Tile(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'User guide and FAQs',
                            onTap: () {},
                            isFirst: true,
                          ),
                          const Divider(height: 1, color: AppColors.borderGray, indent: 54),
                          _Tile(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'Version 1.0.0 · Build 100',
                            onTap: () => _showAbout(ctx),
                            isLast: true,
                          ),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // Sign out
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmLogout(ctx, state),
                          icon: const Icon(Icons.logout, size: 18),
                          label: Text('Sign Out',
                              style: GoogleFonts.inter(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.conflict,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'Smart Academic Scheduling System\nVersion 1.0.0 · Build 100',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.lightGray,
                              height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: AppColors.lightGray,
      letterSpacing: 0.8,
    ),
  );

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.logout, color: AppColors.conflict, size: 20),
          const SizedBox(width: 10),
          Text('Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ]),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.midGray)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await FirebaseAuth.instance.signOut();
              state.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.conflict),
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  color: AppColors.red, size: 30),
            ),
            const SizedBox(height: 14),
            Text('Smart Academic\nScheduling System',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.darkGray)),
            const SizedBox(height: 6),
            Text('Version 1.0.0',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.lightGray)),
            const SizedBox(height: 12),
            Text(
              'Automated scheduling for academic institutions. Eliminates conflicts and monitors room availability in real-time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.midGray, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGray),
            child: Text('Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(11) : Radius.zero,
      bottom: isLast ? const Radius.circular(11) : Radius.zero,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.midGray),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkGray)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.lightGray)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.lightGray),
          ],
        ),
      ),
    );
  }
}