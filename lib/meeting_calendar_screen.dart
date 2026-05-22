import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  // Firebase Firestore bağlantısı
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Görüşme Takvimi",
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

          // 2. Neon Işıltılar (Turkuaz ve Mavi)
          Positioned(
            top: 50,
            right: -50,
            child: _buildNeonCircle(
              200,
              Colors.tealAccent.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -80,
            child: _buildNeonCircle(
              250,
              Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),

          // 3. CANLI FİREBASE VERİSİ (StreamBuilder)
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('meetings').snapshots(),
              builder: (context, snapshot) {
                // Yüklenme durumu
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
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

                // Randevu yoksa gösterilecek boş ekran tasarımı
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 80,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Harika!\nPlanlanmış bir görüşmeniz bulunmuyor.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Firebase'den gelen canlı randevu listesi
                final meetings = snapshot.data!.docs;

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    // Üst Bilgi Çubuğu (Artık dinamik sayı alıyor)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildGlassInfoBar(meetings.length),
                    ),
                    const SizedBox(height: 15),

                    // Toplantı Listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: meetings.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          // Firebase'den gelen her bir dokümanın verisini Map'e çeviriyoruz
                          var meetingData =
                              meetings[index].data() as Map<String, dynamic>;
                          return _buildMeetingGlassCard(meetingData);
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

  // --- WIDGET'LAR (SENİN TASARIMIN) ---

  // Parametre olarak toplantı sayısını (count) alacak şekilde güncellendi
  Widget _buildGlassInfoBar(int count) {
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
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Yaklaşan: $count Randevu",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.filter_list_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingGlassCard(Map<String, dynamic> meeting) {
    // Firebase'den gelen verilere null-safety (hata önleme) uygulandı
    bool isCritical = meeting["isCritical"] ?? false;
    String status = meeting["status"] ?? "Beklemede";
    String date = meeting["date"] ?? "Tarih Yok";
    String time = meeting["time"] ?? "Saat Yok";
    String studentName = meeting["student"] ?? "Bilinmeyen Öğrenci";
    String parentName = meeting["parent"] ?? "Bilinmeyen Veli";

    Color cardBorderColor = isCritical
        ? Colors.redAccent.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.2);
    Color statusColor = _getStatusColor(status);

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
                color: cardBorderColor,
                width: isCritical ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Kısım: Tarih, Saat ve Aciliyet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$date • $time",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (isCritical)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Acil",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Colors.white24, height: 1),
                ),

                // Orta Kısım: Kişi Bilgileri
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isCritical
                          ? Colors.redAccent.withValues(alpha: 0.15)
                          : Colors.blueAccent.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person,
                        color: isCritical
                            ? Colors.redAccent
                            : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Öğrenci: $studentName",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Veli: $parentName",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Alt Kısım: Durum ve Aksiyon Butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    // Görüşmeyi Başlat / Detay Butonu
                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "$parentName ile görüşme notları sayfası açılacak.",
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Görüşme Detayı",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains("Onayladı")) return Colors.greenAccent;
    if (status.contains("Reddetti")) return Colors.redAccent;
    return Colors.orangeAccent; // Beklemede
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
