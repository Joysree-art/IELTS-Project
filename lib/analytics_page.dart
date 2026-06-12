import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'profile_page.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool isLoading = true;

  double readingScore = 0.0;
  double writingScore = 0.0;
  double speakingScore = 0.0;
  double listeningScore = 0.0;

  double overallBand = 0.0;
  double improvement = 0.0;

  List<double> readingTrend = [0.0];
  List<double> writingTrend = [0.0];
  List<double> speakingTrend = [0.0];
  List<double> listeningTrend = [0.0];

  @override
  void initState() {
    super.initState();
    _fetchAllScores();
  }

  Future<void> _fetchAllScores() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final data = await Supabase.instance.client
          .from('ielts_scores')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      double latestReading = 0.0;
      double latestWriting = 0.0;
      double latestSpeaking = 0.0;
      double latestListening = 0.0;

      final readingScores = <double>[];
      final writingScores = <double>[];
      final speakingScores = <double>[];
      final listeningScores = <double>[];

      for (final item in data) {
        final module = item['module'].toString().toLowerCase();
        final score = (item['band_score'] as num).toDouble();

        if (module == 'reading') {
          if (latestReading == 0.0) latestReading = score;
          readingScores.add(score);
        } else if (module == 'writing') {
          if (latestWriting == 0.0) latestWriting = score;
          writingScores.add(score);
        } else if (module == 'speaking') {
          if (latestSpeaking == 0.0) latestSpeaking = score;
          speakingScores.add(score);
        } else if (module == 'listening') {
          if (latestListening == 0.0) latestListening = score;
          listeningScores.add(score);
        }
      }

      final latestScores = [
        latestWriting,
        latestSpeaking,
        latestReading,
        latestListening,
      ].where((score) => score > 0).toList();

      final calculatedOverall = latestScores.isEmpty
          ? 0.0
          : latestScores.reduce((a, b) => a + b) / latestScores.length;

      double getAverage(List<double> scores) {
        final validScores = scores.where((s) => s > 0).toList();
        if (validScores.isEmpty) return 0.0;
        return validScores.reduce((a, b) => a + b) / validScores.length;
      }

      final latestOverallScores = [
        readingScores.isNotEmpty ? readingScores[0] : 0.0,
        writingScores.isNotEmpty ? writingScores[0] : 0.0,
        speakingScores.isNotEmpty ? speakingScores[0] : 0.0,
        listeningScores.isNotEmpty ? listeningScores[0] : 0.0,
      ];

      final previousOverallScores = [
        readingScores.length > 1 ? readingScores[1] : 0.0,
        writingScores.length > 1 ? writingScores[1] : 0.0,
        speakingScores.length > 1 ? speakingScores[1] : 0.0,
        listeningScores.length > 1 ? listeningScores[1] : 0.0,
      ];

      final calculatedImprovement =
          getAverage(latestOverallScores) - getAverage(previousOverallScores);

      setState(() {
        readingScore = latestReading;
        writingScore = latestWriting;
        speakingScore = latestSpeaking;
        listeningScore = latestListening;
        overallBand = calculatedOverall;
        improvement = calculatedImprovement;

        readingTrend = _lastFourAscending(readingScores);
        writingTrend = _lastFourAscending(writingScores);
        speakingTrend = _lastFourAscending(speakingScores);
        listeningTrend = _lastFourAscending(listeningScores);

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load analytics: $e")),
      );
    }
  }

  List<double> _lastFourAscending(List<double> scores) {
    if (scores.isEmpty) return [0.0];

    final latestFour = scores.take(4).toList().reversed.toList();

    if (latestFour.length == 1) {
      return [latestFour.first, latestFour.first];
    }

    return latestFour;
  }

  String _improvementText() {
    if (improvement >= 0) {
      return "+${improvement.toStringAsFixed(1)}";
    }
    return improvement.toStringAsFixed(1);
  }

  void _goToPage(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else if (index == 1) {
      _fetchAllScores();
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final moduleScores = [
      writingScore,
      speakingScore,
      readingScore,
      listeningScore,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F8),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchAllScores,
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 95),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _GradientCard(
                                    title: "Overall Band",
                                    value: overallBand.toStringAsFixed(1),
                                    subtitle: "Average of all modules",
                                    colors: const [
                                      Color(0xFFFF2A2A),
                                      Color(0xFFE9001E),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _GradientCard(
                                    title: "Overall Change",
                                    value: _improvementText(),
                                    subtitle: "Latest overall vs previous",
                                    colors: const [
                                      Color(0xFFFF2A2A),
                                      Color(0xFFF00058),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Performance Trends",
                              height: 340,
                              child: CustomPaint(
                                size: const Size(double.infinity, 250),
                                painter: LineChartPainter(
                                  readingValues: readingTrend,
                                  writingValues: writingTrend,
                                  speakingValues: speakingTrend,
                                  listeningValues: listeningTrend,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Current Module Scores",
                              height: 320,
                              child: CustomPaint(
                                size: const Size(double.infinity, 230),
                                painter: BarChartPainter(scores: moduleScores),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ChartCard(
                              title: "Module Score Analysis",
                              height: 470,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 230,
                                    width: 230,
                                    child: CustomPaint(
                                      painter: DonutChartPainter(
                                        scores: moduleScores,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const _LegendGrid(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics Dashboard",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071323),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Performance insights & trends",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchAllScores,
            icon: const Icon(Icons.refresh, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: _goToPage,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: "Analytics",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profile",
        ),
      ],
    );
  }
}

class _GradientCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final List<Color> colors;

  const _GradientCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final double height;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD9DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF071323),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> readingValues;
  final List<double> writingValues;
  final List<double> speakingValues;
  final List<double> listeningValues;

  LineChartPainter({
    required this.readingValues,
    required this.writingValues,
    required this.speakingValues,
    required this.listeningValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final left = 42.0;
    final top = 10.0;
    final bottom = size.height - 60;
    final right = size.width - 15;

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    for (int i = 0; i < 4; i++) {
      final x = left + i * ((right - left) / 3);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    void drawLine(List<double> values, Color color) {
      if (values.isEmpty) return;

      final displayValues =
          values.length == 1 ? [values.first, values.first] : values;
      final points = <Offset>[];

      for (int i = 0; i < displayValues.length; i++) {
        final x =
            left + i * ((right - left) / max(1, displayValues.length - 1));
        final safeValue = displayValues[i].clamp(0.0, 9.0);
        final y = bottom - ((safeValue - 0) / 9) * (bottom - top);
        points.add(Offset(x, y));
      }

      if (points.isEmpty) return;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, linePaint);

      for (final p in points) {
        canvas.drawCircle(p, 5, Paint()..color = Colors.white);
        canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }

    drawLine(writingValues, const Color(0xFFE82429));
    drawLine(speakingValues, const Color(0xFFF23863));
    drawLine(readingValues, const Color(0xFFE6459B));
    drawLine(listeningValues, const Color(0xFFFF6B16));

    final weekLabels = ["Test 1", "Test 2", "Test 3", "Test 4"];

    for (int i = 0; i < 4; i++) {
      final x = left + i * ((right - left) / 3);

      textPainter.text = TextSpan(
        text: weekLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, bottom + 10),
      );
    }

    final yLabels = ["9", "6", "3", "0"];

    for (int i = 0; i < yLabels.length; i++) {
      final y = top + i * ((bottom - top) / 3);
      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(15, y - 8));
    }

    final legends = [
      ["Writing", const Color(0xFFE82429)],
      ["Speaking", const Color(0xFFF23863)],
      ["Reading", const Color(0xFFE6459B)],
      ["Listening", const Color(0xFFFF6B16)],
    ];

    double legendX = left;
    final legendY = size.height - 22;

    for (final item in legends) {
      final label = item[0] as String;
      final color = item[1] as Color;

      canvas.drawLine(
        Offset(legendX, legendY),
        Offset(legendX + 12, legendY),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );

      canvas.drawCircle(
        Offset(legendX + 6, legendY),
        3,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        Offset(legendX + 6, legendY),
        3,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 12),
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(legendX + 16, legendY - 8));

      legendX += textPainter.width + 34;
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.readingValues != readingValues ||
        oldDelegate.writingValues != writingValues ||
        oldDelegate.speakingValues != speakingValues ||
        oldDelegate.listeningValues != listeningValues;
  }
}

class BarChartPainter extends CustomPainter {
  final List<double> scores;

  BarChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    final left = 42.0;
    final bottom = size.height - 38;
    final top = 5.0;
    final right = size.width - 15;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 4; i++) {
      final y = top + i * ((bottom - top) / 3);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    final labels = ["Writing", "Speaking", "Reading", "Listening"];
    final colors = [
      const Color(0xFFE82429),
      const Color(0xFFF23863),
      const Color(0xFFE6459B),
      const Color(0xFFFF6B16),
    ];

    final barWidth = 48.0;
    final gap = (right - left - barWidth * 4) / 3;

    for (int i = 0; i < 4; i++) {
      final x = left + i * (barWidth + gap);
      final safeScore = scores[i].clamp(0.0, 9.0);
      final h = (safeScore / 9) * (bottom - top);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - h, barWidth, h),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, Paint()..color = colors[i]);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, bottom + 10),
      );

      textPainter.text = TextSpan(
        text: safeScore.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, bottom - h - 18),
      );
    }

    final yLabels = ["9", "6", "3", "0"];

    for (int i = 0; i < yLabels.length; i++) {
      final y = top + i * ((bottom - top) / 3);

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(15, y - 8));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> scores;

  DonutChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    final total = scores.fold<double>(0.0, (sum, value) => sum + value);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 25;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 48
      ..strokeCap = StrokeCap.butt;

    final colors = [
      const Color(0xFFE82429),
      const Color(0xFFF23863),
      const Color(0xFFE6459B),
      const Color(0xFFFF6B16),
    ];

    if (total <= 0) {
      paint.color = const Color(0xFFE5E7EB);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double start = -pi / 2;

    for (int i = 0; i < scores.length; i++) {
      final sweep = (scores[i] / total) * 2 * pi;
      paint.color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.04,
        false,
        paint,
      );

      start += sweep;
    }

    final avg = total / scores.where((s) => s > 0).length.clamp(1, 4);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: avg.toStringAsFixed(1),
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - 24),
    );

    textPainter.text = const TextSpan(
      text: "Average",
      style: TextStyle(color: Colors.grey, fontSize: 13),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}

class _LegendGrid extends StatelessWidget {
  const _LegendGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                color: Color(0xFFE82429),
                text: "Writing",
              ),
            ),
            Expanded(
              child: _LegendItem(
                color: Color(0xFFF23863),
                text: "Speaking",
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _LegendItem(
                color: Color(0xFFE6459B),
                text: "Reading",
              ),
            ),
            Expanded(
              child: _LegendItem(
                color: Color(0xFFFF6B16),
                text: "Listening",
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 7, backgroundColor: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}
