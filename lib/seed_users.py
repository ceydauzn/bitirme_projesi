import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

print("Firebase'e bağlanılıyor...")
cred = credentials.Certificate("lib/firebase_key.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()
print("Firebase bağlantısı başarılı! 🚀\n")

print("Kullanıcılar 'rehberlik' Rolüyle Yeniden Tohumlanıyor...\n")
default_password = "123456"

# ROLLERİ 'rehberlik' OLARAK GÜNCELLEDİK
teachers = {
    "rehberlik1@gmail.com": {"name": "Rehberlik Uzmanı 1", "role": "rehberlik", "branch": "12-A"},
    "rehberlik2@gmail.com": {"name": "Rehberlik Uzmanı 2", "role": "rehberlik", "branch": "12-B"}
}

for email, info in teachers.items():
    try:
        user = auth.create_user(
            email=email,
            password=default_password,
            display_name=info['name']
        )
        print(f"Auth Kaydı Başarılı: {email}")
    except auth.EmailAlreadyExistsError:
        pass

    db.collection('users').document(email).set({
        'name': info['name'],
        'email': email,
        'role': info['role'], # Artık doğrudan 'rehberlik' yazıyor
        'branch': info['branch']
    })

print("-" * 30)

students_data = {
    "101": {"studentName": "Ahmet Yılmaz", "parentName": "Mehmet Yılmaz", "parentEmail": "veli_ahmet@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "102": {"studentName": "Elif Kaya", "parentName": "Ayşe Kaya", "parentEmail": "veli_elif@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "103": {"studentName": "Can Demir", "parentName": "Mustafa Demir", "parentEmail": "veli_can@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "104": {"studentName": "Ceren Çelik", "parentName": "Fatma Çelik", "parentEmail": "veli_ceren@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "105": {"studentName": "Burak Şahin", "parentName": "Ali Şahin", "parentEmail": "veli_burak@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "106": {"studentName": "Efe Öztürk", "parentName": "Hasan Öztürk", "parentEmail": "veli_efe@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "107": {"studentName": "Zeynep Aydın", "parentName": "Emine Aydın", "parentEmail": "veli_zeynep@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "108": {"studentName": "Emre Arslan", "parentName": "Hüseyin Arslan", "parentEmail": "veli_emre@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "109": {"studentName": "Melis Koç", "parentName": "Hatice Koç", "parentEmail": "veli_melis@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "110": {"studentName": "Arda Yıldız", "parentName": "İbrahim Yıldız", "parentEmail": "veli_arda@hotmail.com", "counselor": "rehberlik1@gmail.com"},
    "201": {"studentName": "Mert Bulut", "parentName": "Osman Bulut", "parentEmail": "veli_mert@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "202": {"studentName": "Aslı Güneş", "parentName": "Selma Güneş", "parentEmail": "veli_asli@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "203": {"studentName": "Deniz Erdoğan", "parentName": "Murat Erdoğan", "parentEmail": "veli_deniz@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "204": {"studentName": "Begüm Çetin", "parentName": "Asuman Çetin", "parentEmail": "veli_begum@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "205": {"studentName": "Volkan Yavuz", "parentName": "Kenan Yavuz", "parentEmail": "veli_volkan@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "206": {"studentName": "İrem Kılıç", "parentName": "Reyhan Kılıç", "parentEmail": "veli_irem@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "207": {"studentName": "Görkem Polat", "parentName": "Erhan Polat", "parentEmail": "veli_gorkem@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "208": {"studentName": "Tuğba Aksu", "parentName": "Nedim Aksu", "parentEmail": "veli_tugba@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "209": {"studentName": "Ozan Özdemir", "parentName": "Kemal Özdemir", "parentEmail": "veli_ozan@hotmail.com", "counselor": "rehberlik2@gmail.com"},
    "210": {"studentName": "Simge Yaman", "parentName": "Belgin Yaman", "parentEmail": "veli_simge@hotmail.com", "counselor": "rehberlik2@gmail.com"},
}

for student_id, info in students_data.items():
    parent_email = info['parentEmail']
    try:
        user = auth.create_user(email=parent_email, password=default_password, display_name=info['parentName'])
    except auth.EmailAlreadyExistsError:
        pass
    
    db.collection('users').document(parent_email).set({
        'name': info['parentName'],
        'email': parent_email,
        'role': 'veli',
        'studentId': student_id, 
        'studentName': info['studentName']
    })
    db.collection('students').document(student_id).update({
        'counselorEmail': info['counselor']
    })

print("\n🎉 Veritabanı rolleri 'rehberlik' olarak tamamen temizlendi!")