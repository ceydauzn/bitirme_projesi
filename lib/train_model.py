import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout

print("Yapay Zeka Mimarisi İnşa Ediliyor...")

# Modeli oluşturuyoruz (Beynin Katmanları)
model = Sequential()

# 1. Evrişim (Gözlem) Katmanı: Görüntüdeki çizgileri ve kenarları öğrenir
model.add(Conv2D(32, kernel_size=(3, 3), activation='relu', input_shape=(48, 48, 1)))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.25)) # Ezberlemeyi önlemek için nöronların %25'ini rastgele kapatıyoruz

# 2. Evrişim Katmanı: Daha karmaşık şekilleri (gözler, kaş çatılması) öğrenir
model.add(Conv2D(64, kernel_size=(3, 3), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.25))

# 3. Evrişim Katmanı: İyice derine iniyoruz
model.add(Conv2D(128, kernel_size=(3, 3), activation='relu'))
model.add(MaxPooling2D(pool_size=(2, 2)))
model.add(Dropout(0.25))

# Karar Aşamasına Geçiş (Matrisi tek boyutlu diziye düzleştirme)
model.add(Flatten())

# Tam Bağlantılı (Dense) Sinir Ağı Katmanı: Öğrenilen şekilleri duygularla eşleştirir
model.add(Dense(128, activation='relu'))
model.add(Dropout(0.5))

# Çıkış Katmanı: 7 Farklı Duygu için 7 nöron (Softmax bize olasılık dönecek: %80 Üzgün, %20 Nötr gibi)
model.add(Dense(7, activation='softmax'))

# Modelin özetini ekrana bas
model.summary()
from tensorflow.keras.preprocessing.image import ImageDataGenerator

print("\nVeri Seti Yukleniyor...")

# 1. Fotoğrafları Piksellere Böl ve Normalleştir
datagen = ImageDataGenerator(rescale=1./255)

# 2. Eğitim Verilerini (Train) Al
train_set = datagen.flow_from_directory(
    'dataset/train', # İndirdiğin klasörün yolu
    target_size=(48, 48),
    batch_size=64,
    color_mode='grayscale',
    class_mode='categorical'
)

# 3. Test Verilerini (Test) Al
test_set = datagen.flow_from_directory(
    'dataset/test',
    target_size=(48, 48),
    batch_size=64,
    color_mode='grayscale',
    class_mode='categorical'
)

# 4. Modeli Derle
print("\nModel Derleniyor...")
model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

# 5. EĞİTİMİ BAŞLAT!
print("\nEgitim Basliyor! (Epochs)")
history = model.fit(train_set, epochs=10, validation_data=test_set)

# 6. Eğitilen Modeli Kaydet
model.save('benim_modelim.h5')
print("\nModel basariyla egitildi ve 'benim_modelim.h5' olarak kaydedildi! 🎉")