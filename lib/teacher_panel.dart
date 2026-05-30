import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/database_service.dart';
import 'role_selection_screen.dart';
import 'emotion_analysis_screen.dart';
import 'student_list_screen.dart';
import 'critical_situations_screen.dart';
import 'meeting_calendar_screen.dart';
import 'messages_screen.dart';

class TeacherPanel extends StatefulWidget {
  const TeacherPanel({super.key});

  @override
  State<TeacherPanel> createState() => _TeacherPanelState();
}

class _TeacherPanelState extends State<TeacherPanel> {
  String _teacherName = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    _fetchTeacherName();
  }

  Future<void> _fetchTeacherName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final name = await DatabaseService().getUserName(user.uid);
      if (mounted) {
        setState(() {
          _teacherName = name ?? user.email?.split('@')[0] ?? 'Hocam';
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Stack(
        children: [
          // 1. Üst Kısım: Kavisli Arka Plan
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appbar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Rehberlik Paneli",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'Çıkış Yap',
                          onPressed: () => _signOut(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // DİNAMİK KARŞILAMA KISMI
                  Text(
                    "Hoş Geldiniz, $_teacherName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Öğrenci durumları ve yapay zeka analizleri sistemde güncel.",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. İstatistik Kartı (Cam Efekti + Canlı Radar)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('students')
                                .snapshots(),
                            builder: (context, snapshot) {
                              String displayRiskli = "0";
                              String displayAnaliz = "0";

                              if (snapshot.hasData) {
                                int riskliOgrenciSayisi = 0;
                                int toplamAnalizSayisi = 0;

                                for (var doc in snapshot.data!.docs) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  int negativeDays =
                                      data['negativeDayCount'] ?? 0;

                                  toplamAnalizSayisi += negativeDays;

                                  if (negativeDays >= 3) {
                                    riskliOgrenciSayisi++;
                                  }
                                }

                                displayRiskli = riskliOgrenciSayisi.toString();
                                displayAnaliz = toplamAnalizSayisi.toString();
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    Icons.analytics,
                                    "Yeni Analiz",
                                    displayAnaliz,
                                    Colors.greenAccent,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  _buildStatItem(
                                    Icons.warning_amber_rounded,
                                    "Riskli Durum",
                                    displayRiskli,
                                    Colors.redAccent,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. Menü Kartları
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildModernCard(
                          Icons.insert_chart_rounded,
                          "Duygu\nAnalizleri",
                          const Color(0xFF4776E6),
                          const Color(0xFF8E54E9),
                        ),
                        _buildModernCard(
                          Icons.people_alt_rounded,
                          "Öğrenci\nListesi",
                          const Color(0xFFFF8008),
                          const Color(0xFFFFC837),
                        ),
                        _buildModernCard(
                          Icons.calendar_month_rounded,
                          "Görüşme\nTakvimi",
                          const Color(0xFF11998E),
                          const Color(0xFF38EF7D),
                        ),
                        _buildModernCard(
                          Icons.crisis_alert_rounded,
                          "Kritik\nDurumlar",
                          const Color(0xFFED213A),
                          const Color(0xFF93291E),
                        ),
                        _buildModernCard(
                          Icons.mark_email_unread_rounded,
                          "Mesaj\nKutusu",
                          const Color(0xFF0072ff),
                          const Color(0xFF00c6ff),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard(
    IconData icon,
    String title,
    Color grad1,
    Color grad2,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: grad1.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            if (title.contains("Duygu")) {
              // 👇 HATALI KABLO BURADA ONARILDI: gmail.com olarak güncellendi 👇
              String currentUserEmail =
                  FirebaseAuth.instance.currentUser?.email ?? "";
              String targetClass = (currentUserEmail == "rehberlik2@gmail.com")
                  ? "12-B"
                  : "12-A";

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmotionAnalysisScreen(assignedClass: targetClass),
                ),
              );
              // 👆 BİTİŞ 👆
            } else if (title.contains("Öğrenci")) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentListScreen(),
                ),
              );
            } else if (title.contains("Takvim")) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MeetingCalendarScreen(),
                ),
              );
            } else if (title.contains("Kritik")) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CriticalSituationsScreen(),
                ),
              );
            } else if (title.contains("Mesaj")) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              );
            } else {
              debugPrint("$title sayfası henüz yapım aşamasında");
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [grad1, grad2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: grad1.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const Spacer(),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
