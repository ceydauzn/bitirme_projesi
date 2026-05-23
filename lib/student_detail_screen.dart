import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String userRole; // Beklenen değerler: 'rehberlik' veya 'veli'

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.userRole,
  });

  // 👇 ANAHTARLAR 'rehberlik' OLARAK GÜNCELLENDİ 👇
  final Map<String, Map<String, String>> duyguOnerileri = const {
    'Stresli / Kaygılı': {
      'rehberlik':
          'Kritik Öneri: Öğrenci 3 gündür yüksek stres altında. Konunun zorluk seviyesini düşürün ve doğrudan bireysel rehberlik görüşmesi planlayın.',
      'veli':
          'Kritik Öneri: Çocuğunuzda son günlerde kronikleşen bir stres gözlemleniyor. Evde akademik baskıyı tamamen azaltın ve okulla iletişime geçin.',
    },
    'Kızgın': {
      'rehberlik':
          'Kritik Öneri: Süregelen gerginlik durumu. Öğrenciye mola verdirin ve sınıf içi çatışmaları önlemek için sakinleşme alanı tanıyın.',
      'veli':
          'Kritik Öneri: Çocuğunuzda birkaç gündür okulda süren bir gerginlik var. Bugün onunla yargılamadan, sakin bir konuşma yapmanız çok önemli.',
    },
    'Üzgün': {
      'rehberlik':
          'Kritik Öneri: Öğrencide uzun süreli moral bozukluğu mevcut. Derhal destekleyici bir dil kullanın and özel seans düzenleyin.',
      'veli':
          'Kritik Öneri: Çocuğunuzda devam eden bir üzüntü hali var. Birlikte sevdiği bir aktiviteyi yaparak duygu durumunu acilen desteklemelisiniz.',
    },
    'Mutlu': {
      'rehberlik':
          'Öneri: Harika! Öğrencinin bu ilgisini övgüyle destekleyin ve derse aktif katılımını sürdürün.',
      'veli':
          'Öneri: Çocuğunuz bugün okulda oldukça pozitif ve mutluydu. Bu motivasyonunu evde de takdir ederek pekiştirebilirsiniz.',
    },
    'Nötr': {
      'rehberlik':
          'Öneri: Dikkati ve motivasyonu artırmak için açık uçlu bir soru sorun veya görsel bir materyal gösterin.',
      'veli':
          'Öneri: Çocuğunuzun günü olağan seyrinde geçti. Gününün detaylarını konuşarak iletişiminizi güçlendirebilirsiniz.',
    },
  };

  String _getDynamicRecommendation(
    String status,
    String role,
    int negativeDays,
  ) {
    // 👇 REVIZE KISIM 1: 3 GÜNÜ GEÇTİYSE DOĞRUDAN KRONİK RİSK TAVSİYESİ DÖNDÜR 👇
    if (negativeDays >= 3) {
      if (role == 'rehberlik') {
        return 'Kritik Öneri: Öğrencinin stres geçmişi kronik seviyeye (Riskli) ulaşmış durumda. Şu an anlık durumu nötr görünse bile derhal bireysel rehberlik görüşmesi planlayın.';
      } else {
        return 'Kritik Öneri: Çocuğunuzda son günlerde biriken kronik bir stres gözlemleniyor. Evde akademik baskıyı tamamen azaltın ve okulla iletişime geçin.';
      }
    }

    bool isNegativeEmotion =
        status.contains('Stres') || status == 'Kızgın' || status == 'Üzgün';

    if (isNegativeEmotion && negativeDays < 3) {
      if (role == 'rehberlik') {
        return 'Öneri: Öğrencide anlık bir duygusal dalgalanma var. Kronik bir risk yok, rehberlik takibine alıp gözlemlemeye devam edin.';
      } else {
        return 'Öneri: Çocuğunuz okulda ufak bir duygusal dalgalanma yaşadı. Bugün onunla yakından ilgilenmeniz ve sohbet etmeniz faydalı olacaktır.';
      }
    }

    return duyguOnerileri[status]?[role] ??
        "Yapay zeka analiz için sınıf ortamından daha fazla veri bekliyor...";
  }

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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userRole == 'rehberlik'
                          ? 'Rehberlik Paneli'
                          : 'Veli Paneli',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
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

                      var data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      String currentStatus =
                          data['currentStatus'] ?? 'Bilinmiyor';
                      int negativeDayCount = data['negativeDayCount'] ?? 0;

                      // 👇 REVIZE KISIM 2: 3 GÜNÜ GEÇTİYSE EKRANDA RİSKLİ YAZDIR VE UYARI RENGİNİ TETİKLE 👇
                      bool isCritical = negativeDayCount >= 3;
                      String displayStatus = isCritical
                          ? "Riskli"
                          : currentStatus;
                      bool isNegative =
                          isCritical ||
                          currentStatus.toLowerCase().contains('stres') ||
                          currentStatus == 'Kızgın' ||
                          currentStatus == 'Üzgün';

                      return Column(
                        children: [
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
                                      backgroundColor: isNegative
                                          ? Colors.red[50]
                                          : Colors.green[50],
                                      child: Icon(
                                        isNegative
                                            ? Icons.warning_amber_rounded
                                            : Icons.sentiment_very_satisfied,
                                        color: isNegative
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      "Durum: $displayStatus", // 👈 currentStatus yerine displayStatus basılıyor
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
                                            color: isCritical
                                                ? Colors.red
                                                : Colors.orange,
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

                          Card(
                            color: isCritical
                                ? Colors.redAccent.withValues(
                                    alpha: 0.08,
                                  ) // 👈 isCritical durumuna göre dinamik renk renk
                                : Colors.blueAccent.withValues(alpha: 0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isCritical
                                    ? Colors.redAccent.withValues(alpha: 0.3)
                                    : Colors.blueAccent.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isCritical
                                            ? Icons.notification_important
                                            : Icons.lightbulb_outline,
                                        color: isCritical
                                            ? Colors.redAccent
                                            : Colors.blueAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        userRole == 'rehberlik'
                                            ? "Rehberlik İçin Tavsiye"
                                            : "Veli İçin Tavsiye",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isCritical
                                              ? Colors.redAccent
                                              : Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getDynamicRecommendation(
                                      currentStatus,
                                      userRole,
                                      negativeDayCount,
                                    ),
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
