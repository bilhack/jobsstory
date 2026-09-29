/**
 * JobsStory Admin API — serverless control plane for the admin web panel.
 *
 * Every endpoint is a callable Cloud Function guarded by:
 *   1. Firebase Authentication (request.auth.uid).
 *   2. `users/{uid}.isAdmin === true` in Firestore.
 *
 * Grant the first admin from the Firebase console:
 *   -> Firestore -> users -> <uid> -> add field isAdmin: true
 *
 * The Flutter app never calls these; only the web panel (see `admin/`) does,
 * so normal users can never elevate their own privileges.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { getMessaging } = require("firebase-admin/messaging");

const db = getFirestore();

const PAGE_SIZE = 50;

async function requireAdmin(context) {
  const uid = context?.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "يجب تسجيل الدخول إلى لوحة التحكم.");
  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists || doc.data().isAdmin !== true) {
    throw new HttpsError("permission-denied", "هذا الحساب غير مخول باللوحة.");
  }
  return uid;
}

/** Wraps an admin handler: data, adminUid */
function onAdminCall(handler) {
  return onCall(async (request) => {
    const adminUid = await requireAdmin(request.auth);
    return handler(request.data || {}, adminUid);
  });
}

// ---------------------------------------------------------------- helpers

async function countOf(query) {
  return (await query.count().get()).data().count;
}

function isoValue(v) {
  return v ? new Date(v.seconds ? v.seconds * 1000 : v).toISOString() : null;
}

function cleanUser(doc) {
  const d = doc.data() || {};
  return {
    uid: doc.id,
    email: d.email || "",
    displayName: d.displayName || "",
    role: d.role || "",
    headline: d.headline || "",
    location: d.location || "",
    isAdmin: d.isAdmin === true,
    banned: d.banned === true,
    isVerifiedRecruiter: d.isVerifiedRecruiter === true,
    createdAt: isoValue(d.createdAt),
  };
}

async function paddedQuery(q, cursor, limit) {
  let query = q;
  if (cursor) query = query.startAfter(new Date(cursor));
  const snap = await query.limit(limit).get();
  const docs = snap.docs;
  return {
    items: docs.map((doc) => doc),
    nextCursor: docs.length ? isoValue(docs[docs.length - 1].data().createdAt) : null,
  };
}

// ------------------------------------------------------------------- stats

exports.adminGetStats = onAdminCall(async () => {
  const [users, seekers, recruiters, verified, banned, stories, reviewStories, jobs, openJobs, applications, pendingApps] =
    await Promise.all([
      countOf(db.collection("users")),
      countOf(db.collection("users").where("role", "==", "seeker")),
      countOf(db.collection("users").where("role", "==", "recruiter")),
      countOf(db.collection("users").where("isVerifiedRecruiter", "==", true)),
      countOf(db.collection("users").where("banned", "==", true)),
      countOf(db.collection("stories")),
      countOf(db.collection("stories").where("status", "==", "review")),
      countOf(db.collection("jobs")),
      countOf(db.collection("jobs").where("status", "==", "open")),
      countOf(db.collection("applications")),
      countOf(db.collection("applications").where("status", "==", "pending")),
    ]);

  const recentSnap = await db.collection("users").orderBy("createdAt", "desc").limit(7).get();
  const recentUsers = recentSnap.docs.map(cleanUser);

  return {
    users,
    seekers,
    recruiters,
    verifiedRecruiters: verified,
    bannedUsers: banned,
    stories,
    reviewStories,
    jobs,
    openJobs,
    applications,
    pendingApplications: pendingApps,
    recentUsers,
  };
});

// ------------------------------------------------------------------- users

// List all users (paged). Optional `cursor` for the next page.
exports.adminListUsers = onAdminCall(async ({ cursor }) => {
  const limit = PAGE_SIZE;
  const q = db.collection("users").orderBy("createdAt", "desc");
  const query = cursor ? q.startAfter(new Date(cursor)) : q;
  const snap = await query.limit(limit).get();
  return {
    items: snap.docs.map(cleanUser),
    nextCursor: snap.docs.length ? isoValue(snap.docs[snap.docs.length - 1].data().createdAt) : null,
  };
});

