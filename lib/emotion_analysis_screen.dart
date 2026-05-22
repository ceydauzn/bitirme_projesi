import 'dart:ui';
import 'package:flutter/material.dart';

class EmotionAnalysisScreen extends StatefulWidget {
  const EmotionAnalysisScreen({super.key});

  @override
  State<EmotionAnalysisScreen> createState() => _EmotionAnalysisScreenState();
}

class _EmotionAnalysisScreenState extends State<EmotionAnalysisScreen> {
  // MOCK DATA: Şu an sınıfta algılanan anlık duygu dağılımı
  // İleride burası görüntü işleme API'sinden gelen anlık verilerle güncellenecek.
  final Map<String, double> _instantEmotions = {
    "Odaklanmış": 0.65, // %65 (Yeşil)
    "Mutlu / Rahat": 0.15, // %15 (Mavi)
    "Nötr": 0.10, // %10 (Gri)
    "Stresli / Kaygılı": 0.07, // %7 (Turuncu)
    "Uykulu / Sıkılmış": 0.03, // %3 (Kırmızı)
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Sınıf Analiz Paneli",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                  Color(0xFF0f2027),
                  Color(0xFF203a43),
                  Color(0xFF2c5364),
                ], // Daha koyu, teknolojik tonlar
              ),
            ),
          ),

          // 2. Neon Işıltılar (Mavi ve Mor tonları)
          Positioned(
            top: 100,
            right: -50,
            child: _buildNeonCircle(
              180,
              Colors.blueAccent.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -70,
            child: _buildNeonCircle(
              220,
              Colors.purpleAccent.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Başlık ve Sınıf Seçimi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Canlı Duygu Takibi",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Yapay Zeka Destekli Mikro İfade Analizi",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      _buildClassSelector(),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 3. VİZYONER KISIM: Canlı Kamera Akışı Placeholder'ı
                  _buildLiveFeedPlaceholder(),

                  const SizedBox(height: 25),

                  // 4. Anlık Duygu Dağılımı (Bar Grafik Tasarımı)
                  const Text(
                    "Anlık Sınıf Duygu Dağılımı",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInstantEmotionChart(),

                  const SizedBox(height: 25),

                  // 5. Haftalık Trend (Çizgi Grafik Tasarımı)
                  const Text(
                    "Haftalık Stres Trendi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildWeeklyTrendChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET'LAR ---

  // Sınıf Seçici Dropdown (Cam Efektli)
  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Text(
            "12-A",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  // 1. Canlı Kamera Akışı Placeholder'ı
  Widget _buildLiveFeedPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.3),
              width: 1.5,
            ), // Teknolojik sınır
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arka plan deseni (Kamera varmış hissi)
              Center(
                child: Icon(
                  Icons.videocam_outlined,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 100,
                ),
              ),

              // Canlı Yazısı ve İkon
              Positioned(
                top: 15,
                left: 15,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "CANLI",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Orta Yazı (Gelecekteki Vizyon)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.cyanAccent,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Görüntü İşleme Modülü\nEntegrasyon Aşaması",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Faux İstatistikler
              Positioned(
                bottom: 15,
                right: 15,
                child: Text(
                  "FPS: 30 | Tespit Edilen Öğrenci: 18",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Anlık Duygu Dağılımı (Özel Tasarım Bar)
  Widget _buildInstantEmotionChart() {
    return _buildGlassCard(
      child: Column(
        children: _instantEmotions.entries.map((entry) {
          Color color = _getEmotionColor(entry.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: entry.value,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withValues(alpha: 0.7), color],
                            ),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "%${(entry.value * 100).toInt()}",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // 3. Haftalık Trend (Temsili Çizgi Grafik)
  Widget _buildWeeklyTrendChart() {
    return _buildGlassCard(
      height: 180,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Ortalama Stres Seviyesi",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  "Düşüşte",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Çizgi grafiği simüle eden özel CustomPainter
          SizedBox(
            width: double.infinity,
            height: 100,
            child: CustomPaint(painter: _LineChartPainter()),
          ),
          const Spacer(),
          // Gün İsimleri (Hata buradaydı, Colors.white54 olarak düzeltildi ve const kaldırıldı)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Pzt", "Sal", "Çar", "Per", "Cum"].map((day) {
              return Text(
                day,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI FONKSİYONLAR VE TASARIM ÖĞELERİ ---

  Widget _buildGlassCard({required Widget child, double? height}) {
    // Mavi uyarı buradaydı, Container yerine SizedBox kullanıldı.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    if (emotion.contains("Odaklanmış")) return Colors.greenAccent;
    if (emotion.contains("Mutlu")) return Colors.blueAccent;
    if (emotion.contains("Nötr")) return Colors.white70;
    if (emotion.contains("Stresli")) return Colors.orangeAccent;
    return Colors.redAccent; // Uykulu
  }

  Widget _buildNeonCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 30, spreadRadius: 15)],
      ),
    );
  }
}

// Çizgi Grafiği Çizen Özel CustomPainter (Temsili Veriler)
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.cyanAccent.withValues(alpha: 0.3),
          Colors.cyanAccent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Temsili veri noktaları (x: gün, y: stres seviyesi)
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.25, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.8), // Stres artmış
      Offset(size.width * 0.75, size.height * 0.3), // Sınav sonrası rahatlama
      Offset(size.width, size.height * 0.4),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    // Eğri çizme (Cubic Bezier)
    for (var i = 1; i < points.length; i++) {
      path.cubicTo(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i - 1].dy,
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
      fillPath.cubicTo(
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i - 1].dy,
        points[i - 1].dx + (points[i].dx - points[i - 1].dx) / 2,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint); // Alttaki dolgu
    canvas.drawPath(path, paint); // Ana çizgi

    // Noktaları çiz
    for (var point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = Colors.cyanAccent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
