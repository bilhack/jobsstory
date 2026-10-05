# JobsStory — لوحة تحكم المشرف (ويب)

لوحة إدارة تفاعلية مبنية بـ React + Vite، تتصل بالتطبيق عبر واجهة
Cloud Functions الآمنة في `../functions/admin.js`.

## لماذا Cloud Functions؟
كل بيانات التطبيق في Firestore محمية بروابط مخصصة (العميل لا يقرأ إلا بياناته).
عمليات الإدارة تنفّذ من خوادمنا فقط عبر دوال callable تتحقق من:
1. تسجيل الدخول (`requireAuth`).
2. وثيقة المستخدم تحمل `isAdmin: true`.

## quickest path — local emulator (free, no Blaze)

Cloud Functions can only be deployed on the **Blaze** plan, so the panel ships
with an emulator mode that runs the whole backend on your machine:

```
# 1) start the emulators (Auth 9099, Functions 5001, Firestore 8080, UI 4000)
firebase emulators:start --only auth,firestore,functions --project jobsstory-app

# 2) in another terminal — fill the emulator with demo data
cd functions && node seed-emulator.js

# 3) verify the whole API end to end (optional but recommended)
cd ../admin && node scripts/smoke.mjs

# 4) run the panel
cd admin && npm run dev        # http://localhost:5180
```

Sign in with:

```
admin@jobsstory.app / Admin12345!
```

Emulator data lives in memory: **stopping `emulators:start` wipes it** — just
re-run `node seed-emulator.js`. Set `VITE_USE_EMULATORS=false` in `.env` to point
the panel back at the live project (needs a deployed Blaze backend).

## steps for the live project (one-time)

1. **Create a web app in Firebase** (if none exists):
   Firebase Console ← Project settings ← Your apps ← Add app ← Web.
   You will get a web `apiKey` and `appId`.

2. **Set the variables**:
   ```
   cp .env.example .env
   # fill VITE_FIREBASE_API_KEY (and VITE_FIREBASE_APP_ID)
   # set VITE_USE_EMULATORS=false
   ```

3. **Grant the first admin**:
   Firebase Console ← Firestore ← users/{uid} ← add field `isAdmin: true`.
   (That account signs in with its email and password.)

4. **Install and deploy the functions** (once, requires Blaze):
   ```
   cd ../functions && npm install && npm run deploy
   ```

5. **Run the panel locally** (fixed port 5180):
   ```
   cd ../admin
   npm install
   npm run dev        # http://localhost:5180
   ```

## النشر
اللوحة **محلية فقط** عن قصد (رأس `firebase.json` لا يحتوي `hosting`،
أي أن `firebase deploy` لن يلمس أي موقع منشور لمشروع `jobsstory-app`).
إن أردت نشرها مستقبلاً، استعمل مشروع Firebase منفصلاً حتى لا يستبدل موقعك الحالي.

## الأقسام
- **نظرة عامة** — إحصاءات المنصة وأحدث التسجيلات.
- **المستخدمون** — بحث، حظر/تنشيط، توثيق جهات التوظيف، منح/سحب صلاحية Admin، وعرض الملفات.
- **القصص** — مودرة المحتوى: اعتماد، إخفاء، إعادة نشر، تثبيت، حذف (مع حذف ملفات الفيديو من التخزين).
- **الوظائف** — إغلاق/إعادة فتح/حذف الإعلانات.
- **التقديمات** — متابعة كل الطلبات وتصفيتها حسب الحالة.
- **إشعار البث** — رسالة فورية لكل الأجهزة المسجلة (FCM).

## ملاحظات
- إرسال الإشعارات والـ Cloud Functions الحقيقي يتطلبان باقة **Blaze** (دفع حسب الاستخدام)؛ وضع المحاكي يعمل بلا ذلك.
- الدوال مُربوطة عبر `functions/index.js` الذي **يعيد تصدير** `./admin` (`Object.assign(module.exports, admin)`) — بدون ذلك لا يسجّل Functions-runtime أي نقطة نهاية.
- فحص سريع للـ API دون متصفح: `node scripts/smoke.mjs` من مجلد `admin`.