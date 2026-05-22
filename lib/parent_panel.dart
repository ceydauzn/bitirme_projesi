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
    if (currentUser != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
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
      String uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'hasPendingMeeting': false,
      });

      QuerySnapshot meetingQuery = await _firestore
          .collection('meetings')
          .where('parentId', isEqualTo: uid)
          .where('status', isEqualTo: 'Beklemede')
          .get();

      for (var doc in meetingQuery.docs) {
        await _firestore.collection('meetings').doc(doc.id).update({
          'status': statusText,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              statusText == 'Onaylandı'
                  ? "Görüşme onaylandı, öğretmene iletildi."
                  : "Görüşme reddedildi.",
            ),
            backgroundColor: statusText == 'Onaylandı'
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Randevu cevaplanırken hata: $e");
    }
  }

  // ✅ YENİ: Mesaj gönderme dialogu
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
            fillColor: Colors.white.withValues(alpha: 0.1),
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
                  'fromParentId': _auth.currentUser!.uid,
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
            child: _buildNeonCircle(
              200,
              Colors.tealAccent.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _buildNeonCircle(
              250,
              Colors.blueAccent.withValues(alpha: 0.1),
            ),
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
                      color: Colors.white.withValues(alpha: 0.7),
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

                      // ✅ Gerçek öğrenci adı
                      String studentName = studentData['name'] ?? 'Öğrenci';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCritical) _buildMeetingAlertCard(studentData),
                          if (isCritical) const SizedBox(height: 25),

                          const Text(
                            "Öğrenci Durum Özeti",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildStudentStatusCard(studentData, isCritical),

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
                              // ✅ Mesaj butonu artık dialog açıyor
                              Expanded(
                                child: _buildActionCard(
                                  Icons.chat_bubble_outline_rounded,
                                  "Rehberlik Servisine\nMesaj Gönder",
                                  Colors.blueAccent,
                                  onTap: () => _showMessageDialog(studentName),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // ✅ Analiz butonu artık gerçek öğrenci adını geçiyor
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
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.4),
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
                  color: Colors.white.withValues(alpha: 0.85),
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
    Map<String, dynamic> studentData,
    bool isCritical,
  ) {
    Color statusColor = isCritical ? Colors.redAccent : Colors.greenAccent;
    return ClipRRect(
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
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: statusColor.withValues(alpha: 0.2),
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
                      "Sınıf: ${studentData["class"] ?? "-"}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
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
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Güncel Durum: ${studentData["currentStatus"] ?? "Bilinmiyor"}",
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

  // ✅ onTap parametresi eklendi
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
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
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
