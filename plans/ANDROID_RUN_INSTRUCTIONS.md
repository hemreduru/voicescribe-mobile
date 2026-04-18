# Android Çalıştırma ve Güncelleme Rehberi

Bu doküman, `VoiceScribe Mobile` projesini Android üzerinde nasıl çalıştıracağınızı ve hangi durumlarda yeniden APK oluşturmanız gerektiğini özetler.

## 1. Hızlı geliştirme döngüsü: Metro + Debug

JS tarafında değişiklik yapıyorsanız her seferinde APK yeniden derlemek zorunda değilsiniz.

1. Metro server başlatın:
   ```bash
   npx react-native start
   ```
2. Cihazın Metro portuna erişmesini sağlayın:
   ```bash
   adb reverse tcp:8081 tcp:8081
   ```
3. Uygulamayı debug modda çalıştırın:
   ```bash
   npx react-native run-android
   ```

Bu yöntemle JS kodunu hızlıca iterasyonla test edebilirsiniz.

## 2. Standalone APK (Metro olmadan) çalıştırma

Eğer uygulamanızın Metro server'a bağlı olmadan çalışmasını istiyorsanız, release APK üretip yüklemeniz gerekir.

1. Android dizininde release APK oluşturun:
   ```bash
   cd android && ./gradlew assembleRelease
   ```
2. Oluşan APK'yı cihaza yükleyin:
   ```bash
   adb install -r app/build/outputs/apk/release/app-release.apk
   ```
3. Uygulamayı başlatın:
   ```bash
   adb shell am start -n com.voicescribe.app/.MainActivity
   ```

Bu süreç `createBundleReleaseJsAndAssets` aşamasını içerir ve JS bundle APK içine gömülür.

## 3. Hangi güncellemelerde ne yapılmalı?

- **Sadece JS değişikliği**: Metro + debug modu yeterlidir. APK yeniden yüklemeden hızlıca test edebilirsiniz.
- **Native değişiklikler** (Kotlin, Java, C++, CMake, Gradle ayarları gibi): APK yeniden derlenmeli ve cihaza yüklenmelidir.
- **Yeni native modül veya bağımlılık ekleme**: Yine tam build gerekir.

## 4. Mevcut cihaza kurulu paketi kontrol etmek

Kurulu paket bilgisini almak için:

```bash
adb shell pm path com.voicescribe.app
```

veya kurulu paketi kontrol etmek için:

```bash
adb shell pm list packages | grep com.voicescribe.app
```

## 5. Önerilen pratikler

- Geliştirme sırasında `npx react-native start` ve `adb reverse tcp:8081 tcp:8081` kullanarak hızlı iterasyon yapın.
- Proje kökünde `package.json` içinde bir `android` scripti var, ancak release/standalone için doğrudan Android Gradle komutlarını kullanmak daha güvenilir olabilir.
- CI/CD ortamında release APK üretimini otomatikleştirin.
- Eğer uygulama sürekli kapanıyorsa, `adb logcat` çıktısını filtreleyip hatayı inceleyin.

## 6. Özet

- `npx react-native run-android`: genellikle debug modda Metro ile çalışır.
- `./gradlew assembleRelease`: Metro'ya bağlı olmayan standalone APK üretir.
- Her güncellemede tekrar APK kurmak gerekmez; JS-only değişikliklerde Metro ile devam edebilirsiniz.
- Native düzeyde değişiklik olduğunda APK yeniden derlenmelidir.
