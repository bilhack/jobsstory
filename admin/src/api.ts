import { getFunctions, httpsCallable, type Functions } from "firebase/functions";
import { app } from "./firebase";

let cached: Functions | null = null;

function functionsClient(): Functions {
  if (!app) throw new Error("Firebase is not configured — see src/firebase.ts");
  if (!cached) cached = getFunctions(app, "us-central1");
  return cached;
}

/** Calls one of the admin Cloud Functions (`functions/admin.js`). */
export async function call<T>(name: string, data: Record<string, unknown> = {}): Promise<T> {
  const fn = httpsCallable<Record<string, unknown>, T>(functionsClient(), name);
  const result = await fn(data);
  return result.data;
}

const messages: Record<string, string> = {
  unauthenticated: "يجب تسجيل الدخول أولاً.",
  "permission-denied": "لا يملك هذا الحساب صلاحية لوحة التحكم.",
  "not-found": "العنصر غير موجود.",
  "invalid-argument": "طلب غير صالح.",
  "failed-precondition": "لا يمكن تنفيذ هذا الإجراء.",
  "functions/unknown": "تعذّر الاتصال بالخادم — تحقق من نشر الدوال.",
};

export function errorMessage(error: unknown): string {
  const code = (error as { code?: string })?.code ?? "";
  return messages[code] || messages["functions/unknown"];
}