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

  // Görüşme planla butonuna basıldığında çalışacak fonksiyon
  Future<void> _scheduleMeeting(String studentId, String studentName) async {
    try {
      QuerySnapshot parentQuery = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (parentQuery.docs.isNotEmpty) {
        DocumentSnapshot parentDoc = parentQuery.docs.first;
        String parentUid = parentDoc.id;
        Map<String, dynamic> parentData =
            parentDoc.data() as Map<String, dynamic>;
        String parentName = parentData.containsKey('name')
            ? parentData['name']
            : "Bilinmeyen Veli";

        await _firestore.collection('users').doc(parentUid).update({
          'hasPendingMeeting': true,
        });

        // ✅ DİNAMİK SAAT: Bildirimin gönderildiği gerçek saat kullanılıyor
        final now = DateTime.now();
        final dynamicTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        final dynamicDate =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        await _firestore.collection('meetings').add({
          "student": studentName,
          "parent": parentName,
          "date": dynamicDate, // ✅ Dinamik tarih (YYYY-MM-DD)
          "time": dynamicTime, // ✅ Dinamik saat (HH:mm)
          "notifiedAt": now.toIso8601String(), // ✅ Bildirim gönderilme anı
          "location": "Rehberlik Odası A-102",
          "status": "Beklemede",
          "isCritical": true,
          "studentId": studentId,
          "parentId": parentUid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showGlassDialog(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.greenAccent,
            message: "Evet, veliye bildirildi.",
          );
        }
      } else {
        if (mounted) {
          _showGlassDialog(
            icon: Icons.error_outline_rounded,
            iconColor: Colors.orangeAccent,
            message: "Bu öğrenciye kayıtlı bir veli bulunamadı!",
          );
        }
      }
    } catch (e) {
      debugPrint("Görüşme planlanırken hata: $e");
    }
  }

  // ✅ Tekrar eden glass dialog kodu tek metoda alındı
  void _showGlassDialog({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 60),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Tamam",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildGlassInfoBar(criticalStudents.length),
                    ),
                    const SizedBox(height: 15),
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
    String rawStatus = data["currentStatus"] ?? "Bilinmiyor";
    String displayStatus = negativeDays >= 3 ? "Riskli" : rawStatus;

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
                            "$negativeDays Gündür $displayStatus",
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
