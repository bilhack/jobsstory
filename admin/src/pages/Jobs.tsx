import { useEffect, useState } from "react";
import { call, errorMessage } from "../api";
import type { JobRow } from "../types";
import { Spinner, Empty, Badge, ConfirmButton, ErrorBox, PageHeader, SuccessBox } from "../components/ui";

const TABS = [
  { value: "", label: "الكل" },
  { value: "open", label: "مفتوحة" },
  { value: "closed", label: "مغلقة" },
];

export default function Jobs() {
  const [items, setItems] = useState<JobRow[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [tab, setTab] = useState("");
  const [loading, setLoading] = useState(true);
  const [more, setMore] = useState(false);
  const [error, setError] = useState("");
  const [ok, setOk] = useState("");

  const load = (status: string, c: string | null, append: boolean) => {
    setLoading(true);
    setError("");
    call<{ items: JobRow[]; nextCursor: string | null }>("adminListJobs", {
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

  const act = async (fn: () => Promise<unknown>, msg: string) => {
    setOk("");
    setError("");
    try {
      await fn();
      setOk(msg);
    } catch (e) {
      setError(errorMessage(e));
    }
    load(tab, null, false);
  };

  return (
    <>
      <PageHeader title="الوظائف" subtitle="إدارة الإعلانات المفتوحة والمغلقة" />
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
        <Empty>لا وظائف مطابقة.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>العنوان</th>
                <th>الشركة</th>
                <th>الموقع</th>
                <th>الناشر</th>
                <th>الحالة</th>
                <th>إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {items.map((j) => (
                <tr key={j.id} style={j.status === "closed" ? { opacity: 0.6 } : undefined}>
                  <td style={{ fontWeight: 700 }}>{j.title}</td>
                  <td>{j.company}</td>
                  <td>{j.location || "—"}</td>
                  <td>{j.recruiter || j.createdBy}</td>
                  <td>
                    <Badge tone={j.status === "open" ? "ok" : "neutral"}>{j.status === "open" ? "مفتوحة" : "مغلقة"}</Badge>
                  </td>
                  <td>
                    <div className="row-actions">
                      <button className="btn btn-ghost" onClick={() => act(() => call("adminSetJob", { jobId: j.id, status: j.status === "open" ? "closed" : "open" }), "تحديثت الحالة")}>
                        {j.status === "open" ? "إغلاق" : "إعادة فتح"}
                      </button>
                      <ConfirmButton label="حذف" onClick={() => act(() => call("adminSetJob", { jobId: j.id, remove: true }), "حُذفت الوظيفة")} />
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