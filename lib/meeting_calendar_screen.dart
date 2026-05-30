import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Görüşme Detayı Glass Popup
  void _showMeetingDetailPopup(Map<String, dynamic> meeting) {
    String date = meeting["date"] ?? "Belirtilmemiş";
    String time = meeting["time"] ?? "--:--";
    String location = meeting["location"] ?? "Rehberlik Odası A-102";
    String studentName = meeting["student"] ?? "Bilinmiyor";
    String parentName = meeting["parent"] ?? "Bilinmiyor";
    String status = meeting["status"] ?? "Beklemede";
    bool isCritical = meeting["isCritical"] ?? false;

    // Tarih formatla: 2026-05-23 → 23.05.2026
    String formattedDate = _formatDate(date);

    // Bildirim zamanı
    String notifiedAtText = '';
    if (meeting['notifiedAt'] != null) {
      try {
        DateTime dt = DateTime.parse(meeting['notifiedAt']);
        notifiedAtText =
            "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  "
            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    Color statusColor = _getStatusColor(status);
    IconData statusIcon;
    if (status == 'Onaylandı') {
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'Reddedildi') {
      statusIcon = Icons.cancel_outlined;
    } else {
      statusIcon = Icons.hourglass_top_rounded;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCritical
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.2),
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
                          color: isCritical
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_note_rounded,
                          color: isCritical
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Görüşme Detayı",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCritical)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Acil Görüşme",
                                  style: TextStyle(
                                    color: Colors.redAccent,
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

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 20),

                  // Öğrenci
                  _buildDetailRow(
                    icon: Icons.school_outlined,
                    label: "Öğrenci",
                    value: studentName,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // Veli
                  _buildDetailRow(
                    icon: Icons.people_outline_rounded,
                    label: "Veli",
                    value: parentName,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // Tarih
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: "Tarih",
                    value: formattedDate,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(height: 14),

                  // Saat
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

                  // Bildirim zamanı (varsa)
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

                  // Kapat butonu
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

  // Detay satırı
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
              const SizedBox(height: 3),
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

  // YYYY-MM-DD → GG.AA.YYYY
  String _formatDate(String raw) {
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        return "${parts[2]}.${parts[1]}.${parts[0]}";
      }
    } catch (_) {}
    return raw;
  }

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
          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('meetings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
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

                final meetings = snapshot.data!.docs;

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: _buildGlassInfoBar(meetings.length),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: meetings.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
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
                // Tarih, Saat, Acil badge
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

                // Öğrenci / Veli bilgisi
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

                // Durum + Görüşme Detayı butonu
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

                    // ✅ Artık SnackBar değil, glass popup açıyor
                    SizedBox(
                      height: 35,
                      child: ElevatedButton(
                        onPressed: () => _showMeetingDetailPopup(meeting),
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

  // ✅ Düzeltildi: "Onaylandı" ve "Reddedildi" tam eşleşme
  Color _getStatusColor(String status) {
    if (status == 'Onaylandı') return Colors.greenAccent;
    if (status == 'Reddedildi') return Colors.redAccent;
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
