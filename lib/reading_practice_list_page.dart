import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reading_page.dart';

class ReadingPracticeListPage extends StatefulWidget {
  const ReadingPracticeListPage({super.key});

  @override
  State<ReadingPracticeListPage> createState() =>
      _ReadingPracticeListPageState();
}

class _ReadingPracticeListPageState extends State<ReadingPracticeListPage> {
  final supabase = Supabase.instance.client;

  static const Color primaryRed = Color(0xFFB91C1C);
  static const Color darkRed = Color(0xFF7F1D1D);
  static const Color borderRed = Color(0xFFEF4444);
  static const Color pageWhite = Colors.white;
  static const Color softGrey = Color(0xFFF9FAFB);
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF6B7280);

  bool isLoading = true;

  List<Map<String, dynamic>> passages = [];
  Map<String, int> questionCountByPassage = {};
  Set<String> completedPassageIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadingPractices();
  }

  Future<void> _loadReadingPractices() async {
    setState(() => isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;

      final passageData = await supabase
          .from('reading_passages')
          .select()
          .eq('is_published', true)
          .order('passage_number', ascending: true);

      final questionData =
          await supabase.from('reading_questions').select('id, passage_id');

      final scoreData = userId == null
          ? []
          : await supabase
              .from('reading_scores')
              .select('passage_id')
              .eq('user_id', userId);

      final countMap = <String, int>{};

      for (final q in questionData as List) {
        final passageId = q['passage_id']?.toString();
        if (passageId != null) {
          countMap[passageId] = (countMap[passageId] ?? 0) + 1;
        }
      }

      final completedSet = <String>{};

      for (final score in List<Map<String, dynamic>>.from(scoreData)) {
        final passageId = score['passage_id']?.toString();
        if (passageId != null && passageId.isNotEmpty) {
          completedSet.add(passageId);
        }
      }

      setState(() {
        passages = List<Map<String, dynamic>>.from(passageData as List);
        questionCountByPassage = countMap;
        completedPassageIds = completedSet;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reading practices: $e')),
      );
    }
  }

  void _openReadingPractice(String passageId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingPage(selectedPassageId: passageId),
      ),
    ).then((_) {
      _loadReadingPractices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = passages.length;
    final completed = completedPassageIds.length;
    final remaining = total - completed;

    return Scaffold(
      backgroundColor: pageWhite,
      appBar: AppBar(
        title: const Text('Reading Practice'),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReadingPractices,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : RefreshIndicator(
              onRefresh: _loadReadingPractices,
              color: primaryRed,
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(
                    total: total,
                    completed: completed,
                    remaining: remaining,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Available Reading Tests',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (passages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'No reading practices available.',
                          style: TextStyle(color: textGrey),
                        ),
                      ),
                    )
                  else
                    ...List.generate(passages.length, (index) {
                      final passage = passages[index];
                      final passageId = passage['id'].toString();
                      final isCompleted =
                          completedPassageIds.contains(passageId);

                      return _buildPracticeCard(
                        index: index,
                        passage: passage,
                        questionCount: questionCountByPassage[passageId] ?? 0,
                        isCompleted: isCompleted,
                        onTap: () => _openReadingPractice(passageId),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int completed,
    required int remaining,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderRed, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _summaryItem('Total', total.toString()),
          _summaryItem('Completed', completed.toString()),
          _summaryItem('Left', remaining.toString()),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: primaryRed,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard({
    required int index,
    required Map<String, dynamic> passage,
    required int questionCount,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final title = passage['title']?.toString() ?? 'Untitled Passage';
    final difficulty = passage['difficulty']?.toString() ?? 'medium';
    final passageNumber = index + 1;
    final text = passage['passage_text']?.toString() ?? '';

    final preview = text.length > 120 ? '${text.substring(0, 120)}...' : text;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted ? Colors.green.shade400 : borderRed,
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted ? Colors.green : primaryRed,
                  child: Icon(
                    isCompleted ? Icons.check : Icons.menu_book,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Practice Test $passageNumber',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _tag(
                            text: difficulty.toUpperCase(),
                            color: Colors.orange.shade800,
                            borderColor: Colors.orange.shade700,
                            bg: Colors.white,
                          ),
                          _tag(
                            text: '$questionCount Questions',
                            color: primaryRed,
                            borderColor: primaryRed,
                            bg: Colors.white,
                          ),
                          _tag(
                            text: isCompleted ? 'Completed' : 'Not Attempted',
                            color:
                                isCompleted ? Colors.green.shade800 : darkRed,
                            borderColor:
                                isCompleted ? Colors.green.shade600 : darkRed,
                            bg: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: primaryRed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag({
    required String text,
    required Color color,
    required Color borderColor,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
