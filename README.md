# JobsStory 🎬💼

> **"Don't send a CV. Tell your story."**
> منصة توظيف عالمية: 60 ثانية فيديو بدل السيرة الورقية. موظفو الموارد البشرية يكتشفون المواهب بالتمرير، والباحثون يروون قصصهم بثقة.

## الحالة الحالية

- ✅ **Phase 0** — بنية Flutter + هوية + ترحيب + اختيار الدور + CI
- ✅ **Firebase مربوط** — مشروع `jobsstory-app` (Auth + Firestore + Storage بانتظار آمنية المنصات)
- ⏭️ **المرحلة 1** (التالي) — تسجيل/دخول + اختيار الدور + قواعد أمان Firestore

- فلتر بروجكت (Android + iOS) عبر **Flutter 3.29**
- هوية بصرية: ثيم داكن نابض (بنفسجي/وردي/أزرق) `lib/core/theme/app_theme.dart`
- **عربي أولاً**: دعم RTL + تطبيق يبدأ بالعربية تلقائياً
- شاشة ترحيب (جرادينت + شعار + CTA) واختيار الدور (Seeker/Recruiter)
- Firebase جاهز للتوصيل (نداء `AppBootstrap` لكنه يتخطّى التهيئة حتى تُربط Firebase)
- **CI تلقائي**: `flutter analyze` + `flutter test` + بناء APK / iOS في Github Actions

## هيكل المشروع

```
lib/
├── main.dart                  # نقطة الدخول (عربي أولاً، RTL)
├── firebase_options.dart      # يولد تلقائياً عبر flutterfire configure
├── core/
│   ├── config/app_strings.dart
│   ├── firebase/bootstrap.dart
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
└── features/
    ├── welcome/welcome_screen.dart
    └── onboarding/onboarding_screen.dart
```

## التشغيل محلياً

```bash
flutter pub get
flutter run          # اختر جهازك (Android/iOS/Chrome)
flutter test         # الاختبارات
flutter analyze      # الفحوصات
```

## ربط Firebase (خطوة حسابك المطلوبة)

1. أنشئ مشروعاً في [console.firebase.google.com](https://console.firebase.google.com)
2. فعّل: **Authentication** (Email + Google + Phone)، **Firestore Database**، **Storage**
3. ثبّت أدوات FlutterFire:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. من جذر المشروع:
   ```bash
   flutterfire configure
   ```
   - اختر رقم مشروعك × اندرويد (com.jobsstory.jobsstory) × iOS (com.jobsstory.jobsstory)
   - سيولّد `lib/firebase_options.dart` تلقائياً
5. أعد التشغيل — سيبدأ التطبيق بالربط الحقيقي مع Firebase.

> قبل هذه الخطوة التطبيق يعمل في "وضع المعاينة" بدون Firebase لأجل تطوير الواجهات.

## Roadmap القادم

| المرحلة | المحتوى |
|---|---|
| P1 | تسجيل/دخول + اختيار الدور + قواعد الأمان |
| P2 | استوديو القصة: كاميرا 60 ثانية + رفع لـ Storage |
| P3 | تغذية عمودية + Like/Save/Share/Report + ملف الباحث |
| P4 | وظائف + تقديم + إشعارات + رسائل |
| P5 | إشراف محتوى + AI moderation (Video Intelligence + Whisper) |
| P6 | جاهزية المتجرين (الخصوصية، Data Safety، سياسات) |
| P7 | بيتا → إطلاق عام |

التفاصيل الكاملة: `../JOBSSTORY_MOBILE_ROADMAP.md`