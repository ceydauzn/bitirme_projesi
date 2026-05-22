import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CriticalSituationsScreen extends StatefulWidget {
  const CriticalSituationsScreen({super.key});

  @override
  State<CriticalSituationsScreen> createState() =>
      _CriticalSituationsScreenState();
}

class _CriticalSituationsScreenState extends State<CriticalSituationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Görüşme planla butonuna basıldığında çalışacak sihirli FİNAL fonksiyonu
  Future<void> _scheduleMeeting(String studentId, String studentName) async {
    try {
      // 1. Öğrencinin velisini 'users' koleksiyonunda bul
      QuerySnapshot parentQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (parentQuery.docs.isNotEmpty) {
        // Veliyi bulduk! Verilerini alalım.
        DocumentSnapshot parentDoc = parentQuery.docs.first;
        String parentUid = parentDoc.id;
        Map<String, dynamic> parentData =
            parentDoc.data() as Map<String, dynamic>;
        String parentName = parentData.containsKey('name')
            ? parentData['name']
            : "Bilinmeyen Veli";

        // --- 1. SİHİR: Velinin telefonunda kırmızı alarmı çaldır ---
        await _firestore.collection('users').doc(parentUid).update({
          'hasPendingMeeting': true,
        });

        // --- 2. SİHİR: Senin o efsane tasarımına (Takvime) randevuyu ekle! ---
        await _firestore.collection('meetings').add({
          "student": studentName,
          "parent": parentName,
          "date": "Bugün", // Demo amaçlı anında düşmesi için Bugün dedik
          "time": "15:30",
          "status": "Beklemede",
          "isCritical":
              true, // Kritik ekrandan tetiklendiği için Acil etiketi alacak
          "studentId": studentId,
          "parentId": parentUid,
          "createdAt":
              FieldValue.serverTimestamp(), // İleride tarihe göre sıralamak istersen diye
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Randevu takvime eklendi ve veliye alarm gönderildi!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu öğrenciye kayıtlı bir veli bulunamadı!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Görüşme planlanırken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Kritik Durumlar",
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
                  Color(0xFF1e3c72),
                  Color(0xFF2a5298),
                  Color(0xFF0f2027),
                ],
              ),
            ),
          ),

          // 2. Alarm Hissiyatı Veren Neon Işıltılar (Kırmızı tonlarında)
          Positioned(
            top: 50,
            right: -50,
            child: _buildNeonCircle(
              200,
              Colors.redAccent.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _buildNeonCircle(
              250,
              Colors.orangeAccent.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              // VİZYON: Sadece negativeDayCount >= 3 olan öğrencileri getir!
              stream: _firestore
                  .collection('students')
                  .where('negativeDayCount', isGreaterThanOrEqualTo: 3)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Bir hata oluştu.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Eğer riskli öğrenci yoksa öğretmene güzel haber ver
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.greenAccent.withValues(alpha: 0.8),
                          size: 80,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Harika!\nSınıfta kritik seviyede stres yaşayan\nöğrenci bulunmuyor.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final criticalStudents = snapshot.data!.docs;

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    // Üst Bilgi Çubuğu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildGlassInfoBar(criticalStudents.length),
                    ),
                    const SizedBox(height: 15),

                    // Riskli Öğrenciler Listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: criticalStudents.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          var doc = criticalStudents[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String studentId = doc.id;

                          return _buildCriticalGlassCard(studentId, data);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET'LAR ---

  Widget _buildGlassInfoBar(int count) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Acil Müdahale: $count",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Text(
                "Yapay Zeka Alarmı",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriticalGlassCard(String studentId, Map<String, dynamic> data) {
    String name = data["name"] ?? "Bilinmeyen Öğrenci";
    int negativeDays = data["negativeDayCount"] ?? 3;
    String status = data["currentStatus"] ?? "Stresli";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_alt_rounded,
                        color: Colors.redAccent,
                        size: 30,
                      ),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "$negativeDays Gündür $status",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleMeeting(studentId, name),
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Görüşme Planla ve Veliye Bildir",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
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
        boxShadow: [BoxShadow(color: color, blurRadius: 40, spreadRadius: 20)],
      ),
    );
  }
}
