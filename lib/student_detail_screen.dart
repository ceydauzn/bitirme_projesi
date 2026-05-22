import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  // 👇 1. YAPAY ZEKA ÖNERİ SÖZLÜĞÜ (PEDAGOJİK BEYİN) 👇
  final Map<String, String> duyguOnerileri = const {
    'Stresli / Kaygılı':
        'Öneri: Öğrenciye 5 dakikalık nefes egzersizi yaptırın veya konunun zorluk seviyesini anlık olarak düşürün.',
    'Kızgın':
        'Öneri: Öğrenciye kısa bir mola verdirin veya sakinleşmesi için bireysel çalışma süresi tanıyın.',
    'Üzgün':
        'Öneri: Göz teması kurarak destekleyici bir dil kullanın, ders sonu rehberlik için kısa bir görüşme planlayın.',
    'Mutlu':
        'Öneri: Harika! Öğrencinin bu ilgisini övgüyle destekleyin ve derse aktif katılımını sağlayın.',
    'Nötr':
        'Öneri: Dikkati ve motivasyonu artırmak için açık uçlu bir soru sorun veya görsel bir materyal gösterin.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text("$studentName - Analiz Detayı"),
        backgroundColor: const Color(0xFF1e3c72),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst kısımdaki havalı özet kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Öğrenci No: $studentId",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Canlı Analiz Durumu",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 15),

                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .doc(studentId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("Henüz bir analiz kaydı bulunmuyor."),
                          ),
                        );
                      }

                      // Firebase'den gelen veriyi Map olarak alıyoruz
                      var data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};

                      // Python kodunun gönderdiği alanları okuyoruz
                      String currentStatus =
                          data['currentStatus'] ?? 'Bilinmiyor';
                      int negativeDayCount = data['negativeDayCount'] ?? 0;

                      // Durumun stresli olup olmadığını kontrol ediyoruz
                      bool isStressed = currentStatus.toLowerCase().contains(
                        'stres',
                      );

                      // 👇 2. BURAYI GÜNCELLEDİK: Artık alt alta iki kart dönecek 👇
                      return Column(
                        children: [
                          // MEVCUT DURUM KARTI
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isStressed
                                          ? Colors.red[50]
                                          : Colors.green[50],
                                      child: Icon(
                                        isStressed
                                            ? Icons.warning_amber_rounded
                                            : Icons.sentiment_very_satisfied,
                                        color: isStressed
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      "Durum: $currentStatus",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      "Yapay zeka anlık duygu analizi",
                                    ),
                                  ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Stresli/Kaygılı Bildirim Sayısı:",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          "$negativeDayCount",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isStressed
                                                ? Colors.red
                                                : Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // 👇 3. YENİ YAPAY ZEKA ÖNERİ KARTIMIZ 👇
                          Card(
                            color: Colors.blueAccent.withOpacity(0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.blueAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.blueAccent,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Yapay Zeka Karar Destek",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    duyguOnerileri[currentStatus] ??
                                        "Yapay zeka analiz için sınıf ortamından daha fazla veri bekliyor...",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