// Flip moderation / role flags on a user.
exports.adminSetUserStatus = onAdminCall(async ({ uid, banned, verified, isAdmin }, adminUid) => {
  if (!uid) throw new HttpsError("invalid-argument", "معرّف المستخدم مطلوب.");
  if (uid === adminUid && banned === true) {
    throw new HttpsError("failed-precondition", "لا يمكنك حظر حسابك بنفسك.");
  }
  if (uid === adminUid && isAdmin === false) {
    throw new HttpsError("failed-precondition", "لا يمكنك إزالة صلاحية الادمن عن حسابك بنفسك.");
  }
  const patch = {};
  if (typeof banned === "boolean") patch.banned = banned;
  if (typeof verified === "boolean") patch.isVerifiedRecruiter = verified;
  if (typeof isAdmin === "boolean") patch.isAdmin = isAdmin;
  if (Object.keys(patch).length === 0) {
    throw new HttpsError("invalid-argument", "لا توجد تغييرات لإرسالها.");
  }
  await db.collection("users").doc(uid).set(patch, { merge: true });
  return { ok: true, uid };
});

exports.adminGetUser = onAdminCall(async ({ uid }) => {
  if (!uid) throw new HttpsError("invalid-argument", "معرّف المستخدم مطلوب.");
  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists) throw new HttpsError("not-found", "المستخدم غير موجود.");
  const d = doc.data() || {};
  const storiesSnap = await db.collection("stories").where("ownerUid", "==", uid).orderBy("createdAt", "desc").limit(50).get();
  const jobsSnap = await db.collection("jobs").where("createdBy", "==", uid).limit(50).get();
  return {
    user: cleanUser(doc),
    stories: storiesSnap.docs.map((s) => ({
      id: s.id,
      caption: s.data().caption || "",
      status: s.data().status || "",
      createdAt: isoValue(s.data().createdAt),
    })),
    jobsCount: jobsSnap.docs.length,
  };
});

// ----------------------------------------------------------------- stories

exports.adminListStories = onAdminCall(async ({ status, cursor }) => {
  let q = db.collection("stories").orderBy("createdAt", "desc");
  if (status) q = q.where("status", "==", status);
  const query = cursor ? q.startAfter(new Date(cursor)) : q;
  const snap = await query.limit(PAGE_SIZE).get();

  const ownerIds = [...new Set(snap.docs.map((d) => d.data().ownerUid).filter(Boolean))];
  const owners = new Map();
  if (ownerIds.length) {
    const refs = ownerIds.map((id) => db.collection("users").doc(id));
    const snapshots = await db.getAll(...refs);
    snapshots.forEach((s) => {
      if (s.exists) owners.set(s.id, s.data().displayName || "");
    });
  }

  return {
    items: snap.docs.map((d) => ({
      id: d.id,
      ownerUid: d.data().ownerUid || "",
      ownerName: owners.get(d.data().ownerUid) || "",
      caption: d.data().caption || "",
      thumbnailUrl: d.data().thumbnailUrl || "",
      videoUrl: d.data().videoUrl || "",
      durationMs: d.data().durationMs || 0,
      status: d.data().status || "",
      featured: d.data().featured === true,
      createdAt: isoValue(d.data().createdAt),
    })),
    nextCursor: snap.docs.length ? isoValue(snap.docs[snap.docs.length - 1].data().createdAt) : null,
  };
});

// approve | hide | delete | feature | unfeature
exports.adminModerateStory = onAdminCall(async ({ storyId, action }) => {
  if (!storyId || !["approve", "hide", "delete", "feature", "unfeature"].includes(action)) {
    throw new HttpsError("invalid-argument", "إجراء غير صالح.");
  }
  const ref = db.collection("stories").doc(storyId);
  const doc = await ref.get();
  if (!doc.exists) throw new HttpsError("not-found", "القصة غير موجودة.");

  if (action === "delete") {
    const d = doc.data();
    for (const url of [d?.videoUrl, d?.thumbnailUrl]) {
      const path = storagePath(url);
      if (path) {
        try {
          await getStorage().bucket().file(path).delete();
        } catch {
          // File already gone — the doc is what matters.
        }
      }
    }
    await db.collection("stories").doc(storyId).delete();
    return { ok: true, deleted: true };
  }

  if (action === "approve") await ref.set({ status: "approved" }, { merge: true });
  if (action === "hide") await ref.set({ status: "hidden" }, { merge: true });
  if (action === "feature") await ref.set({ featured: true }, { merge: true });
  if (action === "unfeature") await ref.set({ featured: false }, { merge: true });
  return { ok: true };
});

// ------------------------------------------------------------------ jobs

