import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'analytics_page.dart';
import 'profile_page.dart';

class SpeakingPage extends StatefulWidget {
  const SpeakingPage({super.key});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final supabase = Supabase.instance.client;

  Timer? _timer;

  bool _isPreparing = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _hasResult = false;

  int _prepSeconds = 60;
  int _speakSeconds = 60;

  String _selectedPart = "Part 1";
  String _topic = "";
  String _transcript = "";

  double _bandScore = 0.0;
  String _fluency = "";
  String _vocabulary = "";
  String _grammar = "";
  String _pronunciation = "";
  String _overallFeedback = "";

  List<Map<String, dynamic>> _history = [];

  final Map<String, List<String>> _topics = {
    "Part 1": [
      "Do you like reading books?",
      "What do you usually do in your free time?",
      "Do you prefer studying alone or with friends?",
      "What kind of music do you like?",
    ],
    "Part 2": [
      "Describe a memorable trip you had.",
      "Describe a person who inspires you.",
      "Describe your favorite book.",
      "Describe a place you would like to visit.",
    ],
    "Part 3": [
      "Why do people like travelling?",
      "How has technology changed education?",
      "What makes a good leader?",
      "Is online learning better than classroom learning?",
    ],
  };

  @override
  void initState() {
    super.initState();
    _generateTopic();
    _fetchHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  void _generateTopic() {
    final list = _topics[_selectedPart]!;
    _topic = list[Random().nextInt(list.length)];
  }

  void _changePart(String part) {
    if (_isRecording || _isPreparing) return;

    setState(() {
      _selectedPart = part;
      _resetAll();
      _generateTopic();
    });
  }

  void _resetAll() {
    _timer?.cancel();
    _isPreparing = false;
    _isRecording = false;
    _isAnalyzing = false;
    _hasResult = false;
    _prepSeconds = 60;
    _speakSeconds = _selectedPart == "Part 1" ? 60 : 120;
    _transcript = "";
    _bandScore = 0.0;
    _fluency = "";
    _vocabulary = "";
    _grammar = "";
    _pronunciation = "";
    _overallFeedback = "";
  }

  Future<void> _startPreparation() async {
    setState(() {
      _resetAll();
      _isPreparing = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepSeconds <= 0) {
        timer.cancel();
        _startRecording();
      } else {
        setState(() {
          _prepSeconds--;
        });
      }
    });
  }

  Future<void> _skipPreparation() async {
    _timer?.cancel();
    setState(() {
      _isPreparing = false;
    });
    await _startRecording();
  }

