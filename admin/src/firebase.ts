import { initializeApp } from "firebase/app";

const env = import.meta.env;

export const firebaseConfig = {
  apiKey: env.VITE_FIREBASE_API_KEY as string,
  authDomain:
    (env.VITE_FIREBASE_AUTH_DOMAIN as string) || "jobsstory-app.firebaseapp.com",
  projectId: (env.VITE_FIREBASE_PROJECT_ID as string) || "jobsstory-app",
  storageBucket:
    (env.VITE_FIREBASE_STORAGE_BUCKET as string) || "jobsstory-app.appspot.com",
  messagingSenderId:
    (env.VITE_FIREBASE_MESSAGING_SENDER_ID as string) || "426762692001",
  appId: env.VITE_FIREBASE_APP_ID as string,
};

const missing = Object.entries(firebaseConfig)
  .filter(([, v]) => !v)
  .map(([k]) => k);

if (missing.length) {
  throw new Error(
    `إعدادات Firebase ناقصة في admin/.env: ${missing.join(
      ", "
    )}. انسخ .env.example واملأ القيم من Firebase Console (Web app).`
  );
}

export const app = initializeApp(firebaseConfig);