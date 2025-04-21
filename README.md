# JobsStory

منصة توظيف عصرية تعتمد على الفيديوهات القصيرة، تجمع بين تجربة TikTok وسهولة LinkedIn.

## التقنيات المستخدمة
- Next.js (TypeScript)
- Tailwind CSS
- Firebase (Auth, Firestore, Storage)
- AI APIs (Google Video Intelligence, Whisper)

## خطوات التشغيل

1. انسخ إعدادات Firebase إلى ملف `.env.local`:
```
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID=...
```

2. ثبّت الحزم:
```
npm install
```

3. شغّل المشروع:
```
npm run dev
```

## بنية المشروع
- `src/pages/` صفحات الموقع
- `src/lib/firebase.ts` تكامل مع Firebase
- `src/styles/` ملفات الأنماط

## الميزات القادمة
- تسجيل/دخول المستخدمين (باحث عن عمل/موظف HR)
- رفع فيديوهات قصيرة ووثائق
- تغذية فيديوهات رأسية للـ HR
- تفاعل اجتماعي وتواصل سريع

## 🛠️ Tech Stack

- **Frontend**: Next.js, TypeScript, Tailwind CSS
- **Backend**: Firebase (Auth, Firestore, Storage)
- **AI Processing**: Google Video Intelligence API, Whisper API
- **Analytics**: Firebase Analytics

## 📝 License

MIT