  Future<void> _startRecording() async {
    final permission = await Permission.microphone.request();

    if (!permission.isGranted) {
      _showMessage("Microphone permission required");
      return;
    }

    final available = await _speech.initialize();

    if (!available) {
      _showMessage("Speech recognition not available");
      return;
    }

    setState(() {
      _isPreparing = false;
      _isRecording = true;
      _transcript = "";
      _hasResult = false;
      _speakSeconds = _selectedPart == "Part 1" ? 60 : 120;
    });

    _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (result) {
        setState(() {
          _transcript = result.recognizedWords;
        });
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_speakSeconds <= 0) {
        timer.cancel();
        _stopRecording();
      } else {
        setState(() {
          _speakSeconds--;
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _speech.stop();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    _analyzeSpeaking();

    setState(() {
      _isAnalyzing = false;
      _hasResult = true;
    });
  }

  void _analyzeSpeaking() {
    final words = _transcript.trim().isEmpty
        ? <String>[]
        : _transcript.trim().split(RegExp(r'\s+'));

    final wordCount = words.length;
    final uniqueWords = words.map((e) => e.toLowerCase()).toSet().length;
    final vocabRatio = wordCount == 0 ? 0.0 : uniqueWords / wordCount;

    if (wordCount == 0) {
      _bandScore = 0.0;
      _fluency = "No speech detected.";
      _vocabulary = "No vocabulary detected.";
      _grammar = "No sentence detected.";
      _pronunciation = "Pronunciation could not be analyzed.";
      _overallFeedback = "Please try again and speak clearly.";
      return;
    }

    double score = 4.0;

    if (wordCount >= 20) score += 0.7;
    if (wordCount >= 40) score += 0.7;
    if (wordCount >= 70) score += 0.7;
    if (wordCount >= 100) score += 0.5;
    if (vocabRatio > 0.45) score += 0.5;
    if (_transcript.contains(".") || _transcript.contains(",")) score += 0.2;

    if (score > 8.5) score = 8.5;

    _bandScore = double.parse(score.toStringAsFixed(1));

    _fluency = wordCount < 35
        ? "Your answer is short. Try to speak more continuously with more details."
        : "Your fluency is acceptable. You gave a clear response with enough length.";

    _vocabulary = vocabRatio < 0.35
        ? "Vocabulary range is limited. Try to use more topic-specific words."
        : "Good vocabulary variety. Try adding advanced IELTS expressions.";

    _grammar = wordCount < 50
        ? "Use longer and more complete sentences."
        : "Grammar looks generally understandable. Try to use complex sentence structures.";

    _pronunciation =
        "Basic pronunciation check is estimated from speech recognition clarity. For real pronunciation scoring, audio AI/API is needed.";

    _overallFeedback = _bandScore < 5.5
        ? "You need to speak longer and organize your answer better."
        : _bandScore < 7
            ? "Good attempt. Improve vocabulary and sentence complexity."
            : "Strong response. Keep practicing advanced vocabulary and natural fluency.";
  }

  Future<void> _saveResult() async {
    if (_transcript.trim().isEmpty) {
      _showMessage("No transcript to save");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('speaking_results').insert({
        'user_id': user?.id,
        'part': _selectedPart,
        'topic': _topic,
        'transcript': _transcript,
        'score': _bandScore,
        'fluency': _fluency,
        'vocabulary': _vocabulary,
        'grammar': _grammar,
        'pronunciation': _pronunciation,
        'feedback': _overallFeedback,
      });

      _showMessage("Speaking result saved");
      await _fetchHistory();
    } catch (e) {
      _showMessage("Save failed: $e");
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _fetchHistory() async {
    try {
      final user = supabase.auth.currentUser;

      final response = await supabase
          .from('speaking_results')
          .select()
          .eq('user_id', user?.id ?? '')
          .order('created_at', ascending: false)
          .limit(3);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
      });
    } catch (_) {}
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  void _goToPage(int index) {
  if (index == 0) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } else if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalyticsPage()),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }
}

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE60046), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE60046),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _partButton(String part) {
    final selected = _selectedPart == part;

    return GestureDetector(
      onTap: () => _changePart(part),
      child: Container(
        width: 92,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE60046) : const Color(0xFFFFEEF3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          part,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFE60046),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _feedbackLine(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerText = _isPreparing
        ? _formatTime(_prepSeconds)
        : _formatTime(_speakSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Speaking Practice",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFCCD8)),
                ),
                child: const Text(
                  "Speak for 1-2 minutes on the given topic. Your fluency, pronunciation, vocabulary, and grammar will be analyzed.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFB42350),
                    height: 1.5,
                  ),
                ),
              ),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(Icons.category_outlined, "Speaking Part"),
                    const SizedBox(height: 14),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _partButton("Part 1"),
                          _partButton("Part 2"),
                          _partButton("Part 3"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(Icons.topic_outlined, "Your Topic"),
                    const SizedBox(height: 14),
                    Text(
                      _topic,
                      style: const TextStyle(
                        fontSize: 19,
                        color: Color(0xFF111827),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _isRecording || _isPreparing
                          ? null
                          : () {
                              setState(() {
                                _resetAll();
                                _generateTopic();
                              });
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Change Topic"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE60046),
                      ),
                    ),
                  ],
                ),
              ),

              _card(
                child: Column(
                  children: [
                    Text(
                      timerText,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE60046),
                      ),
                    ),
                    Text(
                      _isPreparing
                          ? "Preparation Time"
                          : _isRecording
                              ? "Speaking Time"
                              : "Ready",
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      height: 155,
                      width: 155,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFCCD8),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 72,
                        color: const Color(0xFFE60046),
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (!_isPreparing && !_isRecording)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _startPreparation,
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Start Preparation",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60046),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                    if (_isPreparing)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _skipPreparation,
                          icon: const Icon(Icons.mic, color: Colors.white),
                          label: const Text(
                            "Skip & Start Recording",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60046),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                    if (_isRecording)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text(
                            "Stop Recording",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60046),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),

                    if (_hasResult)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _resetAll();
                          });
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text("Retake"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE60046),
                        ),
                      ),
                  ],
                ),
              ),

              if (_isAnalyzing)
                _card(
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFFE60046)),
                      SizedBox(height: 14),
                      Text(
                        "Analyzing your speaking response...",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),

              if (_transcript.isNotEmpty)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(Icons.article_outlined, "Transcript"),
                      const SizedBox(height: 12),
                      Text(
                        _transcript,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_hasResult)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(Icons.auto_awesome, "AI Speaking Feedback"),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            height: 95,
                            width: 95,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFCCD8),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _bandScore.toString(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE60046),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              _overallFeedback,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _feedbackLine("Fluency", _fluency),
                      _feedbackLine("Vocabulary", _vocabulary),
                      _feedbackLine("Grammar", _grammar),
                      _feedbackLine("Pronunciation", _pronunciation),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveResult,
                          icon: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.white,
                          ),
                          label: _isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Save Result",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE60046),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_history.isNotEmpty)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(Icons.history, "Recent Speaking History"),
                      const SizedBox(height: 12),
                      ..._history.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${item['score'] ?? '-'}",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE60046),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item['topic'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFFE60046),
        unselectedItemColor: const Color(0xFF9CA3AF),
        onTap: _goToPage,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Analytics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}