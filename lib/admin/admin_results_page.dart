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
  List<Map<String, dynamic>> results = [];

  static const bgColor = Color(0xFFF5F6FA);
  static const primaryColor = Color(0xFFFF3B30);
  static const lightPrimary = Color(0xFFFFE8E6);
  static const textColor = Color(0xFF202124);
  static const subTextColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
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

      final speakingResults =
          List<Map<String, dynamic>>.from(speakingData).map((e) {
        return {
          ...e,
          'result_type': 'speaking',
        };
      }).toList();

      final readingResults =
          List<Map<String, dynamic>>.from(readingData).map((e) {
        return {
          ...e,
          'result_type': 'reading',
        };
      }).toList();

      final allResults = [...speakingResults, ...readingResults];

      allResults.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(2000);
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(2000);
        return bDate.compareTo(aDate);
      });

      setState(() {
        results = allResults;
      });
    } catch (e) {
      _showMessage("Failed to load results: $e");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "Failed to load results",
          style: TextStyle(color: textColor),
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _resultCard(Map<String, dynamic> item) {
    final resultType = item['result_type']?.toString() ?? '';
    final date = item['created_at']?.toString().split('T').first ?? '';

    final title = resultType == 'reading'
        ? 'Reading - ${item['practice_type'] ?? ''}'
        : item['part']?.toString() ?? 'Speaking';

    final topic = resultType == 'reading'
        ? 'Score: ${item['correct_answers'] ?? 0} / ${item['total_questions'] ?? 0}'
        : item['topic']?.toString() ?? '';

    final transcript = resultType == 'reading'
        ? 'Accuracy: ${item['percentage'] ?? 0}%'
        : item['transcript']?.toString() ?? '';

    final feedback = resultType == 'reading'
        ? item['insight']?.toString() ??
            'Band Score: ${item['band_score'] ?? '-'}'
        : item['feedback']?.toString() ?? '';

    final score = resultType == 'reading'
        ? item['band_score']?.toString() ?? '-'
        : item['score']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                topic,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                transcript,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                feedback,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: primaryColor,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
          Icon(Icons.bar_chart_outlined, size: 55, color: primaryColor),
          SizedBox(height: 12),
          Text(
            "No results yet",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "User speaking results will appear here.",
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
          "Admin Results",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchResults,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final double contentWidth =
              (screenWidth * 0.35).clamp(300.0, 520.0).toDouble();
          final bool isSmallScreen = screenWidth <= 320;

          return RefreshIndicator(
            onRefresh: _fetchResults,
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
                        child: Text(
                          "All Results (${results.length})",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        )
                      else if (results.isEmpty)
                        _emptyState()
                      else
                        ...results.map(_resultCard),
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
