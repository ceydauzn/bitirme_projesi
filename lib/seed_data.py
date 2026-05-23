import os
import firebase_admin
from firebase_admin import credentials, firestore

# 1. FIREBASE BAĞLANTISI
print("Firebase'e bağlanılıyor...")
cred = credentials.Certificate("lib/firebase_key.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()
print("Firebase bağlantısı başarılı! 🚀\n")

# 2. GERÇEKÇİ ÖĞRENCİ, VELİ VE REHBERLİK VERİ SETİ
students_data = {
    # --- 12-A ŞUBESİ (Rehberlik Uzmanı: Ayşe Yılmaz) ---
    "101": {"name": "Ahmet Yılmaz", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Mehmet Yılmaz", "parentEmail": "veli_ahmet@hotmail.com"},
    "102": {"name": "Elif Kaya", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Ayşe Kaya", "parentEmail": "veli_elif@hotmail.com"},
    "103": {"name": "Can Demir", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Mustafa Demir", "parentEmail": "veli_can@hotmail.com"},
    "104": {"name": "Ceren Çelik", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Fatma Çelik", "parentEmail": "veli_ceren@hotmail.com"},
    "105": {"name": "Burak Şahin", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Ali Şahin", "parentEmail": "veli_burak@hotmail.com"},
    "106": {"name": "Efe Öztürk", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Hasan Öztürk", "parentEmail": "veli_efe@hotmail.com"},
    "107": {"name": "Zeynep Aydın", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Emine Aydın", "parentEmail": "veli_zeynep@hotmail.com"},
    "108": {"name": "Emre Arslan", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Hüseyin Arslan", "parentEmail": "veli_emre@hotmail.com"},
    "109": {"name": "Melis Koç", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "Hatice Koç", "parentEmail": "veli_melis@hotmail.com"},
    "110": {"name": "Arda Yıldız", "branch": "12-A", "counselor": "Ayşe Yılmaz", "parentName": "İbrahim Yıldız", "parentEmail": "veli_arda@hotmail.com"},

    # --- 12-B ŞUBESİ (Rehberlik Uzmanı: Murat Demir) ---
    "201": {"name": "Mert Bulut", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Osman Bulut", "parentEmail": "veli_mert@hotmail.com"},
    "202": {"name": "Aslı Güneş", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Selma Güneş", "parentEmail": "veli_asli@hotmail.com"},
    "203": {"name": "Deniz Erdoğan", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Murat Erdoğan", "parentEmail": "veli_deniz@hotmail.com"},
    "204": {"name": "Begüm Çetin", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Asuman Çetin", "parentEmail": "veli_begum@hotmail.com"},
    "205": {"name": "Volkan Yavuz", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Kenan Yavuz", "parentEmail": "veli_volkan@hotmail.com"},
    "206": {"name": "İrem Kılıç", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Reyhan Kılıç", "parentEmail": "veli_irem@hotmail.com"},
    "207": {"name": "Görkem Polat", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Erhan Polat", "parentEmail": "veli_gorkem@hotmail.com"},
    "208": {"name": "Tuğba Aksu", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Nedim Aksu", "parentEmail": "veli_tugba@hotmail.com"},
    "209": {"name": "Ozan Özdemir", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Kemal Özdemir", "parentEmail": "veli_ozan@hotmail.com"},
    "210": {"name": "Simge Yaman", "branch": "12-B", "counselor": "Murat Demir", "parentName": "Belgin Yaman", "parentEmail": "veli_simge@hotmail.com"},
}

print("Veri tabanına toplu veri yazma işlemi başlatılıyor...")

# 3. VERİLERİ FİREBASE FIRESTORE'A YÜKLEME DÖNGÜSÜ
for student_id, info in students_data.items():
    student_ref = db.collection('students').document(student_id)
    
    # Mevcut Flutter altyapını bozmamak için gerekli alanları birebir oluşturuyoruz
    student_ref.set({
        'name': info['name'],
        'branch': info['branch'],
        'counselorName': info['counselor'],
        'parentName': info['parentName'],
        'parentEmail': info['parentEmail'],
        'currentStatus': 'Nötr',          # Canlı analiz başlayana kadar varsayılan
        'negativeDayCount': 0             # Başlangıçta herkesin stres sayacı sıfır
    })
    print(f"ID: {student_id} | {info['name']} ({info['branch']}) -> Başarıyla eklendi.")

print("\n🎉 Tebrikler! 2 Şube, 20 Öğrenci, Veli ve Rehberlik atamaları Firestore'a başarıyla yüklendi!")