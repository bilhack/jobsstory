# JobsStory — لوحة تحكم المشرف (ويب)

لوحة إدارة تفاعلية مبنية بـ React + Vite، تتصل بالتطبيق عبر واجهة
Cloud Functions الآمنة في `../functions/admin.js`.

## لماذا Cloud Functions؟
كل بيانات التطبيق في Firestore محمية بروابط مخصصة (العميل لا يقرأ إلا بياناته).
عمليات الإدارة تنفّذ من خوادمنا فقط عبر دوال callable تتحقق من:
1. تسجيل الدخول (`requireAuth`).
2. وثيقة المستخدم تحمل `isAdmin: true`.

## خطوات التشغيل (مرة واحدة)

1. **إنشاء تطبيق ويب في Firebase** (إن لم يكن موجوداً):
   Firebase Console ← Project settings ← Your apps ← Add app ← Web.
   ستحصل على `apiKey` و `appId`.

2. **إعداد المتغيرات**:
   ```
   cp .env.example .env
   # املأ VITE_FIREBASE_API_KEY و VITE_FIREBASE_APP_ID (والبقية لها قيم افتراضية)
   ```

3. **منح صلاحية المشرف لأول حساب**:
   Firebase Console ← Firestore ← users/{uid} ← أضف حقل `isAdmin: true`.
   (هذا الحساب ببريده وكلمة مروره سيدخل اللوحة.)

4. **تثبيت الدوال ونشرها** (مرة واحدة، يتطلب ترقية Blaze):
   ```
   cd ../functions && npm install && npm run deploy
   ```

5. **تشغيل الواجهة محلياً**:
   ```
   cd ../admin
   npm install
   npm run dev        # http://localhost:5173
   ```

6. **نشر الواجهة** (اختياري — Firebase Hosting):
   ```
   cd ../admin
   npm run deploy
   ```
   ثم افتح `https://jobsstory-app.web.app` (أو نطاقك).

## الأقسام
- **نظرة عامة** — إحصاءات المنصة وأحدث التسجيلات.
- **المستخدمون** — بحث، حظر/تنشيط، توثيق جهات التوظيف، منح/سحب صلاحية Admin، وعرض الملفات.
- **القصص** — مودرة المحتوى: اعتماد، إخفاء، إعادة نشر، تثبيت، حذف (مع حذف ملفات الفيديو من التخزين).
- **الوظائف** — إغلاق/إعادة فتح/حذف الإعلانات.
- **التقديمات** — متابعة كل الطلبات وتصفيتها حسب الحالة.
- **إشعار البث** — رسالة فورية لكل الأجهزة المسجلة (FCM).

## ملاحظات
- إرسال الإشعارات والـ Cloud Functions يتطلبان باقة **Blaze** (دفع حسب الاستخدام).
- `firebase.json` يشير للوحة على المسار `admin/dist` ضمن `hosting`،
  وتُفحص الدوال عبر `functions/index.js` (يربط `./admin`).