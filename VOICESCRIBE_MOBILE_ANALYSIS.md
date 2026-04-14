# VoiceScribe Mobile Uygulaması Analizi

## Genel Tanım
VoiceScribe, cihazda çalışan yapay zeka modelleri kullanarak ses kaydını gerçek zamanlı metne dönüştüren, özetleyen ve konuşmacı tanıma özelliklerine sahip bir mobil uygulamadır. React Native ile geliştirilmiş olup, Android ve iOS platformlarında çalışmaktadır.

## Mimarisi ve Teknoloji Yığını

### Frontend
- **React Native**: Ana uygulama framework'ü
- **TypeScript**: Tip güvenliği için
- **React Navigation**: Ekranlar arası gezinme
- **Zustand**: Durum yönetimi
- **gluestack-ui**: Kullanıcı arayüzü bileşenleri
- **NativeWind**: Stil yönetimi

### Native Modüller
- **whisper.cpp**: Sesin metne çevrilmesi için kullanılan cihaz içi model
- **llama.cpp**: Metin özetleme için kullanılan cihaz içi LLM
- **ECAPA-TDNN**: Konuşmacı tanıma için kullanılan model
- **React Native TurboModule**: Native kod ile JS arasında köprü

### Mimarik Yaklaşım
- **Clean Architecture**: Katmanlı mimari (presentation, domain, data)
- **Feature-based Organizasyon**: Özelliklere göre modüller (kayıt, transkripsiyon, özetleme, geçmiş, konuşma)
- **Offline-first**: Veriler cihazda depolanır, isteğe bağlı senkronizasyon

## Ana Özellikler

### 1. Ses Kaydı
- Arka planda çalışan native servislerle sürekli kayıt
- Android'de foreground servis, iOS'da background audio desteği
- Mikrofon izinleri ve sistem politikaları ile uyumlu
- 5-10 saniyelik parçalara bölünmüş ses kaydı

### 2. Gerçek Zamanlı Transkripsiyon
- whisper.cpp kullanarak cihazda sesin metne çevrilmesi
- GGML formatındaki modeller (tiny/base varyantları)
- Parça parça işleme ve gerçek zamanlı sonuçlar
- Model indirme ve yükleme döngüsü

### 3. Konuşmacı Tanıma
- ECAPA-TDNN küçük varyantı ile konuşmacı tanıma
- Yüzde 85 doğruluk oranı hedefi
- Yeni konuşmacı ekleme ve tanınmamış konuşmacıları işleme
- Benzerlik eşik değeri (varsayılan: 0.7)

### 4. Özetleme
- Cihazda çalışan LLM (llama.cpp) ile özetleme
- Hiyerarşik özetleme: parça özetleri → özet özetleri → nihai özet
- Bulut özetleme isteğe bağlı (fallback olarak)
- Phi-3 mini / Gemma 2B / TinyLlama gibi modeller destekleniyor

### 5. Geçmiş ve Veri Yönetimi
- SQLite ile yerel veri saklama
- Geçmiş oturumların listelenmesi ve filtrelenmesi
- Veri dışa aktarma ve silme (silme hakkı)
- Senkronizasyon için Laravel backend proxy

## Uygulama Yapısı

### Ana Bileşenler
- **App.tsx**: Uygulamanın ana girdi noktası
  - whisper modelinin hazırlanması
  - Transkripsiyon durumu yönetimi
  - Global olay dinleyicileri
  - Başlatma ekranı

### Özellik Bazlı Organizasyon
```
src/
├── features/
│   ├── recording/      (kayıt ekranı ve iş mantığı)
│   ├── transcript/     (transkripsiyon görüntüleme)
│   ├── summary/        (özetleme ve görüntüleme)
│   ├── history/        (geçmiş oturumlar)
│   └── speaker/        (konuşmacı yönetimi)
├── shared/             (ortak bileşenler, hizmetler, mağazalar)
└── native/             (native modül arayüzleri)
```

### Native Modüller
- **NativeAudioModule**: Ses kaydı ve transkripsiyon olayları
- **NativeWhisperModule**: Whisper modeliyle etkileşim
- **NativeLlamaModule**: Llama modeliyle etkileşim
- **NativeSpeakerModule**: Konuşmacı tanıma işlemleri

### Durum Yönetimi
- Zustand ile merkezi durum yönetimi
- Transkripsiyon, özet, kayıt durumları ayrı mağazalarda
- Transkripsiyon verileri serileştirilip cihazda saklanıyor