exports.adminListJobs = onAdminCall(async ({ status, cursor }) => {
  let q = db.collection("jobs").orderBy("createdAt", "desc");
  if (status) q = q.where("status", "==", status);
  const query = cursor ? q.startAfter(new Date(cursor)) : q;
  const snap = await query.limit(PAGE_SIZE).get();

  const ownerIds = [...new Set(snap.docs.map((d) => d.data().createdBy).filter(Boolean))];
  const owners = new Map();
  if (ownerIds.length) {
    const snapshots = await db.getAll(...ownerIds.map((id) => db.collection("users").doc(id)));
    snapshots.forEach((s) => {
      if (s.exists) owners.set(s.id, `${s.data().displayName || ""} (${s.data().email || ""})`);
    });
  }

  return {
    items: snap.docs.map((d) => ({
      id: d.id,
      title: d.data().title || "",
      company: d.data().company || "",
      location: d.data().location || "",
      description: d.data().description || "",
      status: d.data().status || "",
      createdBy: d.data().createdBy || "",
      recruiter: owners.get(d.data().createdBy) || "",
      createdAt: isoValue(d.data().createdAt),
    })),
    nextCursor: snap.docs.length ? isoValue(snap.docs[snap.docs.length - 1].data().createdAt) : null,
  };
});

exports.adminSetJob = onAdminCall(async ({ jobId, status, remove }) => {
  if (!jobId) throw new HttpsError("invalid-argument", "معرّف الوظيفة مطلوب.");
  const ref = db.collection("jobs").doc(jobId);
  const doc = await ref.get();
  if (!doc.exists) throw new HttpsError("not-found", "الوظيفة غير موجودة.");
  if (remove) {
    await ref.delete();
    return { ok: true, deleted: true };
  }
  if (status && ["open", "closed"].includes(status)) {
    await ref.set({ status }, { merge: true });
  }
  return { ok: true };
});

// ----------------------------------------------------------- applications

exports.adminListApplications = onAdminCall(async ({ jobId, status, cursor }) => {
  let q = db.collection("applications").orderBy("appliedAt", "desc");
  if (jobId) q = q.where("jobId", "==", jobId);
  if (status) q = q.where("status", "==", status);
  const query = cursor ? q.startAfter(new Date(cursor)) : q;
  const snap = await query.limit(PAGE_SIZE).get();

  const jobIds = [...new Set(snap.docs.map((d) => d.data().jobId).filter(Boolean))];
  const jobs = new Map();
  if (jobIds.length) {
    const snapshots = await db.getAll(...jobIds.map((id) => db.collection("jobs").doc(id)));
    snapshots.forEach((s) => {
      if (s.exists) jobs.set(s.id, s.data().title || "");
    });
  }

  return {
    items: snap.docs.map((d) => ({
      id: d.id,
      jobId: d.data().jobId || "",
      jobTitle: jobs.get(d.data().jobId) || "",
      seekerUid: d.data().seekerUid || "",
      seekerName: d.data().seekerName || "",
      seekerEmail: d.data().seekerEmail || "",
      status: d.data().status || "",
      storyId: d.data().storyId || "",
      appliedAt: isoValue(d.data().appliedAt),
    })),
    nextCursor: snap.docs.length ? isoValue(snap.docs[snap.docs.length - 1].data().appliedAt) : null,
  };
});

// ---- extract a storage path from an https:// or gs:// Firebase URL
function storagePath(url) {
  if (!url) return null;
  try {
    if (url.startsWith("gs://")) {
      return url.slice(5).split("/").slice(1).join("/");
    }
    const u = new URL(url);
    if (u.hostname === "firebasestorage.googleapis.com") return u.pathname.split("/o/")[1] || null;
  } catch {
    return null;
  }
  return null;
}

// -------------------------------------------------------------- broadcast

// Sends a push notification to every registered device (tokens under users/*).
exports.adminBroadcast = onAdminCall(async ({ title, body }) => {
  const t = String(title || "").trim();
  const b = String(body || "").trim();
  if (!t || !b) throw new HttpsError("invalid-argument", "العنوان والنص مطلوبان.");

  const snap = await db.collection("users").select("fcmTokens").get();
  const tokens = [];
  snap.docs.forEach((d) => {
    const list = d.data().fcmTokens || [];
    if (Array.isArray(list)) list.forEach((tok) => tokens.push(tok));
  });

  let sent = 0;
  for (let i = 0; i < tokens.length; i += 500) {
    const chunk = tokens.slice(i, i + 500);
    const res = await getMessaging().sendEachForMulticast({
      tokens: chunk,
      notification: { title: t, body: b },
    });
    sent += res.successCount;
  }
  return { ok: true, targeted: tokens.length, sent };
});

// Connectivity / auth sanity check used by the panel once.
exports.adminPing = onAdminCall(async () => ({ ok: true, message: "مرحباً بك في لوحة تحكم JobsStory" }));