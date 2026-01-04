import 'package:flutter/material.dart';
import 'groq_service.dart';
import 'package:fl_chart/fl_chart.dart';

const String GROQ_API_KEY = ''; 

void main() {
  GroqService.init(GROQ_API_KEY);
  runApp(const TruthLensApp());
}

class TruthLensApp extends StatelessWidget {
  const TruthLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TruthLens',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TruthLensHome(),
    );
  }
}

class TruthLensHome extends StatefulWidget {
  const TruthLensHome({super.key});

  @override
  State<TruthLensHome> createState() => _TruthLensHomeState();
}

class _TruthLensHomeState extends State<TruthLensHome> {
  final TextEditingController _controller = TextEditingController();

  String aiAnswer = '';
  bool loading = false;
  double confidenceScore = 0.0;

 

  Future<void> analyze() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      final answer = await GroqService.getAnswer(_controller.text);
      setState(() {
        aiAnswer = answer;
        confidenceScore = estimateConfidence(answer);
        loading = false;
      });
    } catch (e) {
      setState(() {
        aiAnswer = 'Error: $e';
        confidenceScore = 0.0;
        loading = false;
      });
    }
  }

  double estimateConfidence(String answer) {
    final lengthScore = (answer.length / 400).clamp(0.2, 1.0);
    final certaintyWords = ['definitely', 'always', 'never', 'guaranteed'];

    final hasStrongClaims =
        certaintyWords.any((w) => answer.toLowerCase().contains(w));

    double confidence = lengthScore;
    if (hasStrongClaims) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  int confidenceToStars(double confidence) {
    if (confidence >= 0.90) return 5;
    if (confidence >= 0.75) return 4;
    if (confidence >= 0.60) return 3;
    if (confidence >= 0.40) return 2;
    return 1;
  }

  String riskLabel(double confidence) {
    if (confidence >= 0.85) return 'Low Risk';
    if (confidence >= 0.65) return 'Possible Overconfidence Risk';
    if (confidence >= 0.45) return 'Instability Risk';
    return 'Hallucination Risk';
  }

  Color riskColor(double confidence) {
    if (confidence >= 0.85) return Colors.green;
    if (confidence >= 0.65) return Colors.orange;
    return Colors.red;
  }

 

  Widget buildStars(double confidence) {
    final stars = confidenceToStars(confidence);
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 28,
        ),
      ),
    );   
  }

  Widget buildConfidenceLineGraph(double confidence) {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 1,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              barWidth: 4,
              spots: [
                FlSpot(0, confidence * 0.6),
                FlSpot(1, confidence * 0.8),
                FlSpot(2, confidence),
              ],
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRiskPieChart(double confidence) {
    final risk = (1 - confidence).clamp(0.0, 1.0);

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 40,
          sectionsSpace: 4,
          sections: [
            PieChartSectionData(
              value: confidence,
              color: Colors.green,
              title: 'Stable',
              radius: 50,
            ),
            PieChartSectionData(
              value: risk,
              color: Colors.red,
              title: 'Risk',
              radius: 50,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      title: const Text(
  'TruthLens',
  style: TextStyle(
    color: Colors.white, 
    fontWeight: FontWeight.bold,
  ),
),

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/image.png',
                height: 250,
                width: 250,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Ask a question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your query...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : analyze,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analyze'),
              ),
            ),

            const SizedBox(height: 24),

            if (aiAnswer.isNotEmpty) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(aiAnswer),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor(confidenceScore)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Trust Assessment',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    buildStars(confidenceScore),
                    const SizedBox(height: 8),
                    Text(
                      riskLabel(confidenceScore),
                      style: TextStyle(
                        color: riskColor(confidenceScore),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(confidenceScore * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Confidence Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildConfidenceLineGraph(confidenceScore),

              const SizedBox(height: 24),
              const Text(
                'Risk Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildRiskPieChart(confidenceScore),
            ],
          ],
        ),
      ),
    );
  }
}
