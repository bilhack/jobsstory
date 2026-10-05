import { initializeApp, type FirebaseApp } from "firebase/app";

const env = import.meta.env as Record<string, string | undefined>;

export const firebaseConfig = {
  apiKey: env.VITE_FIREBASE_API_KEY || "",
  authDomain: env.VITE_FIREBASE_AUTH_DOMAIN || "jobsstory-app.firebaseapp.com",
  projectId: env.VITE_FIREBASE_PROJECT_ID || "jobsstory-app",
  storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET || "jobsstory-app.firebasestorage.app",
  messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID || "426762692001",
  // Optional for Auth + callable functions; only needed for Analytics/Install.
  appId: env.VITE_FIREBASE_APP_ID || "",
};

// Auth (and callable Cloud Functions) only need the API key — everything
// else has a working default for this project. Without a key the app would
// previously crash with a blank page, so we fail gracefully instead.
export const missingKeys = Object.entries(firebaseConfig)
  .filter(([, v]) => !v)
  .map(([k]) => k);

export const appReady = Boolean(firebaseConfig.apiKey);

export const app: FirebaseApp | null = appReady ? initializeApp(firebaseConfig) : null;

if (!appReady) {
  // eslint-disable-next-line no-console
  console.warn(
    "[JobsStory Admin] VITE_FIREBASE_API_KEY is missing — the panel is showing setup instructions."
  );
}