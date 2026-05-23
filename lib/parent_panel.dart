import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role_selection_screen.dart';
import 'past_analysis_screen.dart';

class ParentPanel extends StatefulWidget {
  const ParentPanel({super.key});

  @override
  State<ParentPanel> createState() => _ParentPanelState();
}

class _ParentPanelState extends State<ParentPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _parentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.email)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _parentData = doc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint("Veli verisi çekilirken hata: $e");
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _signOut(BuildContext context) async {
    await _auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  Future<void> _respondToMeeting(String statusText) async {
    try {
      String userEmail = _auth.currentUser!.email!;

      // 1. Veritabanını Güncelle
      await _firestore.collection('users').doc(userEmail).update({
        'hasPendingMeeting': false,
      });

      // 👇 2. SİHİRLİ DOKUNUŞ: Ekranın anında tepki verip kartı silmesi için State'i güncelliyoruz 👇
      setState(() {
        _parentData!['hasPendingMeeting'] = false;
      });

      // 3. Beklemedeki randevuyu bul ve Onaylandı/Reddedildi yap (Rehberlik1 ve Rehberlik2 hepsi için ortak çalışır)
      QuerySnapshot meetingQuery = await _firestore
          .collection('meetings')
          .where('parentId', isEqualTo: userEmail)
          .where('status', isEqualTo: 'Beklemede')
          .get();

      for (var doc in meetingQuery.docs) {
        await _firestore.collection('meetings').doc(doc.id).update({
          'status': statusText,
        });
      }

      // 4. Şık Cam Tasarımlı Bildirim Baloncuğu
      if (mounted) {
        bool isApproved = statusText == 'Onaylandı';
        IconData iconData = isApproved
            ? Icons.check_circle_outline_rounded
            : Icons.cancel_outlined;
        Color statusColor = isApproved
            ? Colors.greenAccent
            : Colors.orangeAccent;
        String message = isApproved
            ? "Görüşme başarıyla onaylandı ve öğretmene iletildi."
            : "Görüşme reddedildi / ertelendi.";

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, color: statusColor, size: 60),
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
                            backgroundColor: Colors.white.withOpacity(0.2),
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
    } catch (e) {
      debugPrint("Randevu cevaplanırken hata: $e");
    }
  }

  void _showMessageDialog(String studentName) {
    final TextEditingController messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e3c72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Rehberlik Servisine Mesaj",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Mesajınızı yazın...",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              try {
                await _firestore.collection('messages').add({
                  'fromParentEmail': _auth.currentUser!.email,
                  'fromParentName': _parentData?['name'] ?? 'Bilinmeyen Veli',
                  'studentName': studentName,
                  'studentId': _parentData?['studentId'] ?? '',
                  'text': messageController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                  'isRead': false,
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Mesajınız rehberlik servisine iletildi."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint("Mesaj gönderilirken hata: $e");
              }
            },
            child: const Text(
              "Gönder",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0f2027),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    if (_parentData == null || _parentData!['studentId'] == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f2027),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            "Öğrenci kaydınız bulunamadı.\nLütfen rehberlik servisiyle iletişime geçin.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    String studentId = _parentData!['studentId'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Veli Bilgilendirme Paneli",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış Yap',
            onPressed: () => _signOut(context),
          ),
        ],
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
            top: -50,
            right: -50,
            child: _buildNeonCircle(200, Colors.tealAccent.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildNeonCircle(250, Colors.blueAccent.withOpacity(0.1)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hoş Geldiniz, ${_parentData!["name"] ?? 'Veli'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Öğrencinizin güncel durum raporu aşağıdadır.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),

                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestore
                        .collection('students')
                        .doc(studentId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        );
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          "Öğrenci verisi Firebase'de bulunamadı.",
                          style: TextStyle(color: Colors.white),
                        );
                      }

                      var studentData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      int negativeDays = studentData['negativeDayCount'] ?? 0;
                      bool isCritical = negativeDays >= 3;

                      // 👇 REVIZE KISIM: Kartın görünürlüğü artık gün sayısına değil öğretmenin talebine (hasPendingMeeting) bağlı 👇
                      bool hasPending =
                          _parentData?['hasPendingMeeting'] == true;

                      String studentName = studentData['name'] ?? 'Öğrenci';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasPending) _buildMeetingAlertCard(studentData),
                          if (hasPending) const SizedBox(height: 25),

                          const Text(
                            "Öğrenci Durum Özeti",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildStudentStatusCard(
                            studentId,
                            studentData,
                            isCritical,
                          ), // studentId parametresi eklendi

                          const SizedBox(height: 25),

                          const Text(
                            "Hızlı İşlemler",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  Icons.chat_bubble_outline_rounded,
                                  "Rehberlik Servisine\nMesaj Gönder",
                                  Colors.blueAccent,
                                  onTap: () => _showMessageDialog(studentName),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildActionCard(
                                  Icons.insights_rounded,
                                  "Geçmiş Analiz\nRaporları",
                                  Colors.purpleAccent,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PastAnalysisScreen(
                                        studentName: studentName,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingAlertCard(Map<String, dynamic> studentData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notification_important_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text(
                      "Rehberlik Görüşme Talebi",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "Yapay zeka analizlerimize göre öğrenciniz ${studentData["name"]} son ${studentData["negativeDayCount"]} gündür yoğun stres altındadır. Sınıf rehber öğretmeni sizinle bir görüşme planlamıştır.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToMeeting('Onaylandı'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ONAYLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToMeeting('Reddedildi'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "REDDET / ERTELE",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentStatusCard(
    String studentId, // Dinamik sınıf hesaplaması için eklendi
    Map<String, dynamic> studentData,
    bool isCritical,
  ) {
    Color statusColor = isCritical ? Colors.redAccent : Colors.greenAccent;
    String rawStatus = studentData["currentStatus"] ?? "Bilinmiyor";
    String displayStatus = isCritical ? "Riskli" : rawStatus;

    // 👇 REVIZE KISIM: Sınıf bilgisi 1 veya 2 ile başlamasına göre otomatik hesaplanıyor 👇
    String calculatedClass = studentId.startsWith('1') ? '12-A' : '12-B';
    String finalClass = studentData["class"] ?? calculatedClass;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: statusColor.withOpacity(0.2),
                child: Icon(Icons.person, color: statusColor, size: 40),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentData["name"] ?? "Bilinmiyor",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Sınıf: $finalClass", // 👈 Artık 12-A veya 12-B otomatik basılacak
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Güncel Durum: $displayStatus",
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color, {
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 35),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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
        boxShadow: [BoxShadow(color: color, blurRadius: 30, spreadRadius: 15)],
      ),
    );
  }
}
