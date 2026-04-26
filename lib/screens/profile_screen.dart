// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final isAdmin = state.isAdmin;
      final teacher = state.currentTeacher;
      final displayName =
      isAdmin ? 'Administrator' : (teacher?.fullName ?? 'Teacher');
      final displayRole =
      isAdmin ? 'System Administrator' : (teacher?.department ?? 'Teacher');
      final displayEmail = isAdmin
          ? 'admin@university.edu'
          : (teacher?.email ?? '');

      return Scaffold(
        backgroundColor: AppColors.bgGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text('Profile',
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
                    children: [
                      // ── Profile header ───────────────────────────────────
                      Container(
                        decoration: kCardDecoration(),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.darkGray,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_outlined
                                          : Icons.person,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(displayName,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.darkGray,
                                            )),
                                        const SizedBox(height: 2),
                                        Text(displayRole,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.lightGray)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.available
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isAdmin ? 'Admin' : 'Teacher',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.available,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.borderGray),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.email_outlined,
                                      size: 14, color: AppColors.lightGray),
                                  const SizedBox(width: 10),
                                  Text(displayEmail,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppColors.midGray)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Settings group ───────────────────────────────────
                      _SectionLabel('SETTINGS'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: kCardDecoration(),
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Alerts and reminders',
                              onTap: () {},
                              isFirst: true,
                            ),
                            const Divider(height: 1, color: AppColors.borderGray, indent: 54),
                            _SettingsTile(
                              icon: Icons.shield_outlined,
                              title: 'Privacy & Security',
                              subtitle: 'Account security settings',
                              onTap: () {},
                            ),
                            const Divider(height: 1, color: AppColors.borderGray, indent: 54),
                            _SettingsTile(
                              icon: Icons.info_outline,
                              title: 'About',
                              subtitle: 'Smart Academic Scheduling System v1.0',
                              onTap: () => _showAbout(ctx),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Logout ───────────────────────────────────────────
                      Container(
                        decoration: kCardDecoration(),
                        child: ListTile(
                          contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.conflict.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.logout,
                                color: AppColors.conflict, size: 18),
                          ),
                          title: Text('Sign Out',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.conflict)),
                          subtitle: Text('Sign out of your account',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.lightGray)),
                          onTap: () => _confirmLogout(ctx, state),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Version ──────────────────────────────────────────
                      Text(
                        'Smart Academic Scheduling System\nVersion 1.0.0 · Spring 2026',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.lightGray, height: 1.6),
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

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school_outlined,
                  color: AppColors.red, size: 32),
            ),
            const SizedBox(height: 14),
            Text('Smart Academic\nScheduling System',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Version 1.0.0',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.lightGray)),
            const SizedBox(height: 12),
            Text(
              'An automated scheduling system designed to eliminate conflicts and provide real-time room availability monitoring.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.midGray, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGray),
            child: Text('Close',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.logout, color: AppColors.conflict, size: 20),
          const SizedBox(width: 10),
          Text('Sign Out',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700)),
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
}

// ── Reusable section label ───────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.lightGray,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Settings tile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
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
                size: 18, color: AppColors.lightGray),
          ],
        ),
      ),
    );
  }
}