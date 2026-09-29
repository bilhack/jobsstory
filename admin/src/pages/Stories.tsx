import { useEffect, useState } from "react";
import { call, errorMessage } from "../api";
import type { StoryRow } from "../types";
import { Spinner, Empty, Badge, ConfirmButton, ErrorBox, PageHeader, SuccessBox } from "../components/ui";

const TABS = [
  { value: "", label: "الكل" },
  { value: "review", label: "قيد المراجعة" },
  { value: "approved", label: "معتمدة" },
  { value: "hidden", label: "مخفية" },
];

export default function Stories() {
  const [items, setItems] = useState<StoryRow[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [tab, setTab] = useState("");
  const [loading, setLoading] = useState(true);
  const [more, setMore] = useState(false);
  const [error, setError] = useState("");
  const [ok, setOk] = useState("");

  const load = (status: string, c: string | null, append: boolean) => {
    setLoading(true);
    setError("");
    call<{ items: StoryRow[]; nextCursor: string | null }>("adminListStories", {
      status: status || undefined,
      cursor: c || undefined,
    })
      .then((res) => {
        setItems((prev) => (append ? [...prev, ...res.items] : res.items));
        setCursor(res.nextCursor);
        setMore(!!res.nextCursor);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    setItems([]);
    load(tab, null, false);
  }, [tab]);

  const act = async (storyId: string, action: string, msg: string) => {
    setOk("");
    setError("");
    try {
      await call("adminModerateStory", { storyId, action });
      setOk(msg);
    } catch (e) {
      setError(errorMessage(e));
    }
    load(tab, null, false);
  };

  return (
    <>
      <PageHeader title="القصص" subtitle="مودرة المحتوى قبل النشر" />
      <SuccessBox message={ok} />
      <ErrorBox message={error} />
      <div className="toolbar">
        {TABS.map((t) => (
          <button key={t.value} className={`btn ${tab === t.value ? "btn-primary" : "btn-ghost"}`} onClick={() => setTab(t.value)}>
            {t.label}
          </button>
        ))}
      </div>
      {loading && items.length === 0 ? (
        <Spinner label="جارِ التحميل..." />
      ) : items.length === 0 ? (
        <Empty>لا قصص في هذا القسم.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>المنشئ</th>
                <th>التعليق</th>
                <th>الحالة</th>
                <th>التاريخ</th>
                <th>إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {items.map((s) => (
                <tr key={s.id}>
                  <td>{s.ownerName || s.ownerUid}</td>
                  <td style={{ maxWidth: 260, whiteSpace: "normal" }}>{s.caption || "—"}</td>
                  <td>
                    {s.featured && <Badge tone="warn">مثبّتة</Badge>}{" "}
                    <Badge tone={s.status === "approved" ? "ok" : s.status === "review" ? "warn" : "neutral"}>
                      {s.status === "approved" ? "معتمدة" : s.status === "review" ? "قيد المراجعة" : "مخفية"}
                    </Badge>
                  </td>
                  <td>{new Date(s.createdAt || "").toLocaleDateString("ar")}</td>
                  <td>
                    <div className="row-actions">
                      {s.videoUrl && (
                        <a className="btn btn-ghost" href={s.videoUrl} target="_blank" rel="noreferrer">معاينة</a>
                      )}
                      {s.status === "review" && (
                        <button className="btn btn-primary" onClick={() => act(s.id, "approve", "اعتُمدت القصة")}>اعتماد</button>
                      )}
                      {s.status === "approved" && (
                        <button className="btn btn-warn" onClick={() => act(s.id, "hide", "أُخفيت القصة")}>إخفاء</button>
                      )}
                      {s.status === "hidden" && (
                        <button className="btn btn-primary" onClick={() => act(s.id, "approve", "أُعيد نشر القصة")}>إعادة نشر</button>
                      )}
                      <button className="btn btn-ghost" onClick={() => act(s.id, s.featured ? "unfeature" : "feature", s.featured ? "أُزيل التثبيت" : "ثُبّتت القصة")}>
                        {s.featured ? "إلغاء التثبيت" : "تثبيت"}
                      </button>
                      <ConfirmButton label="حذف" onClick={() => act(s.id, "delete", "حُذفت القصة")} />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      {more && (
        <div style={{ marginTop: 14, textAlign: "center" }}>
          <button className="btn btn-ghost" onClick={() => load(tab, cursor, true)} disabled={loading}>
            {loading ? "..." : "عرض المزيد"}
          </button>
        </div>
      )}
    </>
  );
}