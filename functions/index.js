/**
 * JobsStory push notifications (Phase 4).
 * - New application  -> notify the job owner (recruiter).
 * - Status change    -> notify the applying seeker.
 *
 * Deploy (requires Spark->Blaze upgrade + Storage setup in the console):
 *   cd functions && npm install && npm run deploy
 */
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

initializeApp();

async function notify(uid, title, body) {
  if (!uid) return;
  const user = await getFirestore().collection("users").doc(uid).get();
  const tokens = (user.data()?.fcmTokens || []).filter(Boolean);
  if (tokens.length === 0) return;
  try {
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
    });
  } catch (err) {
    console.warn("FCM send failed for", uid, err.message);
  }
}

exports.onApplicationCreated = onDocumentCreated("applications/{applicationId}", async (event) => {
  const app = event.data;
  if (!app) return;
  const job = await getFirestore().collection("jobs").doc(app.get("jobId")).get();
  const data = job.data() || {};
  const seekerName = app.get("seekerName") || "باحث";
  const title = "تقديم جديد";
  const body = `${seekerName} قدّم على وظيفتك «${data.title || ""}»`;
  await notify(data.createdBy, title, body);
});

exports.onApplicationUpdated = onDocumentUpdated("applications/{applicationId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!after || !before || before.status === after.status) return;
  const label =
    after.status === "contacted"
      ? "تمت عملية التواصل بخصوص تقديمك"
      : after.status === "rejected"
        ? "تم رفض طلبك لهذه الوظيفة"
        : "تحديث جديد على حالة تقديمك";
  await notify(after.seekerUid, "حالة تقديمك", label);
});