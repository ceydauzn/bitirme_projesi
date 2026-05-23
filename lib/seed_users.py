import os
import firebase_admin
from firebase_admin import credentials, firestore, auth

# 1. FIREBASE BAĞLANTISI
print("Firebase'e bağlanılıyor...")
cred = credentials.Certificate("lib/firebase_key.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()
print("Firebase bağlantısı başarılı! 🚀\n")

print("Tüm Kullanıcılar (Öğretmenler ve 20 Veli) Authentication ve Firestore'a Ekleniyor...\n")
default_password = "123456"

# 2. ÖĞRETMENLERİ EKLE
teachers = {
    "ayse.yilmaz@okul.com": {"name": "Ayşe Yılmaz", "role": "ogretmen", "branch": "12-A"},
    "murat.demir@okul.com": {"name": "Murat Demir", "role": "ogretmen", "branch": "12-B"}
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
        print(f"Uyarı: {email} zaten var, veritabanı güncellenecek.")

    db.collection('users').document(email).set({
        'name': info['name'],
        'email': email,
        'role': info['role'],
        'branch': info['branch']
    })

print("-" * 30)

# 3. TÜM 20 VELİYİ EKLE
students_data = {
    # --- 12-A ŞUBESİ ---
    "101": {"studentName": "Ahmet Yılmaz", "parentName": "Mehmet Yılmaz", "parentEmail": "veli_ahmet@hotmail.com"},
    "102": {"studentName": "Elif Kaya", "parentName": "Ayşe Kaya", "parentEmail": "veli_elif@hotmail.com"},
    "103": {"studentName": "Can Demir", "parentName": "Mustafa Demir", "parentEmail": "veli_can@hotmail.com"},
    "104": {"studentName": "Ceren Çelik", "parentName": "Fatma Çelik", "parentEmail": "veli_ceren@hotmail.com"},
    "105": {"studentName": "Burak Şahin", "parentName": "Ali Şahin", "parentEmail": "veli_burak@hotmail.com"},
    "106": {"studentName": "Efe Öztürk", "parentName": "Hasan Öztürk", "parentEmail": "veli_efe@hotmail.com"},
    "107": {"studentName": "Zeynep Aydın", "parentName": "Emine Aydın", "parentEmail": "veli_zeynep@hotmail.com"},
    "108": {"studentName": "Emre Arslan", "parentName": "Hüseyin Arslan", "parentEmail": "veli_emre@hotmail.com"},
    "109": {"studentName": "Melis Koç", "parentName": "Hatice Koç", "parentEmail": "veli_melis@hotmail.com"},
    "110": {"studentName": "Arda Yıldız", "parentName": "İbrahim Yıldız", "parentEmail": "veli_arda@hotmail.com"},

    # --- 12-B ŞUBESİ ---
    "201": {"studentName": "Mert Bulut", "parentName": "Osman Bulut", "parentEmail": "veli_mert@hotmail.com"},
    "202": {"studentName": "Aslı Güneş", "parentName": "Selma Güneş", "parentEmail": "veli_asli@hotmail.com"},
    "203": {"studentName": "Deniz Erdoğan", "parentName": "Murat Erdoğan", "parentEmail": "veli_deniz@hotmail.com"},
    "204": {"studentName": "Begüm Çetin", "parentName": "Asuman Çetin", "parentEmail": "veli_begum@hotmail.com"},
    "205": {"studentName": "Volkan Yavuz", "parentName": "Kenan Yavuz", "parentEmail": "veli_volkan@hotmail.com"},
    "206": {"studentName": "İrem Kılıç", "parentName": "Reyhan Kılıç", "parentEmail": "veli_irem@hotmail.com"},
    "207": {"studentName": "Görkem Polat", "parentName": "Erhan Polat", "parentEmail": "veli_gorkem@hotmail.com"},
    "208": {"studentName": "Tuğba Aksu", "parentName": "Nedim Aksu", "parentEmail": "veli_tugba@hotmail.com"},
    "209": {"studentName": "Ozan Özdemir", "parentName": "Kemal Özdemir", "parentEmail": "veli_ozan@hotmail.com"},
    "210": {"studentName": "Simge Yaman", "parentName": "Belgin Yaman", "parentEmail": "veli_simge@hotmail.com"},
}

for student_id, info in students_data.items():
    parent_email = info['parentEmail']
    
    try:
        user = auth.create_user(
            email=parent_email,
            password=default_password,
            display_name=info['parentName']
        )
        print(f"Auth Kaydı Başarılı (Veli): {parent_email}")
    except auth.EmailAlreadyExistsError:
        print(f"Uyarı: {parent_email} zaten Auth panelinde var. Atlanıyor...")
    
    db.collection('users').document(parent_email).set({
        'name': info['parentName'],
        'email': parent_email,
        'role': 'veli',
        'studentId': student_id, 
        'studentName': info['studentName']
    })

print("\n🎉 İşlem Tamam! Eksik olan tüm veliler Auth ve Firestore'a eklendi!")