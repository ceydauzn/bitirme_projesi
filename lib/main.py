import os
# TensorFlow uyarılarını tamamen susturmak için en tepeye aldık (DeepFace uyanmadan önce çalışmalı)
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2' 

import cv2
from deepface import DeepFace
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# 1. FIREBASE BAĞLANTISI
print("Firebase'e bağlanılıyor...")
cred = credentials.Certificate("lib/firebase_key.json") # İndirdiğin JSON dosyasının adı
firebase_admin.initialize_app(cred)
db = firestore.client()
print("Firebase bağlantısı başarılı! 🚀")

# 2. KAMERAYI AÇ
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
print("Kamera açıldı. Analiz yapmak için 's' tuşuna, çıkmak için 'q' tuşuna basın.")
if not cap.isOpened():
    print("Kamera açılamadı!")
    exit()

while True:
    ret, frame = cap.read()
    if not ret:
        break

    # Ekrana bilgi yazdır
    cv2.putText(frame, "Analiz icin 's', Cikmak icin 'q'", (20, 40), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    
    cv2.imshow('Duygu Analizi (Yapay Zeka)', frame)

    key = cv2.waitKey(1) & 0xFF

    # 'q' tuşuna basılırsa çık
    if key == ord('q'):
        break
        
    # 's' tuşuna basılırsa (Scan/Tara) anlık duygu analizi yap
    elif key == ord('s'):
        print("\nYüz analiz ediliyor, lütfen bekleyin...")
        try:
            # 👇 İŞTE SİHİRLİ DOKUNUŞ BURASI: detector_backend='opencv' ile hafif moda geçtik!
            result = DeepFace.analyze(frame, actions=['emotion'], enforce_detection=False, detector_backend='opencv')
            
            # DeepFace bazen liste bazen sözlük döndürür, güvenli alalım
            emotion_data = result[0] if isinstance(result, list) else result
            dominant_emotion = emotion_data['dominant_emotion']
            
            print(f"Tespit Edilen Duygu: {dominant_emotion.upper()}")

            # Eğer duygu negatifse (stres, üzüntü, korku, kızgınlık)
            if dominant_emotion in ['sad', 'angry', 'fear']:
                print("Negatif duygu tespit edildi! Firebase güncelleniyor...")
                
                # Efe'nin (106 ID'li öğrenci) doküman referansını al
                student_ref = db.collection('students').document('106')
                student_doc = student_ref.get()
                
                if student_doc.exists:
                    current_days = student_doc.to_dict().get('negativeDayCount', 0)
                    new_days = current_days + 1
                    
                    # Veritabanını güncelle!
                    student_ref.update({
                        'negativeDayCount': new_days,
                        'currentStatus': 'Stresli / Kaygılı'
                    })
                    print(f"Firebase Güncellendi! Efe'nin yeni stres sayacı: {new_days}")
                    print("!!! TELEFONA BAK, ALARM ÇALMIŞ OLMALI !!!")
                else:
                    print("Öğrenci Firebase'de bulunamadı.")
            else:
                print("Öğrenci gayet iyi durumda (Pozitif/Nötr).")
                
        except Exception as e:
            print(f"Analiz sırasında bir hata oluştu: {e}")

cap.release()
cv2.destroyAllWindows()