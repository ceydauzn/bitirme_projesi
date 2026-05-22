import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafikleri çizeceğimiz sihirli paket

class PastAnalysisScreen extends StatelessWidget {
  final String studentName;

  const PastAnalysisScreen({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "$studentName - Stres Analizi",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Ortak Derin Gradyan Arka Plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1e3c72),
                  Color(0xFF2a5298),
                  Color(0xFF0f2027),
                ],
              ),
            ),
          ),

          // 2. Neon Işıltılar (Mor ve Pembe tonlarında - Grafikle uyumlu)
          Positioned(
            top: 100,
            right: -50,
            child: _buildNeonCircle(
              200,
              Colors.purpleAccent.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildNeonCircle(
              250,
              Colors.pinkAccent.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Son 7 Günlük Yapay Zeka Duygu Analizi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Bu grafik, sınıftaki kamera üzerinden alınan mikro yüz ifadelerinin haftalık stres/kaygı indeksini gösterir.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 3. CAM EFEKTLİ GRAFİK KARTI
                  _buildGlassChartCard(),

                  const SizedBox(height: 30),

                  // 4. Yapay Zeka Yorumu Kartı
                  _buildAiCommentCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GRAFİK WIDGET'I ---
  Widget _buildGlassChartCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 350, // Yüksekliği iyice artırdık ki grafik rahatlasın
          padding: const EdgeInsets.only(
            right: 20,
            left: 10,
            top: 20,
            bottom: 20, // Alt boşluğu 10'dan 20'ye çıkardık
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60, // Kesin çözüm: Yazı alanını 60'a çıkardık
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      Widget text;
                      switch (value.toInt()) {
                        case 0:
                          text = const Text('Pzt', style: style);
                          break;
                        case 1:
                          text = const Text('Sal', style: style);
                          break;
                        case 2:
                          text = const Text('Çar', style: style);
                          break;
                        case 3:
                          text = const Text('Per', style: style);
                          break;
                        case 4:
                          text = const Text('Cum', style: style);
                          break;
                        default:
                          text = const Text('', style: style);
                          break;
                      }
                      return SideTitleWidget(meta: meta, space: 8, child: text);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt()}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 4,
              minY: 0,
              maxY: 10,
              lineBarsData: [
                LineChartBarData(
                  // Haftalık stres verileri (0-10 arası)
                  spots: const [
                    FlSpot(0, 3), // Pazartesi: 3 seviye stres
                    FlSpot(1, 4), // Salı: 4 seviye
                    FlSpot(2, 8), // Çarşamba: 8 seviye (Pik yapmış)
                    FlSpot(3, 7), // Perşembe: 7 seviye
                    FlSpot(4, 9), // Cuma: 9 seviye (Çok riskli)
                  ],
                  isCurved: true,
                  color: Colors.pinkAccent,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.3,
                    ), // Çizginin altındaki parlama efekti
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- YAPAY ZEKA YORUM KARTI ---
  Widget _buildAiCommentCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.pinkAccent,
                size: 28,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Yapay Zeka Analiz Özeti",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Öğrencinin stres seviyesi hafta ortasından itibaren (Çarşamba) keskin bir artış göstermiş ve kritik eşik olan 7'nin üzerinde kalmıştır. Acil rehberlik müdahalesi önerilir.",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 15)],
      ),
    );
  }
}
