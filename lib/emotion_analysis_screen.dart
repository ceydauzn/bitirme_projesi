import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionAnalysisScreen extends StatefulWidget {
  final String assignedClass;
  const EmotionAnalysisScreen({super.key, required this.assignedClass});

  @override
  State<EmotionAnalysisScreen> createState() => _EmotionAnalysisScreenState();
}

class _EmotionAnalysisScreenState extends State<EmotionAnalysisScreen> {
  late String _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.assignedClass;
  }

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
                ],
              ),
            ),
          ),

          // 2. Neon Işıltılar
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
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: 40.0, // Alt boşluk
              ),
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

                  // 3. Canlı Kamera Akışı Placeholder'ı
                  _buildLiveFeedPlaceholder(),
                  const SizedBox(height: 20),

                  // 4. YENİ MODÜL: Sistem Durum Kartı
                  _buildSystemStatusCard(),
                  const SizedBox(height: 25),

                  // 5. Anlık Duygu Dağılımı (Mevcut Firebase Bağlantılı Modül)
                  const Text(
                    "Anlık Sınıf Duygu Dağılımı",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildDynamicEmotionChart(),

                  const SizedBox(height: 25),

                  // 6. YENİ MODÜL: Kritik Durum Uyarıları
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orangeAccent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Kritik Durum Uyarıları",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildCriticalAlerts(),

                  const SizedBox(height: 25),

                  // 7. YENİ MODÜL: YZ Asistan Önerisi
                  const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amberAccent),
                      SizedBox(width: 8),
                      Text(
                        "YZ Sınıf İçi Aksiyon Önerisi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildAIRecommendation(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET'LAR ---

  Widget _buildClassSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(
            _selectedClass,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
        ],
      ),
    );
  }

  Widget _buildLiveFeedPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory, color: Colors.cyanAccent, size: 60),
            SizedBox(height: 15),
            Text(
              "Yapay Zeka Analiz Modülü",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Sistem Aktif • Veriler Gerçek Zamanlı İşleniyor",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // YENİ EKLENEN MODÜL 1: Sistem Durum Kartı
  Widget _buildSystemStatusCard() {
    return _buildGlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem(
            Icons.videocam,
            "Kamera",
            "Aktif",
            Colors.greenAccent,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatusItem(
            Icons.speed,
            "Analiz Hızı",
            "0.8 sn",
            Colors.cyanAccent,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatusItem(
            Icons.group,
            "Öğrenci",
            "18/20",
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // YENİ EKLENEN MODÜL 2: Kritik Durum Uyarıları
  Widget _buildCriticalAlerts() {
    return Column(
      children: [
        _buildAlertTile(
          name: "Ahmet Yılmaz",
          issue:
              "Son 15 dakikadır sürekli stres ve kaygı belirtisi gösteriyor.",
          color: Colors.orangeAccent,
          icon: Icons.psychology_alt,
        ),
        const SizedBox(height: 10),
        _buildAlertTile(
          name: "Zeynep Kaya",
          issue: "Ders başından beri odaklanma sorunu ve yorgunluk.",
          color: Colors.redAccent,
          icon: Icons.snooze,
        ),
      ],
    );
  }

  Widget _buildAlertTile({
    required String name,
    required String issue,
    required Color color,
    required IconData icon,
  }) {
    return _buildGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Rehberlik Yönlendirmesi Önerilir",
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // YENİ EKLENEN MODÜL 3: YZ Aksiyon Önerisi
  Widget _buildAIRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "Sistem Analizi",
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Sınıfın %60'ı odaklanmış durumda ancak arka sıralarda genel bir enerji düşüklüğü tespit edildi. Dikkatleri tazelemek için kısa bir soru-cevap etkinliğine geçilmesi önerilir.",
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicEmotionChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('branch', isEqualTo: _selectedClass)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGlassCard(
            height: 200,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildGlassCard(
            height: 200,
            child: const Center(
              child: Text(
                "Sınıf verisi bulunamadı.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        int totalStudents = snapshot.data!.docs.length;
        Map<String, int> emotionCounts = {
          "Odaklanmış": 0,
          "Mutlu / Rahat": 0,
          "Nötr": 0,
          "Stresli / Kaygılı": 0,
          "Uykulu / Sıkılmış": 0,
        };

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['currentStatus'] ?? "Nötr";

          if (status.contains("Mutlu")) {
            emotionCounts["Mutlu / Rahat"] =
                (emotionCounts["Mutlu / Rahat"] ?? 0) + 1;
          } else if (status.contains("Stres")) {
            emotionCounts["Stresli / Kaygılı"] =
                (emotionCounts["Stresli / Kaygılı"] ?? 0) + 1;
          } else if (status.contains("Kizgin") || status.contains("Üzgün")) {
            emotionCounts["Stresli / Kaygılı"] =
                (emotionCounts["Stresli / Kaygılı"] ?? 0) + 1;
          } else if (status.contains("Odakli")) {
            emotionCounts["Odaklanmış"] =
                (emotionCounts["Odaklanmış"] ?? 0) + 1;
          } else {
            emotionCounts["Nötr"] = (emotionCounts["Nötr"] ?? 0) + 1;
          }
        }

        return _buildGlassCard(
          child: Column(
            children: emotionCounts.entries.map((entry) {
              Color color = _getEmotionColor(entry.key);
              double percentage = totalStudents > 0
                  ? entry.value / totalStudents
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.fastOutSlowIn,
                            widthFactor: percentage,
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
                    SizedBox(
                      width: 40,
                      child: Text(
                        "%${(percentage * 100).toInt()}",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, double? height}) {
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
    return Colors.redAccent;
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
