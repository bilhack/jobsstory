import { useEffect, useState } from "react";
import { call, errorMessage } from "../api";
import type { ApplicationRow } from "../types";
import { Spinner, Empty, Badge, ErrorBox, PageHeader } from "../components/ui";

const TABS = [
  { value: "", label: "الكل" },
  { value: "pending", label: "جديد" },
  { value: "contacted", label: "تم التواصل" },
  { value: "rejected", label: "مرفوض" },
];

export default function Applications() {
  const [items, setItems] = useState<ApplicationRow[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [tab, setTab] = useState("");
  const [filter, setFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [more, setMore] = useState(false);
  const [error, setError] = useState("");

  const load = (status: string, c: string | null, append: boolean) => {
    setLoading(true);
    setError("");
    call<{ items: ApplicationRow[]; nextCursor: string | null }>("adminListApplications", {
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

  const shown = items.filter(
    (a) => !filter || a.seekerName.toLowerCase().includes(filter.toLowerCase()) || a.jobTitle.toLowerCase().includes(filter.toLowerCase())
  );

  return (
    <>
      <PageHeader title="التقديمات" subtitle="متابعة كل الطلبات على المنصة" />
      <ErrorBox message={error} />
      <div className="toolbar">
        {TABS.map((t) => (
          <button key={t.value} className={`btn ${tab === t.value ? "btn-primary" : "btn-ghost"}`} onClick={() => setTab(t.value)}>
            {t.label}
          </button>
        ))}
        <input placeholder="ابحث بباحث أو وظيفة..." value={filter} onChange={(e) => setFilter(e.target.value)} />
      </div>
      {loading && items.length === 0 ? (
        <Spinner label="جارِ التحميل..." />
      ) : shown.length === 0 ? (
        <Empty>لا تقديمات مطابقة.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>الباحث</th>
                <th>الوظيفة</th>
                <th>الحالة</th>
                <th>التاريخ</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((a) => (
                <tr key={a.id}>
                  <td>
                    {a.seekerName}
                    <div className="muted">{a.seekerEmail}</div>
                  </td>
                  <td>{a.jobTitle || a.jobId}</td>
                  <td>
                    <Badge tone={a.status === "pending" ? "warn" : a.status === "contacted" ? "ok" : "danger"}>
                      {a.status === "pending" ? "جديد" : a.status === "contacted" ? "تم التواصل" : "مرفوض"}
                    </Badge>
                  </td>
                  <td>{new Date(a.appliedAt || "").toLocaleDateString("ar")}</td>
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