import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login_page.dart';
import 'admin_reading_page.dart';
import 'admin_writing_page.dart';
import 'admin_speaking_page.dart';
import 'admin_listening_page.dart';
import 'admin_users_page.dart';
import 'admin_results_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  int totalUsers = 0;
  int totalAdmins = 0;
  int writingQuestions = 0;
  int readingQuestions = 0;
  int speakingTopics = 0;
  int listeningQuestions = 0;

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final usersData = await supabase.from('profiles').select('id, role');
      final writingData = await supabase.from('writing_questions').select('id');

      final usersList = List<Map<String, dynamic>>.from(usersData as List);
      final writingList = List<Map<String, dynamic>>.from(writingData as List);

      if (!mounted) return;

      setState(() {
        totalUsers = usersList.length;
        totalAdmins = usersList
            .where((user) => (user['role'] ?? 'user').toString() == 'admin')
            .length;

        writingQuestions = writingList.length;

        readingQuestions = 0;
        speakingTopics = 0;
        listeningQuestions = 0;
      });
    } catch (e) {
      _showMessage("Dashboard load failed: ${e.toString()}");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: textColor),
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: lightPrimary,
                child: Icon(icon, color: primaryColor),
              ),
              const Spacer(),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: subTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: lightPrimary,
                  child: Icon(icon, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: subTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(
          Icons.logout,
          color: primaryColor,
          size: 20,
        ),
        label: const Text(
          "Logout",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: primaryColor,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final double contentWidth =
                    (screenWidth * 0.35).clamp(300.0, 520.0).toDouble();
                final bool isSmallScreen = screenWidth <= 320;

                return RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 18,
                      vertical: 18,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: lightPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "Manage IELTSync content, users, questions, and results from here.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.15,
                              children: [
                                _statCard(
                                  title: "Total Users",
                                  value: totalUsers,
                                  icon: Icons.people_outline,
                                  onTap: () =>
                                      _openPage(const AdminUsersPage()),
                                ),
                                _statCard(
                                  title: "Admins",
                                  value: totalAdmins,
                                  icon: Icons.admin_panel_settings_outlined,
                                  onTap: () =>
                                      _openPage(const AdminUsersPage()),
                                ),
                                _statCard(
                                  title: "Writing",
                                  value: writingQuestions,
                                  icon: Icons.edit_note,
                                  onTap: () =>
                                      _openPage(const AdminWritingPage()),
                                ),
                                _statCard(
                                  title: "Reading",
                                  value: readingQuestions,
                                  icon: Icons.menu_book_outlined,
                                  onTap: () =>
                                      _openPage(const AdminReadingPage()),
                                ),
                                _statCard(
                                  title: "Speaking",
                                  value: speakingTopics,
                                  icon: Icons.mic_none,
                                  onTap: () =>
                                      _openPage(const AdminSpeakingPage()),
                                ),
                                _statCard(
                                  title: "Listening",
                                  value: listeningQuestions,
                                  icon: Icons.headphones_outlined,
                                  onTap: () =>
                                      _openPage(const AdminListeningPage()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            const Text(
                              "Admin Actions",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _menuCard(
                              title: "Manage Users",
                              subtitle: "View users and update user roles",
                              icon: Icons.people_outline,
                              onTap: () => _openPage(const AdminUsersPage()),
                            ),
                            _menuCard(
                              title: "View Results",
                              subtitle: "Check user test results and scores",
                              icon: Icons.bar_chart_outlined,
                              onTap: () => _openPage(const AdminResultsPage()),
                            ),
                            const SizedBox(height: 18),
                            _logoutButton(),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}