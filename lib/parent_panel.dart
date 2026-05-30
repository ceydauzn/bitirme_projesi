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

      await _firestore.collection('users').doc(userEmail).update({
        'hasPendingMeeting': false,
      });

      setState(() {
        _parentData!['hasPendingMeeting'] = false;
      });

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

        _showGlassDialog(
          icon: iconData,
          iconColor: statusColor,
          message: message,
        );
      }
    } catch (e) {
      debugPrint("Randevu cevaplanırken hata: $e");
    }
  }

  // ✅ YENİ: Görüşme detaylarını glass popup ile göster
  void _showMeetingDetailPopup(Map<String, dynamic> meetingData) {
    // ✅ Tarih formatını kullanıcı dostu hale getir
    String rawDate = meetingData['date'] ?? '';
    String formattedDate = _formatDate(rawDate);

    // ✅ Gerçek bildirim saatini göster
    String time = meetingData['time'] ?? '--:--';
    String location = meetingData['location'] ?? 'Belirtilmemiş';
    String status = meetingData['status'] ?? 'Beklemede';
    String studentName = meetingData['student'] ?? 'Bilinmiyor';

    // ✅ Bildirim zamanı (notifiedAt varsa)
    String notifiedAtText = '';
    if (meetingData['notifiedAt'] != null) {
      try {
        DateTime notifiedAt = DateTime.parse(meetingData['notifiedAt']);
        notifiedAtText =
            "${notifiedAt.day.toString().padLeft(2, '0')}.${notifiedAt.month.toString().padLeft(2, '0')}.${notifiedAt.year}  "
            "${notifiedAt.hour.toString().padLeft(2, '0')}:${notifiedAt.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Onaylandı':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'Reddedildi':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.amberAccent;
        statusIcon = Icons.hourglass_top_rounded;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_note_rounded,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Görüşme Detayı",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 20),

                  // Öğrenci Adı
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: "Öğrenci",
                    value: studentName,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // ✅ Dinamik Tarih
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: "Tarih",
                    value: formattedDate,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // ✅ Dinamik Saat (gerçek bildirim saati)
                  _buildDetailRow(
                    icon: Icons.access_time_rounded,
                    label: "Saat",
                    value: time,
                    valueColor: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 14),

                  // Yer
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: "Yer",
                    value: location,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // Durum
                  _buildDetailRow(
                    icon: statusIcon,
                    label: "Durum",
                    value: status,
                    valueColor: statusColor,
                  ),

                  // ✅ Bildirim zamanı varsa göster
                  if (notifiedAtText.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildDetailRow(
                      icon: Icons.notifications_active_outlined,
                      label: "Bildirim Zamanı",
                      value: notifiedAtText,
                      valueColor: Colors.white70,
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Kapat",
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

  // ✅ Detay satırı widget'ı
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ YYYY-MM-DD → GG.AA.YYYY formatına çevir
  String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return "${parts[2]}.${parts[1]}.${parts[0]}";
      }
    } catch (_) {}
    return raw;
  }

  // ✅ Yeniden kullanılabilir glass dialog
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
    // ✅ Veliyi meetings sorgusunda tanımlamak için email kullan
    String parentEmail = _auth.currentUser!.email!;

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

                      bool hasPending =
                          _parentData?['hasPendingMeeting'] == true;
                      String studentName = studentData['name'] ?? 'Öğrenci';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Toplantı kartı artık meetings'ten gerçek veriyi çekiyor
                          if (hasPending)
                            _buildMeetingAlertCard(studentData, parentEmail),
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
                          ),

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

  // ✅ Butona basınca Firestore'dan toplantı verisini çekip popup aç
  Future<void> _fetchAndShowMeetingDetail(String parentEmail) async {
    try {
      // orderBy olmadan, sadece where ile sorgula → composite index gerekmez
      final QuerySnapshot snap = await _firestore
          .collection('meetings')
          .where('parentId', isEqualTo: parentEmail)
          .get();

      if (snap.docs.isEmpty) {
        if (mounted) {
          _showGlassDialog(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.orangeAccent,
            message: "Henüz görüşme kaydı bulunamadı.",
          );
        }
        return;
      }

      // En son oluşturulanı client-side sırala
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final aTs = (a.data() as Map)['createdAt'];
        final bTs = (b.data() as Map)['createdAt'];
        if (aTs == null || bTs == null) return 0;
        return (bTs as dynamic).compareTo(aTs as dynamic);
      });

      final meetingData = docs.first.data() as Map<String, dynamic>;
      if (mounted) _showMeetingDetailPopup(meetingData);
    } catch (e) {
      debugPrint("Görüşme detayı çekilirken hata: $e");
      if (mounted) {
        _showGlassDialog(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.redAccent,
          message: "Görüşme bilgisi yüklenemedi. Lütfen tekrar deneyin.",
        );
      }
    }
  }

  Widget _buildMeetingAlertCard(
    Map<String, dynamic> studentData,
    String parentEmail,
  ) {
    // Kart içindeki tarih/saat/yer için hafif bir FutureBuilder kullan
    // orderBy YOK → composite index sorunu yok
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('meetings')
          .where('parentId', isEqualTo: parentEmail)
          .get(),
      builder: (context, meetingSnapshot) {
        Map<String, dynamic>? meetingData;

        if (meetingSnapshot.hasData && meetingSnapshot.data!.docs.isNotEmpty) {
          // En son kaydı client-side bul
          final docs = meetingSnapshot.data!.docs.toList();
          docs.sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'];
            final bTs = (b.data() as Map)['createdAt'];
            if (aTs == null || bTs == null) return 0;
            return (bTs as dynamic).compareTo(aTs as dynamic);
          });
          meetingData = docs.first.data() as Map<String, dynamic>;
        }

        String displayDate = meetingData != null
            ? _formatDate(meetingData['date'] ?? '')
            : '--.--.----';
        String displayTime = meetingData?['time'] ?? '--:--';
        String displayLocation = meetingData?['location'] ?? 'Rehberlik Odası';

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
                  // Başlık
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

                  // Açıklama
                  Text(
                    "Yapay zeka analizlerimize göre öğrenciniz ${studentData["name"]} son ${studentData["negativeDayCount"]} gündür yoğun stres altındadır. Sınıf rehber öğretmeni sizinle bir görüşme planlamıştır.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ✅ Tarih / Saat / Yer bilgi satırları
                  _buildMiniInfoRow(
                    Icons.calendar_today_rounded,
                    "Tarih",
                    displayDate,
                  ),
                  const SizedBox(height: 6),
                  _buildMiniInfoRow(
                    Icons.access_time_rounded,
                    "Saat",
                    displayTime,
                    valueColor: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 6),
                  _buildMiniInfoRow(
                    Icons.location_on_outlined,
                    "Yer",
                    displayLocation,
                  ),
                  const SizedBox(height: 15),

                  // Butonlar
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ✅ Görüşme Detayı Butonu — her zaman tıklanabilir
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      // Tıklanınca Firestore'dan veri çek → popup aç
                      onPressed: () => _fetchAndShowMeetingDetail(parentEmail),
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      label: const Text(
                        "Görüşme Detayı",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Kart içi küçük bilgi satırı
  Widget _buildMiniInfoRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentStatusCard(
    String studentId,
    Map<String, dynamic> studentData,
    bool isCritical,
  ) {
    Color statusColor = isCritical ? Colors.redAccent : Colors.greenAccent;
    String rawStatus = studentData["currentStatus"] ?? "Bilinmiyor";
    String displayStatus = isCritical ? "Riskli" : rawStatus;

    String calculatedClass = studentId.startsWith('1') ? '12-A' : '12-B';
    String finalClass = studentData["class"] ?? calculatedClass;

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
                      "Sınıf: $finalClass",
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
