# JobStory Firebase Setup — مكتمل ✅

تم تنفيذ الخطوات حتى البناء الناجح على Android. هذه الصفحة = دليل المرجع والاستمرار.

## ⚠️ ناقص: ملف iOS (في انتظاره عند بناء iOS)

`flutterfire configure` لم ينزّل `GoogleService-Info.plist` تلقائياً. لبنائه لـiPhone في ما بعد:

1. [console.firebase.google.com](https://console.firebase.google.com) → مشروع `jobsstory-app`
2. ⚙️ **Project settings** → **Your apps** → تطبيق iOS (`com.jobsstory.jobsstory`)
3. اضغط **Download GoogleService-Info.plist**
4. ضع الملف هنا: `ios/Runner/GoogleService-Info.plist` (بجانب Runner)
5. افتح `ios/Runner.xcworkspace` في Xcode ثم أضف الملف للمشروع إذا لم يلتقطه تلقائياً.

> لا يمنع هذا البناء الحالي ولا عمل Android.

---

## 1) أنشئ مشروع Firebase

1. افتح [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → الاسم: `jobsstory` (أو `jobsstory-app` إن كان محجوزاً)
3. أطفئ Google Analytics (أسرع) أو اتركه (إحصائيات مجانية — يُنصح بتركه)
4. انتظر التجهيز ثم **Continue**

## 2) فعّل الخدمات الثلاث

| الخدمة | من أين | النموذج/الوضع |
|---|---|---|
| **Authentication** | Build → Authentication → Get started | فعّل: Email/Password + Google + Phone |
| **Firestore Database** | Build → Firestore → Create database | Production mode + منطقة قريبة (مثال `europe-west1` أو `me-west1`) |
| **Storage** | Build → Storage → Get started | المنطقة نفسها، الرفع على الوضع الافتراضي |

> ستفعل **Security Rules** لاحقاً في المرحلة 1 (اقطع الوصول الافتراضي فوراً):
> في Firestore → Rules → الصق:
> ```
> rules_version = '2';
> service cloud.firestore {
>   match /databases/{database}/documents {
>     match /{document=**} { allow read, write: if false; }
>   }
> }
> ```
> وفي Storage → Rules → الصق:
> ```
> rules_version = '2';
> service firebase.storage {
>   match /b/{bucket}/o {
>     match /{allPaths=**} { allow read, write: if false; }
>   }
> }
> ```
> (نفتحها آمنةً واحدة واحدة أثناء بناء المراحل).

## 3) ثبّت أدوات FlutterFire

```powershell
dart pub global activate flutterfire_cli
```

## 4) شغّل flutterfire configure

من جذر المشروع (`...\Default Project\jobsstory`):

```powershell
flutterfire configure
```

- اختر **رقم مشروعك** (jobsstory)
- للأسئلة عن المنصات: فعّل **android + ios** (واستخدم Enter لأي تلميحات)
- مطلوب اختيار/إنشاء:
  - Android app ↔ package: `com.jobsstory.jobsstory`
  - iOS app ↔ bundle: `com.jobsstory.jobsstory`

**ماذا سيحدث:**
- إنشاء `lib/firebase_options.dart` بالقيم الحقيقية
- نسخ `google-services.json` إلى `android/app/`
- نسخ `GoogleService-Info.plist` إلى `ios/Runner/`

## 5) فعّل google-services في gradle (خطوة يدوية قصيرة)

> (مضبوطة عمداً حتى لا يكسر البناء قبل وجود الملف).

عدّل **سطراً واحداً في سطرين**:

**`android/build.gradle.kts`** — في أول السطر:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

**`android/app/build.gradle.kts`** — داخل `plugins { ... }`:
```kotlin
id("com.google.gms.google-services")
```

## 6) تحقق أن gradle يبنى بعد الربط

```powershell
flutter build apk --debug
```
يجب أن ينجح (minSdk أصبح 24 ضمن قيمة جاهزة). إن صادفت أي خلل، راجع قسم "عند العطل".

## 7) تحقق أن التطبيق يربط فعلاً

```powershell
flutter run
```

- ستفتح شاشة الترحيب كالمعتاد، وسترى في ترمينل flutter سطراً مثل
  `Firebase InitializeApp ...` دون أخطاء (لا توجد مؤشرات تحطّم).
- اختبار أسرع: عدّل `Firebase.initializeApp` في `main.dart` لأي نص ترحيبي —
  سيُلغى التطبيق وتقتل العملية إذا فشل الربط (على عكس وضع المعاينة).

## 8) نهر قواعد التخزين (Storage rules) — للتحضير للمرحلة 2

```bash
# إنشاء قواعد تنظيم المجلدات قبل إطلاق المرحلة 2
storage.rules:
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/stories/{allPaths=**} {
      allow read: if request.auth.uid == uid;
      allow write: if request.auth.uid == uid;
    }
  }
}
```
(تُنشر مع قواعد أمان Firestore في المرحلة 1 — أنت الآن مُهيأ فقط.)

---

## عند العطل

| المشكلة | الحل |
|---|---|
| `MissingPluginException` أثناء تصحيح الأخطاء | `flutter clean` ثم `flutter pub get` ثم `flutter run` |
| خطأ minSdk | تأكد أن `android/app/build.gradle.kts` فيه `minSdk = 24` (تم تعديله) |
| Firebase غير موجود في `firebase_options.dart` | أعد `flutterfire configure` واختر المشروع الصحيح |
| iOS: خطأ bundle id عند configure | أنشئ تطبيق iOS في Firebase يدوياً بـ `com.jobsstory.jobsstory` ثم أعد config