// lib/listening/listening_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListeningPage extends StatelessWidget {
  const ListeningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text("Listening"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            "Choose Listening Option",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _OptionCard(
            title: "Practice Part 1",
            subtitle: "Conversation / form completion practice",
            icon: Icons.looks_one,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ListeningPracticeListPage(
                    sectionType: 'part1',
                    title: 'Practice Part 1',
                  ),
                ),
              );
            },
          ),
          _OptionCard(
            title: "Practice Part 2",
            subtitle: "Monologue practice",
            icon: Icons.looks_two,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ListeningPracticeListPage(
                    sectionType: 'part2',
                    title: 'Practice Part 2',
                  ),
                ),
              );
            },
          ),
          _OptionCard(
            title: "Practice Part 3",
            subtitle: "Academic discussion practice",
            icon: Icons.looks_3,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ListeningPracticeListPage(
                    sectionType: 'part3',
                    title: 'Practice Part 3',
                  ),
                ),
              );
            },
          ),
          _OptionCard(
            title: "Practice Part 4",
            subtitle: "Lecture practice",
            icon: Icons.looks_4,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ListeningPracticeListPage(
                    sectionType: 'part4',
                    title: 'Practice Part 4',
                  ),
                ),
              );
            },
          ),
          _OptionCard(
            title: "Give Full Test",
            subtitle: "Full IELTS Listening test with all 4 parts",
            icon: Icons.assignment,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FullListeningTestListPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ListeningPracticeListPage extends StatefulWidget {
  final String sectionType;
  final String title;

  const ListeningPracticeListPage({
    super.key,
    required this.sectionType,
    required this.title,
  });

  @override
  State<ListeningPracticeListPage> createState() =>
      _ListeningPracticeListPageState();
}

class _ListeningPracticeListPageState extends State<ListeningPracticeListPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> sections = [];

  @override
  void initState() {
    super.initState();
    loadSections();
  }

  Future<void> loadSections() async {
    try {
      final data = await supabase
          .from('listening_sections')
          .select('*, listening_tests!inner(id,title,is_published)')
          .eq('section_type', widget.sectionType)
          .eq('listening_tests.is_published', true)
          .order('created_at', ascending: false);

      setState(() {
        sections = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('Load sections error: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sections.isEmpty
              ? const Center(child: Text("No practice available yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final test = section['listening_tests'];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child:
                              const Icon(Icons.headphones, color: Colors.red),
                        ),
                        title: Text(
                          section['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(test?['title'] ?? 'IELTS Listening'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListeningTestPage(
                                testId: section['test_id'],
                                testTitle: section['title'],
                                singleSectionId: section['id'],
                                isFullTest: false,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class FullListeningTestListPage extends StatefulWidget {
  const FullListeningTestListPage({super.key});

  @override
  State<FullListeningTestListPage> createState() =>
      _FullListeningTestListPageState();
}

class _FullListeningTestListPageState extends State<FullListeningTestListPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> tests = [];

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  Future<void> loadTests() async {
    try {
      final data = await supabase
          .from('listening_tests')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      setState(() {
        tests = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('Load tests error: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: const Text("Full Listening Tests"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
              ? const Center(child: Text("No full test available yet"))
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: tests.length,
                  itemBuilder: (context, index) {
                    final test = tests[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child:
                              const Icon(Icons.assignment, color: Colors.red),
                        ),
                        title: Text(
                          test['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text("Full IELTS Listening Test"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListeningTestPage(
                                testId: test['id'],
                                testTitle: test['title'],
                                isFullTest: true,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class ListeningTestPage extends StatefulWidget {
  final String testId;
  final String testTitle;
  final String? singleSectionId;
  final bool isFullTest;

  const ListeningTestPage({
    super.key,
    required this.testId,
    required this.testTitle,
    this.singleSectionId,
    this.isFullTest = false,
  });

  @override
  State<ListeningTestPage> createState() => _ListeningTestPageState();
}

class _ListeningTestPageState extends State<ListeningTestPage> {
  final supabase = Supabase.instance.client;
  final AudioPlayer audioPlayer = AudioPlayer();

  bool loading = true;
  bool submitted = false;
  bool isPlaying = false;
  bool fullTestStarted = false;

  int currentAudioIndex = 0;

  Duration audioPosition = Duration.zero;
  Duration audioDuration = Duration.zero;

  Timer? testTimer;
  Duration testRemaining = const Duration(minutes: 40);

  List<Map<String, dynamic>> sections = [];
  Map<String, List<Map<String, dynamic>>> questionsBySection = {};
  Map<String, dynamic> userAnswers = {};

  int extractQuestionNumber(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return 9999;
    return int.parse(match.group(0)!);
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    setupAudioListener();
    setupAudioStateListeners();
    fetchTestData();
  }

  @override
  void dispose() {
    testTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  void setupAudioListener() {
    audioPlayer.onPlayerComplete.listen((event) async {
      setState(() {
        isPlaying = false;
        audioPosition = Duration.zero;
      });

      if (!widget.isFullTest) return;

      currentAudioIndex++;

      if (currentAudioIndex < sections.length) {
        await audioPlayer.play(
          UrlSource(sections[currentAudioIndex]['audio_url']),
        );
      }
    });
  }

  void setupAudioStateListeners() {
    audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        audioDuration = duration;
      });
    });

    audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        audioPosition = position;
      });
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });
  }

  void startTestTimer() {
    testTimer?.cancel();

    testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (testRemaining.inSeconds <= 0) {
        timer.cancel();
        audioPlayer.stop();

        if (!submitted) {
          submitTest();
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        testRemaining = Duration(seconds: testRemaining.inSeconds - 1);
      });
    });
  }

  Future<void> fetchTestData() async {
    try {
      List<dynamic> sectionData;

      if (widget.singleSectionId != null) {
        sectionData = await supabase
            .from('listening_sections')
            .select()
            .eq('id', widget.singleSectionId!)
            .order('section_no', ascending: true);
      } else {
        sectionData = await supabase
            .from('listening_sections')
            .select()
            .eq('test_id', widget.testId)
            .order('section_no', ascending: true);
      }

      sections = List<Map<String, dynamic>>.from(sectionData);

      sections.sort(
        (a, b) => (a['section_no'] as int).compareTo(b['section_no'] as int),
      );

      for (final section in sections) {
        final questionData = await supabase
            .from('listening_questions')
            .select()
            .eq('section_id', section['id'])
            .order('question_no', ascending: true);

        final qList = List<Map<String, dynamic>>.from(questionData);

        qList.sort((a, b) {
          final aNo = extractQuestionNumber(a['question_no'].toString());
          final bNo = extractQuestionNumber(b['question_no'].toString());
          return aNo.compareTo(bNo);
        });

        questionsBySection[section['id']] = qList;
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint('Fetch listening test data error: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> playSingleAudio(String audioUrl) async {
    await audioPlayer.stop();

    setState(() {
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;
    });

    await audioPlayer.play(UrlSource(audioUrl));
  }

  Future<void> pausePracticeAudio() async {
    if (widget.isFullTest) return;
    await audioPlayer.pause();
  }

  Future<void> resumePracticeAudio() async {
    if (widget.isFullTest) return;
    await audioPlayer.resume();
  }

  Future<void> seekPracticeAudio(Duration position) async {
    if (widget.isFullTest) return;
    await audioPlayer.seek(position);
  }

  Future<void> playFullTestAudio() async {
    if (sections.isEmpty || fullTestStarted) return;

    setState(() {
      fullTestStarted = true;
      testRemaining = const Duration(minutes: 40);
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;
    });

    startTestTimer();

    currentAudioIndex = 0;
    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(sections[currentAudioIndex]['audio_url']));
  }

  void setAnswer(String questionId, dynamic answer) {
    setState(() {
      userAnswers[questionId] = answer;
    });
  }

  String normalize(dynamic value) {
    return value.toString().replaceAll('"', '').trim().toLowerCase();
  }

  bool checkAnswer(Map<String, dynamic> question) {
    final qid = question['id'];
    final type = question['question_type'];
    final correct = question['correct_answer'];
    final user = userAnswers[qid];

    if (user == null) return false;

    if (type == 'completion' || type == 'short_answer') {
      return normalize(user) == normalize(correct);
    }

    if (type == 'mcq' || type == 'map') {
      return normalize(user) == normalize(correct);
    }

    if (type == 'multi_mcq') {
      final userList = List<String>.from(user ?? [])..sort();
      final correctList = List<String>.from(correct ?? [])..sort();

      if (userList.length != correctList.length) return false;

      for (int i = 0; i < correctList.length; i++) {
        if (normalize(userList[i]) != normalize(correctList[i])) {
          return false;
        }
      }

      return true;
    }

    if (type == 'matching') {
      if (user is! Map || correct is! Map) return false;

      for (final key in correct.keys) {
        if (normalize(user[key]) != normalize(correct[key])) {
          return false;
        }
      }

      return true;
    }

    return false;
  }

  int get totalQuestions {
    int total = 0;
    for (final qList in questionsBySection.values) {
      total += qList.length;
    }
    return total;
  }

  int get correctCount {
    int count = 0;

    for (final qList in questionsBySection.values) {
      for (final q in qList) {
        if (checkAnswer(q)) count++;
      }
    }

    return count;
  }

  double listeningBand(int score) {
    if (score >= 39) return 9.0;
    if (score >= 37) return 8.5;
    if (score >= 35) return 8.0;
    if (score >= 32) return 7.5;
    if (score >= 30) return 7.0;
    if (score >= 26) return 6.5;
    if (score >= 23) return 6.0;
    if (score >= 18) return 5.5;
    if (score >= 16) return 5.0;
    if (score >= 13) return 4.5;
    if (score >= 10) return 4.0;
    return 3.5;
  }

  Future<void> submitTest() async {
    if (submitted) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    testTimer?.cancel();
    await audioPlayer.stop();

    final score = correctCount;
    final total = totalQuestions;
    final percentage = total == 0 ? 0 : ((score / total) * 100).round();
    final band = listeningBand(score);

    final attempt = await supabase
        .from('user_listening_attempts')
        .insert({
          'user_id': user.id,
          'test_id': widget.testId,
          'score': score,
          'total': total,
          'percentage': percentage,
          'band_score': band,
        })
        .select()
        .single();
    await supabase.from('ielts_scores').insert({
      'user_id': user.id,
      'module': 'listening',
      'band_score': band,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (final qList in questionsBySection.values) {
      for (final q in qList) {
        await supabase.from('user_listening_attempt_answers').insert({
          'attempt_id': attempt['id'],
          'question_id': q['id'],
          'user_answer': userAnswers[q['id']],
          'correct_answer': q['correct_answer'],
          'is_correct': checkAnswer(q),
        });
      }
    }

    setState(() {
      submitted = true;
    });
  }

  Widget practiceAudioControl(String audioUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                color: Colors.red,
                iconSize: 34,
                onPressed: () async {
                  if (isPlaying) {
                    await pausePracticeAudio();
                  } else {
                    if (audioPosition == Duration.zero) {
                      await playSingleAudio(audioUrl);
                    } else {
                      await resumePracticeAudio();
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                color: Colors.red,
                onPressed: () {
                  final newPosition =
                      audioPosition - const Duration(seconds: 10);
                  seekPracticeAudio(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                color: Colors.red,
                onPressed: () {
                  final newPosition =
                      audioPosition + const Duration(seconds: 10);
                  seekPracticeAudio(
                    newPosition > audioDuration ? audioDuration : newPosition,
                  );
                },
              ),
              Expanded(
                child: Text(
                  '${formatDuration(audioPosition)} / ${formatDuration(audioDuration)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Slider(
            value: audioPosition.inSeconds
                .clamp(0,
                    audioDuration.inSeconds > 0 ? audioDuration.inSeconds : 1)
                .toDouble(),
            min: 0,
            max: audioDuration.inSeconds > 0
                ? audioDuration.inSeconds.toDouble()
                : 1,
            onChanged: (value) {
              seekPracticeAudio(Duration(seconds: value.toInt()));
            },
          ),
        ],
      ),
    );
  }

  Widget fullTestAudioBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.headphones, color: Colors.white, size: 48),
          const SizedBox(height: 10),
          const Text(
            "Full Listening Test Audio",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Part 1 to Part 4 will play one after another.",
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            "Time left: ${formatDuration(testRemaining)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fullTestStarted
                ? "Audio time: ${formatDuration(audioPosition)} / ${formatDuration(audioDuration)}"
                : "Once started, audio cannot be paused.",
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: fullTestStarted ? null : playFullTestAudio,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                fullTestStarted ? "Test Running" : "Start Full Listening Test",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F9),
      appBar: AppBar(
        title: Text(widget.testTitle),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: sections.isEmpty
          ? const Center(child: Text("No sections found"))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isFullTest) fullTestAudioBox(),
                  ...sections.map((section) {
                    final questions = questionsBySection[section['id']] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Part ${section['section_no']}: ${section['title']}",
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (section['instructions'] != null &&
                              section['instructions'].toString().isNotEmpty)
                            Text(
                              section['instructions'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                          if (!widget.isFullTest) ...[
                            const SizedBox(height: 16),
                            practiceAudioControl(section['audio_url']),
                          ],
                          const SizedBox(height: 20),
                          ...questions.map((q) {
                            return QuestionWidget(
                              question: q,
                              userAnswer: userAnswers[q['id']],
                              submitted: submitted,
                              isCorrect: submitted ? checkAnswer(q) : null,
                              onChanged: (answer) => setAnswer(q['id'], answer),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: submitted ? null : submitTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(
                        submitted ? "Submitted" : "Submit Test",
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                  if (submitted) ...[
                    const SizedBox(height: 22),
                    ResultBox(
                      score: correctCount,
                      total: totalQuestions,
                      band: listeningBand(correctCount),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class QuestionWidget extends StatelessWidget {
  final Map<String, dynamic> question;
  final dynamic userAnswer;
  final bool submitted;
  final bool? isCorrect;
  final Function(dynamic) onChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.submitted,
    required this.isCorrect,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final type = question['question_type'];

    if (type == 'mcq') return buildMcq();
    if (type == 'multi_mcq') return buildMultiMcq();
    if (type == 'completion' || type == 'short_answer') return buildTextField();
    if (type == 'matching') return buildMatching();
    if (type == 'map') return buildMap();

    return const SizedBox();
  }

  Widget resultIcon() {
    if (!submitted) return const SizedBox();

    return Icon(
      isCorrect == true ? Icons.check_circle : Icons.cancel,
      color: isCorrect == true ? Colors.green : Colors.red,
    );
  }

  Widget buildContextBlock() {
    if (question['context_text'] == null ||
        question['context_text'].toString().trim().isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        question['context_text'],
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget buildBase({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: submitted
            ? isCorrect == true
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2)
            : const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: child,
    );
  }

  Widget buildTextField() {
    return buildBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContextBlock(),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Q${question['question_no']}. ${question['question_text']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              resultIcon(),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            enabled: !submitted,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: "Write your answer",
              border: OutlineInputBorder(),
            ),
          ),
          if (submitted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Correct answer: ${question['correct_answer']}"),
            ),
        ],
      ),
    );
  }

  Widget buildMcq() {
    final options = List<String>.from(question['options'] ?? []);

    return buildBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContextBlock(),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Q${question['question_no']}. ${question['question_text']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              resultIcon(),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) {
            final letter = option.substring(0, 1);

            return RadioListTile<String>(
              value: letter,
              groupValue: userAnswer,
              onChanged: submitted ? null : (v) => onChanged(v),
              title: Text(option),
            );
          }),
          if (submitted) Text("Correct answer: ${question['correct_answer']}"),
        ],
      ),
    );
  }

  Widget buildMultiMcq() {
    final options = List<String>.from(question['options'] ?? []);
    final current = List<String>.from(userAnswer ?? []);

    return buildBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContextBlock(),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Q${question['question_no']}. ${question['question_text']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              resultIcon(),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Choose TWO answers.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...options.map((option) {
            final letter = option.substring(0, 1);
            final selected = current.contains(letter);

            return CheckboxListTile(
              value: selected,
              title: Text(option),
              onChanged: submitted
                  ? null
                  : (value) {
                      final updated = List<String>.from(current);

                      if (value == true) {
                        if (!updated.contains(letter) && updated.length < 2) {
                          updated.add(letter);
                        }
                      } else {
                        updated.remove(letter);
                      }

                      onChanged(updated);
                    },
            );
          }),
          if (submitted) Text("Correct answer: ${question['correct_answer']}"),
        ],
      ),
    );
  }

  Widget buildMatching() {
    final options = question['options'] ?? {};
    final items = List<String>.from(options['items'] ?? []);
    final choices = List<String>.from(options['choices'] ?? []);
    final current = Map<String, dynamic>.from(userAnswer ?? {});

    final startNo = int.tryParse(
          RegExp(r'\d+')
                  .firstMatch(question['question_no'].toString())
                  ?.group(0) ??
              '',
        ) ??
        0;

    return buildBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContextBlock(),
          Text(
            "Q${question['question_no']}. ${question['question_text']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final displayNumber = startNo + index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 135,
                    child: Text(
                      "$displayNumber. $item",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: current[item],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: choices.map((choice) {
                        return DropdownMenuItem(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList(),
                      onChanged: submitted
                          ? null
                          : (value) {
                              current[item] = value;
                              onChanged(current);
                            },
                    ),
                  ),
                ],
              ),
            );
          }),
          if (submitted) Text("Correct answer: ${question['correct_answer']}"),
        ],
      ),
    );
  }

  Widget buildMap() {
    final options = question['options'] ?? {};
    final labels = List<String>.from(options['labels'] ?? []);

    return buildBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildContextBlock(),
          Text(
            "Q${question['question_no']}. ${question['question_text']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (question['image_url'] != null &&
              question['image_url'].toString().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(question['image_url']),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: userAnswer,
            decoration: const InputDecoration(
              labelText: "Choose map label",
              border: OutlineInputBorder(),
            ),
            items: labels.map((label) {
              return DropdownMenuItem(
                value: label,
                child: Text(label),
              );
            }).toList(),
            onChanged: submitted ? null : onChanged,
          ),
          if (submitted) Text("Correct answer: ${question['correct_answer']}"),
        ],
      ),
    );
  }
}

class ResultBox extends StatelessWidget {
  final int score;
  final int total;
  final double band;

  const ResultBox({
    super.key,
    required this.score,
    required this.total,
    required this.band,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : ((score / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text(
            "Listening Result",
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "$score / $total",
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Accuracy: $percentage%",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "Band: ${band.toStringAsFixed(1)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.red.shade100,
                child: Icon(icon, color: Colors.red),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
