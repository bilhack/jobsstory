import { useState } from "react";
import { call, errorMessage } from "../api";
import type { BroadcastResult } from "../types";
import { ErrorBox, PageHeader, SuccessBox } from "../components/ui";

export default function Broadcast() {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [result, setResult] = useState<BroadcastResult | null>(null);

  const send = async () => {
    setError("");
    setResult(null);
    if (!title.trim() || !body.trim()) {
      setError("العنوان ونص الرسالة مطلوبان.");
      return;
    }
    setBusy(true);
    try {
      setResult(await call<BroadcastResult>("adminBroadcast", { title, body }));
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader title="إشعارات البث" subtitle="رسالة فورية لكل الأجهزة المسجلة" />
      <ErrorBox message={error} />
      {result && (
        <SuccessBox
          message={`أُرسل ${result.sent} إشعاراً إلى ${result.targeted} جهاز. (إشعارات غير مكوّنة على الأجهزة تتجاهل)`}
        />
      )}
      <div className="card" style={{ maxWidth: 560 }}>
        <div className="field">
          <label>العنوان</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="مثال: وظائف جديدة أُضيفت اليوم" />
        </div>
        <div className="field">
          <label>نص الإشعار</label>
          <textarea rows={4} value={body} onChange={(e) => setBody(e.target.value)} placeholder="محتوى الرسالة الظاهرة في الإشعار..." />
        </div>
        <button className="btn btn-primary" onClick={send} disabled={busy} style={{ padding: "12px 18px" }}>
          {busy ? "جارِ الإرسال..." : "إرسال البث الآن"}
        </button>
      </div>
    </>
  );
}