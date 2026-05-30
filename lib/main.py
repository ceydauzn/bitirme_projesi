import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import cv2
from deepface import DeepFace
import firebase_admin
from firebase_admin import credentials, firestore

# --- AYARLAR ---
JSON_PATH = "lib/firebase_key.json" # Kendi json yolunu kontrol et

# 1. FIREBASE BAĞLANTISI
try:
    cred = credentials.Certificate(JSON_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase bağlantısı başarılı!")
except Exception as e:
    print(f"❌ Firebase bağlantı hatası: {e}")
    exit()

# --- SINIF VE ÖĞRENCİ LİSTESİ (101-110 ve 201-210 Arası) ---
school_data = {
    '12-A': ['101', '102', '103', '104', '105', '106', '107', '108', '109', '110'], 
    '12-B': ['201', '202', '203', '204', '205', '206', '207', '208', '209', '210']
}

class_names = list(school_data.keys())
current_class_idx = 0
current_student_idx = 0

current_class = class_names[current_class_idx]
current_student = school_data[current_class][current_student_idx]

# 2. KAMERA
camera = cv2.VideoCapture(0, cv2.CAP_DSHOW) # Hata verirse 0'ı 1 yap
if not camera.isOpened():
    print("❌ HATA: Kamera açılamadı!")
    exit()

current_emotion = "Bekleniyor..."

while True:
    ret, frame = camera.read()
    if not ret:
        print("⚠️ Kamera görüntüsü alınamadı!")
        break

    # EKRANA BİLGİ YAZDIRMA
    cv2.putText(frame, f"Konum: {current_class} (Sinif degis: 'c')", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
    cv2.putText(frame, f"Aktif Ogrenci: ID {current_student} (Siradaki: 'n')", (10, 60), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 0), 2)
    cv2.putText(frame, f"AI: 's' | Sim: 1:Stres 2:Mutlu 3:Odak 4:Notr 5:Uyku | Sifirla: 'r'", (10, 90), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 2)
    cv2.putText(frame, f"Son Analiz: {current_emotion}", (10, 130), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    
    cv2.imshow('AI Sinif Ici Duygu Takibi', frame)
    key = cv2.waitKey(1) & 0xFF
    
    if key == ord('q'):
        break
        
    # KAMERAYI BAŞKA SINIFA TAŞIMA ('c')
    elif key == ord('c'):
        current_class_idx = (current_class_idx + 1) % len(class_names)
        current_class = class_names[current_class_idx]
        current_student_idx = 0
        current_student = school_data[current_class][current_student_idx]
        current_emotion = "Bekleniyor..."
        print(f"\n🏢 Kamera {current_class} sınıfına taşındı!")

    # ÖĞRENCİ DEĞİŞTİRME ('n')
    elif key == ord('n'):
        students_in_class = school_data[current_class]
        current_student_idx = (current_student_idx + 1) % len(students_in_class)
        current_student = students_in_class[current_student_idx]
        current_emotion = "Bekleniyor..."
        print(f"\n🔄 Yeni Öğrenci ID: {current_student}")

    # RİSK PUANINI SIFIRLAMA ('r')
    elif key == ord('r'):
        try:
            current_emotion = 'Notr (Sifirlandi)' # Kameradaki yazıyı da güncelliyoruz
            db.collection('students').document(current_student).update({
                'negativeDayCount': 0,
                'currentStatus': 'Nötr' # Öğrencinin anlık durumunu da Nötr yapıyoruz!
            })
            print(f"🧹 {current_student} ID'li öğrencinin risk puanı ve durumu tamamen sıfırlandı!")
        except Exception as e:
            print(f"⚠️ Sıfırlama hatası: {e}")

    # YAPAY ZEKA ANALİZİ ('s')
    elif key == ord('s'):
        print(f"\n🔍 {current_class} - {current_student} analiz ediliyor...")
        try:
            # detector_backend='mtcnn' ekleyerek Windows dosya yolu hatasını bypass ettik
            result = DeepFace.analyze(frame, actions=['emotion'], enforce_detection=False, detector_backend='mtcnn')
            emotion = result[0]['dominant_emotion']
            
            if emotion in ['sad', 'angry', 'fear', 'disgust']: 
                status = 'Stresli / Kaygılı'
                db.collection('students').document(current_student).update({
                    'currentStatus': status,
                    'negativeDayCount': firestore.Increment(1)
                })
            elif emotion == 'happy': 
                status = 'Mutlu / Rahat'
                db.collection('students').document(current_student).update({'currentStatus': status})
            elif emotion == 'surprise': 
                status = 'Odaklanmış'
                db.collection('students').document(current_student).update({'currentStatus': status})
            else: 
                status = 'Nötr'
                db.collection('students').document(current_student).update({'currentStatus': status})
            
            current_emotion = f"{status} (AI)"
            print(f"🎯 Firebase Güncellendi: {status}")
        except Exception as e:
            print(f"⚠️ Analiz hatası: {e}")
            
    # --- 5 MODLU SİMÜLASYON ---
    elif key == ord('1'):
        current_emotion = 'Stresli / Kaygili (Simule)'
        db.collection('students').document(current_student).update({
            'currentStatus': 'Stresli / Kaygılı',
            'negativeDayCount': firestore.Increment(1)
        })
        print(f"🔥 Firebase: {current_student} Stresli yapıldı ve Risk Puanı arttı!")
        
    elif key == ord('2'):
        current_emotion = 'Mutlu / Rahat (Simule)'
        db.collection('students').document(current_student).update({'currentStatus': 'Mutlu / Rahat'})
        print(f"✨ Firebase: {current_student} Mutlu yapıldı!")
        
    elif key == ord('3'):
        current_emotion = 'Odaklanmis (Simule)'
        db.collection('students').document(current_student).update({'currentStatus': 'Odaklanmış'})
        print(f"🎯 Firebase: {current_student} Odaklanmış yapıldı!")
        
    elif key == ord('4'):
        current_emotion = 'Notr (Simule)'
        db.collection('students').document(current_student).update({'currentStatus': 'Nötr'})
        print(f"😐 Firebase: {current_student} Nötr yapıldı!")
        
    elif key == ord('5'):
        current_emotion = 'Uykulu / Sikilmis (Simule)'
        db.collection('students').document(current_student).update({
            'currentStatus': 'Uykulu / Sıkılmış',
            'negativeDayCount': firestore.Increment(1)
        })
        print(f"😴 Firebase: {current_student} Uykulu yapıldı ve Risk Puanı arttı!")

camera.release()
cv2.destroyAllWindows()