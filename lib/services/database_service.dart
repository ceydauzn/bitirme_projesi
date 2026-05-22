import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // YENİ: Kayıt olurken Rol, Sınıf ve Öğrenci No verilerini de alıyoruz
  Future<void> saveUserData(
    String uid,
    String name,
    String email,
    String role, {
    String? className,
    String? studentId,
  }) async {
    try {
      // Temel kullanıcı bilgileri
      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'role': role, // rehberlik, ogretmen veya veli
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Eğer öğretmense sınıfını da ekle
      if (role == 'ogretmen' && className != null) {
        userData['class'] = className;
      }
      // Eğer veliyse öğrenci numarasını ekle
      else if (role == 'veli' && studentId != null) {
        userData['studentId'] = studentId;
      }

      await _db.child('users').child(uid).set(userData);
      debugPrint("Veritabanına detaylı kayıt başarılı!");
    } catch (e) {
      debugPrint("Veritabanı kayıt hatası: $e");
    }
  }

  // Veri Çekme: Kullanıcının adını getirir
  Future<String?> getUserName(String uid) async {
    try {
      final snapshot = await _db.child('users').child(uid).child('name').get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
    }
    return null;
  }
}
