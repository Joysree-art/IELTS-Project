import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminResultsPage extends StatefulWidget {
  const AdminResultsPage({super.key});

  @override
  State<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends State<AdminResultsPage> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> speakingResults = [];
  List<Map<String, dynamic>> readingResults = [];

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchUsersWithResults();
  }

  Future<void> _fetchUsersWithResults() async {
    setState(() => isLoading = true);

    try {
      final speakingData = await supabase
          .from('speaking_results')
          .select()
          .order('created_at', ascending: false);

      final readingData = await supabase
          .from('reading_scores')
          .select()
          .order('created_at', ascending: false);

      speakingResults = List<Map<String, dynamic>>.from(speakingData);
      readingResults = List<Map<String, dynamic>>.from(readingData);

      final userIds = [
        ...speakingResults.map((e) => e['user_id']?.toString()),
        ...readingResults.map((e) => e['user_id']?.toString()),
      ].where((id) => id != null && id.isNotEmpty).toSet().toList();

      if (userIds.isEmpty) {
        setState(() {
          users = [];
          isLoading = false;
        });
        return;
      }

      final profilesData = await supabase
          .from('profiles')
          .select('id, full_name, email, avatar_url')
          .inFilter('id', userIds);

      users = List<Map<String, dynamic>>.from(profilesData);
    } catch (e) {
      _showMessage("Failed to load results: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  int _speakingCountForUser(String userId) {
    return speakingResults.where((r) => r['user_id'].toString() == userId).length;
  }

  int _readingCountForUser(String userId) {
    return readingResults.where((r) => r['user_id'].toString() == userId).length;
  }

  String _latestScoreForUser(String userId) {
    final userSpeaking = speakingResults
        .where((r) => r['user_id'].toString() == userId)
        .map((e) => {...e, 'type': 'speaking'})
        .toList();

    final userReading = readingResults
        .where((r) => r['user_id'].toString() == userId)
        .map((e) => {...e, 'type': 'reading'})
        .toList();

    final all = [...userSpeaking, ...userReading];

    if (all.isEmpty) return "-";

    all.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final latest = all.first;

    if (latest['type'] == 'reading') {
      return latest['band_score']?.toString() ?? "-";
    }

    return latest['score']?.toString() ?? "-";
  }

  void _openUserDetails(Map<String, dynamic> user) {
    final userId = user['id'].toString();

    final userSpeakingResults =
        speakingResults.where((r) => r['user_id'].toString() == userId).toList();

    final userReadingResults =
        readingResults.where((r) => r['user_id'].toString() == userId).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserResultDetailsPage(
          user: user,
          speakingResults: userSpeakingResults,
          readingResults: userReadingResults,
        ),
      ),
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

  Widget _userCard(Map<String, dynamic> user) {
    final userId = user['id'].toString();
    final name = user['full_name']?.toString().trim();
    final email = user['email']?.toString() ?? '';
    final avatarUrl = user['avatar_url']?.toString();

    final speakingCount = _speakingCountForUser(userId);
    final readingCount = _readingCountForUser(userId);
    final latestScore = _latestScoreForUser(userId);

    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openUserDetails(user),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: lightPrimary,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar
                      ? const Icon(Icons.person, color: primaryColor)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name == null || name.isEmpty ? "Unknown User" : name,
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: subTextColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Speaking: $speakingCount  •  Reading: $readingCount",
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: lightPrimary,
                  child: Text(
                    latestScore,
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.people_outline, size: 55, color: primaryColor),
          SizedBox(height: 12),
          Text(
            "No users with results yet",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Users will appear here after saving results.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor),
          ),
        ],
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
        iconTheme: const IconThemeData(color: textColor),
        title: const Text(
          "Admin View Results",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchUsersWithResults,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final double contentWidth =
              (screenWidth * 0.35).clamp(300.0, 560.0).toDouble();

          return RefreshIndicator(
            onRefresh: _fetchUsersWithResults,
            color: primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: lightPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Users With Results (${users.length})",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      else if (users.isEmpty)
                        _emptyState()
                      else
                        ...users.map(_userCard),
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

class AdminUserResultDetailsPage extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> speakingResults;
  final List<Map<String, dynamic>> readingResults;

  const AdminUserResultDetailsPage({
    super.key,
    required this.user,
    required this.speakingResults,
    required this.readingResults,
  });

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  Widget _moduleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: enabled ? Colors.white : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: enabled ? lightPrimary : Colors.grey.shade300,
                  child: Icon(
                    icon,
                    color: enabled ? primaryColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: enabled ? textColor : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: enabled ? subTextColor : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  enabled ? Icons.arrow_forward_ios : Icons.lock_outline,
                  size: 16,
                  color: enabled ? primaryColor : Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = user['full_name']?.toString().trim();
    final email = user['email']?.toString() ?? '';
    final avatarUrl = user['avatar_url']?.toString();
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    final displayName = name == null || name.isEmpty ? "Unknown User" : name;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: const Text(
          "User Results",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width * 0.35)
                .clamp(300.0, 560.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: lightPrimary,
                        backgroundImage:
                            hasAvatar ? NetworkImage(avatarUrl) : null,
                        child: !hasAvatar
                            ? const Icon(Icons.person, color: primaryColor)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: subTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _moduleCard(
                  icon: Icons.mic,
                  title: "Speaking",
                  subtitle: "${speakingResults.length} results available",
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminSpeakingResultOnlyPage(
                          userName: displayName,
                          speakingResults: speakingResults,
                        ),
                      ),
                    );
                  },
                ),
                _moduleCard(
                  icon: Icons.menu_book,
                  title: "Reading",
                  subtitle: "${readingResults.length} results available",
                  enabled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminReadingResultOnlyPage(
                          userName: displayName,
                          readingResults: readingResults,
                        ),
                      ),
                    );
                  },
                ),
                _moduleCard(
                  icon: Icons.edit,
                  title: "Writing",
                  subtitle: "Coming soon",
                  enabled: false,
                ),
                _moduleCard(
                  icon: Icons.headphones,
                  title: "Listening",
                  subtitle: "Coming soon",
                  enabled: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminSpeakingResultOnlyPage extends StatelessWidget {
  final String userName;
  final List<Map<String, dynamic>> speakingResults;

  const AdminSpeakingResultOnlyPage({
    super.key,
    required this.userName,
    required this.speakingResults,
  });

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  String _safeText(dynamic value) {
    if (value == null) return "N/A";
    if (value.toString().trim().isEmpty) return "N/A";
    return value.toString();
  }

  Widget _smallScoreBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: lightPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "$title: $value",
        style: const TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _speakingResultCard(Map<String, dynamic> item) {
    final part = _safeText(item['part']);
    final topic = _safeText(item['topic']);
    final transcript = _safeText(item['transcript']);
    final feedback = _safeText(item['feedback']);
    final score = _safeText(item['score']);
    final fluency = _safeText(item['fluency']);
    final vocabulary = _safeText(item['vocabulary']);
    final grammar = _safeText(item['grammar']);
    final pronunciation = _safeText(item['pronunciation']);
    final date = item['created_at']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: lightPrimary,
                child: Text(
                  score,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  part,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Topic: $topic",
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallScoreBox("Fluency", fluency),
              _smallScoreBox("Vocabulary", vocabulary),
              _smallScoreBox("Grammar", grammar),
              _smallScoreBox("Pronunciation", pronunciation),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "Transcript",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            transcript,
            style: const TextStyle(color: subTextColor, height: 1.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "Feedback",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            feedback,
            style: const TextStyle(
              color: primaryColor,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double contentWidth =
        (MediaQuery.of(context).size.width * 0.35).clamp(300.0, 560.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: Text(
          "$userName Speaking Results",
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: speakingResults.isEmpty
                ? _emptyBox("No speaking results found", Icons.mic_none)
                : Column(
                    children: speakingResults.map(_speakingResultCard).toList(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 55, color: primaryColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReadingResultOnlyPage extends StatelessWidget {
  final String userName;
  final List<Map<String, dynamic>> readingResults;

  const AdminReadingResultOnlyPage({
    super.key,
    required this.userName,
    required this.readingResults,
  });

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  String _safeText(dynamic value) {
    if (value == null) return "N/A";
    if (value.toString().trim().isEmpty) return "N/A";
    return value.toString();
  }

  Widget _readingResultCard(Map<String, dynamic> item) {
    final practiceType = _safeText(item['practice_type']);
    final correctAnswers = _safeText(item['correct_answers']);
    final totalQuestions = _safeText(item['total_questions']);
    final percentage = _safeText(item['percentage']);
    final bandScore = _safeText(item['band_score']);
    final insight = _safeText(item['insight']);
    final date = item['created_at']?.toString().split('T').first ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: lightPrimary,
                child: Text(
                  bandScore,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Reading - $practiceType",
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Score: $correctAnswers / $totalQuestions",
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Accuracy: $percentage%",
            style: const TextStyle(color: subTextColor),
          ),
          const SizedBox(height: 12),
          const Text(
            "Insight",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            insight,
            style: const TextStyle(
              color: primaryColor,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double contentWidth =
        (MediaQuery.of(context).size.width * 0.35).clamp(300.0, 560.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: Text(
          "$userName Reading Results",
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: readingResults.isEmpty
                ? _emptyBox("No reading results found", Icons.menu_book)
                : Column(
                    children: readingResults.map(_readingResultCard).toList(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emptyBox(String title, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 55, color: primaryColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}