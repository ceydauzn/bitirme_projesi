import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_detail_screen.dart'; // 👈 1. ADIM: Detay sayfasını içeri aktardık

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  // Firebase Firestore bağlantısı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Cam AppBar arkasından gradyan aksın
      appBar: AppBar(
        title: const Text(
          "12-A Sınıf Listesi",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent, // Şeffaf AppBar
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

          // 2. Arka Plan Dekoratif Işıltıları (Mavi/Turkuaz tonlarında)
          Positioned(
            top: -50,
            right: -50,
            child: _buildNeonCircle(
              200,
              Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildNeonCircle(
              250,
              Colors.cyanAccent.withValues(alpha: 0.05),
            ),
          ),

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              // VİZYON: Tüm students koleksiyonunu saniye saniye dinle
              stream: _firestore.collection('students').snapshots(),
              builder: (context, snapshot) {
                // Veri yüklenirken dönecek çark
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }

                // Hata durumu
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Bir hata oluştu.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                // Veri yoksa veya koleksiyon boşsa
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Sınıfta hiç öğrenci bulunamadı.\nLütfen Firebase'den öğrenci ekleyin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                // Firebase'den gelen döküman listesi (Tüm öğrenciler)
                final students = snapshot.data!.docs;

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    // 3. Cam Efektli Bilgi Çubuğu (Dinamik mevcut sayısı)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildGlassInfoBar(students.length),
                    ),
                    const SizedBox(height: 15),

                    // 4. Cam Efektli Liste Elemanları
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: students.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          var doc = students[index];
                          var data = doc.data() as Map<String, dynamic>;

                          // Dokümanın ID'si aslında öğrenci numarası (Örn: 106)
                          String studentNo = doc.id;

                          return _buildStudentGlassCard(studentNo, data);
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

  // --- CAM WIDGET'LAR ---

  // Üst Bilgi Çubuğu
  Widget _buildGlassInfoBar(int totalStudents) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Mevcut: $totalStudents",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Canlı Veri",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Öğrenci Kartı Tasarımı
  Widget _buildStudentGlassCard(
    String studentNo,
    Map<String, dynamic> student,
  ) {
    Color statusColor;
    IconData statusIcon;

    // Firebase'deki alan adlarına göre verileri çekiyoruz (Yoksalar varsayılan atanır)
    int negativeDays = student["negativeDayCount"] ?? 0;
    String name = student["name"] ?? "Bilinmeyen Öğrenci";
    String status = student["currentStatus"] ?? "Nötr";

    // Renge karar verme
    if (negativeDays >= 3) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_rounded;
    } else if (negativeDays > 0) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.sentiment_dissatisfied_rounded;
    } else {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.sentiment_very_satisfied_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                // Eğer riskliyse sınırı kırmızı, değilse normal beyaz şeffaf yap
                color: negativeDays >= 3
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                "Öğrenci No: $studentNo",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (negativeDays > 0)
                    Text(
                      "$negativeDays Gün",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              // 👇 2. ADIM: TIKLANDIĞINDA DETAY SAYFASINA YÖNLENDİRME 👇
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailScreen(
                      studentId: studentNo,
                      studentName: name,
                    ),
                  ),
                );
              },
              // 👆 YÖNLENDİRME BİTİŞİ 👆
            ),
          ),
        ),
      ),
    );
  }

  // Arka plan ışıltıları için yardımcı widget
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
