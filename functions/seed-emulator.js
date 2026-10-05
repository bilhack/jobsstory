/**
 * Seeds the Firebase Emulator Suite with realistic demo data so the admin
 * panel (admin/) can be exercised without the Blaze plan or production data.
 *
 * Usage — with `firebase emulators:start` already running:
 *   node seed-emulator.js
 *
 * Creates an admin login you can use in the panel:
 *   admin@jobsstory.app / Admin12345!
 */
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

initializeApp({ projectId: "jobsstory-app", apiKey: "emulator-only" });

const db = getFirestore();
const auth = getAuth();

const ADMIN_EMAIL = "admin@jobsstory.app";
const ADMIN_PASSWORD = "Admin12345!";

const daysAgo = (d) => Timestamp.fromDate(new Date(Date.now() - d * 86400000));

async function wipe(collection) {
  const snap = await db.collection(collection).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

async function ensureAdminUid() {
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    return existing.uid;
  } catch {
    const created = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      emailVerified: true,
      displayName: "مدير المنصة",
    });
    return created.uid;
  }
}

async function main() {
  const adminUid = await ensureAdminUid();

  await Promise.all([wipe("users"), wipe("stories"), wipe("jobs"), wipe("applications")]);

  const seekers = [
    { key: "s1", name: "سارة العتيبي", email: "sara@example.com", headline: "مهندسة واجهات أمامية", location: "الرياض", skills: ["Flutter", "TypeScript"], age: 2 },
    { key: "s2", name: "محمد القحطاني", email: "mohammed@example.com", headline: "مطور أندرويد", location: "جدة", skills: ["Kotlin", "Firebase"], age: 5 },
    { key: "s3", name: "ليان الحربي", email: "layan@example.com", headline: "مصممة تجربة مستخدم", location: "الرياض", skills: ["Figma", "UX"], age: 7 },
    { key: "s4", name: "يوسف ناصر", email: "youssef@example.com", headline: "مهندس خلفي", location: "الخبر", skills: ["Node.js", "SQL"], age: 12 },
    { key: "s5", name: "نوف السبيعي", email: "nouf@example.com", headline: "محللة بيانات", location: "أبها", skills: ["Python", "BI"], age: 18 },
  ];

  const recruiters = [
    { key: "r1", name: "شركة النور للتقنية", email: "hr@noor.example.com", verified: true, age: 20 },
    { key: "r2", name: "مجموعة روافد", email: "careers@rawafed.example.com", verified: true, age: 25 },
    { key: "r3", name: "استوديو Webwise", email: "jobs@webwise.example.com", verified: false, age: 30 },
  ];

  const users = db.collection("users");
  const batch = db.batch();

  batch.set(users.doc(adminUid), {
    uid: adminUid,
    email: ADMIN_EMAIL,
    displayName: "مدير المنصة",
    role: "recruiter",
    isAdmin: true,
    fcmTokens: [],
    createdAt: daysAgo(40),
  });

  const uidByKey = { s1: adminUid, s2: adminUid, s3: adminUid, s4: adminUid, s5: adminUid, r1: adminUid, r2: adminUid, r3: adminUid };
  seekers.forEach((s, i) => {
    const uid = `seek-${s.key}`;
    uidByKey[s.key] = uid;
    batch.set(users.doc(uid), {
      uid,
      email: s.email,
      displayName: s.name,
      role: "seeker",
      headline: s.headline,
      location: s.location,
      skills: s.skills,
      languages: ["العربية", "الإنجليزية"],
      createdAt: daysAgo(s.age),
      banned: i === 4,
    });
  });
  recruiters.forEach((r) => {
    const uid = `rec-${r.key}`;
    uidByKey[r.key] = uid;
    batch.set(users.doc(uid), {
      uid,
      email: r.email,
      displayName: r.name,
      role: "recruiter",
      headline: "شركة توظيف",
      location: "السعودية",
      isVerifiedRecruiter: r.verified,
      createdAt: daysAgo(r.age),
    });
  });

  const stories = [
    { key: "st1", owner: "s1", caption: "ثلاث سنوات أصمّم واجهات عربية أنيقة", status: "review", age: 1 },
    { key: "st2", owner: "s2", caption: "مطور أندرويد جاهز لمشروعك القادم", status: "review", age: 1 },
    { key: "st3", owner: "s3", caption: "أصمّم واجهات تشرح نفسها", status: "review", age: 2 },
    { key: "st4", owner: "s4", caption: "خبرة في بناء خدمات عالية الأداء", status: "review", age: 3 },
    { key: "st5", owner: "s5", caption: "أحوّل البيانات إلى قرارات", status: "review", age: 4 },
    { key: "st6", owner: "s1", caption: "قصة معتمدة — سارة", status: "approved", age: 9 },
    { key: "st7", owner: "s2", caption: "قصة معتمدة — محمد", status: "approved", age: 14 },
    { key: "st8", owner: "s3", caption: "قصة مخفية للاختبار", status: "hidden", age: 22 },
  ];

  const storyIds = {};
  stories.forEach((st) => {
    const id = `story-${st.key}`;
    storyIds[st.key] = id;
    batch.set(db.collection("stories").doc(id), {
      ownerUid: uidByKey[st.owner],
      videoUrl: "",
      thumbnailUrl: "",
      caption: st.caption,
      durationMs: 45000,
      status: st.status,
      featured: st.key === "st6",
      createdAt: daysAgo(st.age),
    });
  });

  const jobs = [
    { key: "j1", title: "مهندس فلاتر أول", company: "شركة النور للتقنية", location: "الرياض", owner: "r1", status: "open", age: 2, description: "نبحث عن مهندس فلاتر خبرة سنتين لبناء تطبيقات عربية عالية الجودة." },
    { key: "j2", title: "مطور أندرويد", company: "مجموعة روافد", location: "جدة", owner: "r2", status: "open", age: 6, description: "تطوير وإصدار تطبيقات أندرويد." },
    { key: "j3", title: "مصمم UI/UX", company: "استوديو webwise", location: "الرياض", owner: "r3", status: "open", age: 8, description: "تصميم واجهات عربية من صفحة부터 تطبيق." },
    { key: "j4", title: "مهندس خلفية", company: "شركة النور للتقنية", location: "الخبر", owner: "r1", status: "open", age: 11, description: "بناء خدمات خلفية قابلة للتوسع." },
    { key: "j5", title: "محلل بيانات", company: "مجموعة روافد", location: "أبها", owner: "r2", status: "open", age: 15, description: "تحويل البيانات إلى تقارير واضحة." },
    { key: "j6", title: "مطور فلاتر (مغلقة)", company: "استوديو webwise", location: "جدة", owner: "r3", status: "closed", age: 25, description: "تم إغلاق هذا الإعلان." },
  ];

  const jobIds = {};
  jobs.forEach((j) => {
    const id = `job-${j.key}`;
    jobIds[j.key] = id;
    batch.set(db.collection("jobs").doc(id), {
      title: j.title,
      company: j.company,
      location: j.location,
      description: j.description,
      createdBy: uidByKey[j.owner],
      status: j.status,
      createdAt: daysAgo(j.age),
    });
  });

  const applications = [
    { job: "j1", seeker: "s1", status: "pending", story: "st6", age: 1 },
    { job: "j1", seeker: "s4", status: "pending", story: "st7", age: 2 },
    { job: "j2", seeker: "s2", status: "contacted", story: "st7", age: 4 },
    { job: "j3", seeker: "s3", status: "pending", story: "st6", age: 5 },
    { job: "j4", seeker: "s5", status: "rejected", story: "st7", age: 9 },
    { job: "j5", seeker: "s4", status: "pending", story: "st7", age: 12 },
  ];

  applications.forEach((a, i) => {
    const seeker = seekers.find((s) => s.key === a.seeker);
    batch.set(db.collection("applications").doc(`app-${i + 1}`), {
      jobId: jobIds[a.job],
      seekerUid: uidByKey[a.seeker],
      seekerName: seeker ? seeker.name : "",
      seekerEmail: seeker ? seeker.email : "",
      seekerHeadline: seeker ? seeker.headline : "",
      storyId: storyIds[a.story],
      status: a.status,
      appliedAt: daysAgo(a.age),
    });
  });

  await batch.commit();

  console.log("Seeded emulator data:");
  console.log(`  users:         ${await db.collection("users").count().get().then((s) => s.data().count)}`);
  console.log(`  stories:       ${stories.length}`);
  console.log(`  jobs:          ${jobs.length}`);
  console.log(`  applications:  ${applications.length}`);
  console.log("\nAdmin login for the panel:");
  console.log(`  email:    ${ADMIN_EMAIL}`);
  console.log(`  password: ${ADMIN_PASSWORD}`);
  process.exit(0);
}

main().catch((err) => {
  console.error("Seeding failed:", err.message);
  process.exit(1);
});