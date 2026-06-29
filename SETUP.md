# Couple App — راهنمای ڕاستەکردنەوە

## ١. دروستکردنی پرۆژەی Firebase

١. بڕۆ بۆ [console.firebase.google.com](https://console.firebase.google.com)
٢. پرۆژەیەکی نوێ دروست بکە
٣. **Authentication** چالاک بکە:
   - بڕۆ بۆ Authentication → Sign-in method
   - Email/Password چالاک بکە
٤. **Firestore Database** دروست بکە:
   - بڕۆ بۆ Firestore Database → Create Database
   - Start in **production mode** هەڵبژێرە
   - بعد Rules کۆپی بکە لە `firestore.rules` و paste بکە

---

## ٢. فلۆتەر نصب بکە

ئەگەر هێشتا نصبت نەکردووە:

```powershell
# Windows PowerShell
winget install Google.FlutterSDK
# یان دەنرێت بۆ: https://docs.flutter.dev/get-started/install/windows
```

دوای نصب:
```powershell
flutter doctor
```

---

## ٣. FlutterFire CLI نصب بکە و Configure بکە

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR-FIREBASE-PROJECT-ID
```

ئەمە `lib/firebase_options.dart` ی ڕاستەکی دروست دەکات.

---

## ٤. Assets دروست بکە

```powershell
New-Item -ItemType Directory -Force assets/images
New-Item -ItemType Directory -Force assets/animations
```

---

## ٥. Packages دامەزرێنە

```powershell
flutter pub get
```

---

## ٦. Android — google-services.json

١. لە Firebase Console: Project Settings → Your Apps → Android
٢. `com.couple.coupleApp` تۆمار بکە
٣. `google-services.json` دانلۆد بکە
٤. بیخە `android/app/google-services.json`

---

## ٧. android/build.gradle مۆدیفای بکە

لە `android/build.gradle` (پرۆژە-ئاست):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

لە `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

لە `android/app/build.gradle`، `minSdkVersion` بکە `21`:
```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

---

## ٨. ئەپەکە ڕابکە

```powershell
flutter run
```

---

## تایبەتمەندییەکان

| تایبەتمەندی | وردەکاری |
|---|---|
| 🔐 Auth | Sign Up / Login بە Email + Password |
| 💑 Couple Code | User A کۆد دروست دەکات، User B داخڵ دەکات |
| ❤️ Likes/Dislikes | هەر کەسێک داخڵ دەکات، لای هەردووکیان دەرکەوێت |
| 👨‍👩‍👧 خێزان | ئەندامانی خێزان بەرواری لەدایکبوون |
| 📚 وانەکان | وانەی پێکەوە + ئاگادارکردنەوە |
| ✅ تاسکەکان | تاسک بۆ خۆت یان هاوسەرەکەت |
| ❓ کوئیز | پرسیار دروست بکە، هاوسەرت وەڵامی بداتەوە |