## Kullanıcı Arayüzü
- Modern, cam efektli arayüz (glassmorphism)
- Koyu tema desteği
- 5 ana sekme: Kayıt, Transkripsiyon, Özet, Geçmiş, Konuşmacılar
- Canlı dalga formu görselleştirme (planlanmış)
- Gerçek zamanlı transkripsiyon önizlemesi

## Güvenlik ve Gizlilik
- Transkripsiyonlar sadece cihazda çalışır (izin olmadan veri gönderilmez)
- Bulut özetleme isteğe bağlı ve açıkça belirtilir
- Yerel veriler şifreli olarak saklanır (SQLCipher)
- Mobil istemcide API anahtarı bulunmaz
- Laravel backend proxy üzerinden tüm bulut çağrıları yapılır

## Performans ve Stabilite
- Ağır işlemlemeler özel native thread'lerde çalışır
- React Native JS thread'i asla bloklanmaz
- Pil tüketimi ve termal koşullar için throttling
- Bellek kullanımı stabil kalır
- Uzun süreli (1-3 saat) kayıtlar için test edilmiştir

## Geliştirme Süreci ve Aşamalar

### Tamamlanan Aşamalar
1. **Aşama 1**: React Native projesi başlatma ve Clean Architecture kurulumu
2. **Aşama 2**: Native ses kaydı ve arka plan servisleri
3. **Aşama 3**: whisper.cpp entegrasyonu ile cihaz içi transkripsiyon
4. **Aşama 10**: gluestack-ui ile tam kullanıcı arayüzü oluşturma

### Devam Eden Aşamalar
5. **Aşama 4**: Hafif konuşmacı tanıma sistemi
6. **Aşama 5**: llama.cpp ile cihaz içi özetleme
7. **Aşama 6**: Bulut özetleme istemcisi
8. **Aşama 7**: Çevrimdışı öncelikli veri senkronizasyonu
9. **Aşama 8**: Performans ve arka plan optimizasyonları
10. **Aşama 9**: İzinler ve sistem politikaları
11. **Aşama 11**: Mimari kurallar ve kod organizasyonu
12. **Aşama 12**: Uzun süreli kayıt testleri ve kararlılık izleme
13. **Aşama 13**: Güvenlik ve gizlilik önlemleri
14. **Aşama 14**: Üretim derlemeleri hazırlığı

## GitHub Issue'lar Analizi

### Açık Issue'lar
- **Üretim Derlemeleri Hazırlığı**: Android ve iOS için üretim derlemeleri yapılandırması
- **Güvenlik ve Gizlilik Önlemleri**: Cihazda işleme, veri şifreleme, kullanıcı izinleri
- **Uzun Süreli Kararlılık Testleri**: 1-3 saatlik kayıtlar için bellek sızıntısı ve CPU kullanımı izleme
- **Mimari Kurallar**: Clean architecture prensiplerine uygunluk kontrolü
- **İzin ve Sistem Politikaları**: OEM özel ayarları ve pil optimizasyonları
- **Performans Optimizasyonları**: Arka planda çalışırken pil tüketimi ve termal koşullar
- **Çevrimdışı Öncelikli Senkronizasyon**: SQLite ile yerel veri yönetimi ve sunucu senkronizasyonu
- **Bulut Özetleme**: Laravel backend ile entegre özetleme hizmeti
- **Cihaz İçi Özetleme**: llama.cpp entegrasyonu
- **Konuşmacı Tanıma**: ECAPA-TDNN ile lightweight model entegrasyonu

### Kapanmış Issue'lar
- **Kullanıcı Arayüzü**: gluestack-ui ile modern arayüz oluşturma
- **whisper.cpp Entegrasyonu**: Cihaz içi transkripsiyon motoru
- **Native Ses Kaydı**: Android/iOS native modülleri ile arka plan ses kaydı
- **Proje Başlatma**: Clean Architecture ile React Native projesi kurulumu

## Sonuç
VoiceScribe, cihazda çalışan yapay zeka modelleri ile güçlü bir ses işleme uygulamasıdır. Offline-first yaklaşımıyla kullanıcı gizliliğini ön planda tutarken, hem yerel hem de bulut tabanlı AI hizmetlerinden faydalanabiliyor. Clean Architecture ve feature-based organizasyon sayesinde sürdürülebilir ve ölçeklenebilir bir yapıya sahip. Uzun vadeli hedefi, profesyonel düzeyde ses işleme yeteneklerini mobil cihazlarda sunmak.