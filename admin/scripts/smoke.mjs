/**
 * End-to-end smoke test for the admin API against the local Emulator Suite.
 *
 * Verifies: sign-in (Auth emulator) -> callable functions (Functions emulator)
 * -> Firestore data, i.e. exactly what the panel does in the browser.
 *
 * Usage: with `firebase emulators:start` running and the panel seeded.
 *   node scripts/smoke.mjs
 */
import { initializeApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInWithEmailAndPassword } from "firebase/auth";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";

const app = initializeApp({
  apiKey: "emulator-only",
  authDomain: "jobsstory-app.firebaseapp.com",
  projectId: "jobsstory-app",
});

const auth = getAuth(app);
connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });

const functions = getFunctions(app, "us-central1");
connectFunctionsEmulator(functions, "127.0.0.1", 5001);

const call = async (name, data = {}) => {
  const res = await httpsCallable(functions, name)(data);
  return res.data;
};

const results = [];
const check = (label, ok, detail = "") => {
  results.push({ label, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"}  ${label}${detail ? " — " + detail : ""}`);
};

try {
  const cred = await signInWithEmailAndPassword(auth, "admin@jobsstory.app", "Admin12345!");
  check("تسجيل الدخول عبر Auth emulator", !!cred.user, cred.user.uid);

  const ping = await call("adminPing");
  check("adminPing", ping.ok === true, ping.message);

  const stats = await call("adminGetStats");
  check(
    "adminGetStats",
    stats.users > 0 && stats.stories > 0 && stats.jobs > 0,
    `مستخدمون ${stats.users} / قصص ${stats.stories} / وظائف ${stats.jobs} / تقديمات ${stats.applications}`
  );
  check("بانتظار المراجعة", stats.reviewStories > 0, `${stats.reviewStories} قصة`);

  const users = await call("adminListUsers");
  check("adminListUsers", Array.isArray(users.items) && users.items.length > 0, `${users.items.length} مستخدم`);
  check(
    "علم isAdmin محفوظ",
    users.items.some((u) => u.isAdmin === true)
  );

  const stories = await call("adminListStories", { status: "review" });
  check("adminListStories (مراجعة)", stories.items.length > 0, `${stories.items.length} قصة`);
  const owner = stories.items[0]?.ownerName;
  check("دمج اسم صاحب القصة", !!owner, owner);

  const target = stories.items[0];
  await call("adminModerateStory", { storyId: target.id, action: "approve" });
  const approved = await call("adminListStories", { status: "approved" });
  check(
    "adminModerateStory (اعتماد)",
    approved.items.some((s) => s.id === target.id),
    `اعتُمدت «${target.caption}»`
  );

  const jobs = await call("adminListJobs");
  check("adminListJobs", jobs.items.length > 0, `${jobs.items.length} وظيفة`);

  const apps = await call("adminListApplications", {});
  check("adminListApplications", apps.items.length > 0, `${apps.items.length} تقديم`);

  const detail = await call("adminGetUser", { uid: users.items.find((u) => u.role === "seeker")?.uid });
  check("adminGetUser", !!detail.user.uid, `${detail.stories.length} قصة`);

  const broadcast = await call("adminBroadcast", { title: "اختبار", body: "رسالة تجريبية" });
  check("adminBroadcast", broadcast.ok === true, `استهدف ${broadcast.targeted} جهاز${broadcast.warning ? " (تنبيه: " + broadcast.warning + ")" : ""}`);

  const denied = await (async () => {
    try {
      await call("adminSetUserStatus", { uid: "nope" });
      return false;
    } catch (e) {
      return true;
    }
  })();
  check("التحقق من المدخلات", denied, "رفض uid غير موجود");
} catch (err) {
  check("تشغيل الفحص", false, err?.message || String(err));
}

const failed = results.filter((r) => !r.ok).length;
console.log(`\n${results.length - failed}/${results.length} ناجح`);
process.exit(failed ? 1 : 0);