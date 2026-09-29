import { useEffect, useState } from "react";
import { call, errorMessage } from "../api";
import type { UserRow, UserDetail } from "../types";
import { Spinner, Empty, Badge, ConfirmButton, ErrorBox, PageHeader, SuccessBox } from "../components/ui";

export default function Users() {
  const [users, setUsers] = useState<UserRow[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [more, setMore] = useState(false);
  const [filter, setFilter] = useState("");
  const [roleFilter, setRoleFilter] = useState("");
  const [error, setError] = useState("");
  const [ok, setOk] = useState("");
  const [detail, setDetail] = useState<UserDetail | null>(null);

  const load = (continueCursor: string | null, append: boolean) => {
    setLoading(true);
    setError("");
    call<{ items: UserRow[]; nextCursor: string | null }>("adminListUsers", {
      cursor: continueCursor || undefined,
    })
      .then((res) => {
        setUsers((prev) => (append ? [...prev, ...res.items] : res.items));
        setCursor(res.nextCursor);
        setMore(!!res.nextCursor);
      })
      .catch((e) => setError(errorMessage(e)))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load(null, false);
  }, []);

  const act = async (fn: () => Promise<unknown>, msg: string) => {
    setError("");
    setOk("");
    try {
      await fn();
      setOk(msg);
    } catch (e) {
      setError(errorMessage(e));
    }
    load(null, false);
  };

  const openDetail = async (uid: string) => {
    try {
      setDetail(await call<UserDetail>("adminGetUser", { uid }));
    } catch (e) {
      setError(errorMessage(e));
    }
  };

  const shown = users.filter(
    (u) =>
      (!roleFilter || u.role === roleFilter) &&
      (!filter || u.displayName.toLowerCase().includes(filter.toLowerCase()) || u.email.toLowerCase().includes(filter.toLowerCase()))
  );

  if (detail) {
    return (
      <div>
        <PageHeader title={`ملف المستخدم — ${detail.user.displayName || detail.user.email}`} />
        <div className="card">
          <p>
            <Badge tone="neutral">{detail.user.email}</Badge>{" "}
            <Badge tone={detail.user.role === "recruiter" ? "warn" : "neutral"}>
              {detail.user.role === "recruiter" ? "جهة توظيف" : detail.user.role === "seeker" ? "باحث" : "بدون دور"}
            </Badge>{" "}
            {detail.user.isAdmin && <Badge tone="danger">Admin</Badge>}{" "}
            {detail.user.banned && <Badge tone="danger">محظور</Badge>}{" "}
            {detail.user.isVerifiedRecruiter && <Badge tone="ok">موثّقة</Badge>}
          </p>
          <p className="muted">{detail.user.headline}</p>
          {detail.user.location && <p className="muted">{detail.user.location}</p>}
          <h2 style={{ marginTop: 18 }}>قصصه ({detail.stories.length})</h2>
          {detail.stories.length === 0 ? (
            <Empty>لا قصص.</Empty>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>التعليق</th>
                    <th>الحالة</th>
                    <th>التاريخ</th>
                  </tr>
                </thead>
                <tbody>
                  {detail.stories.map((s) => (
                    <tr key={s.id}>
                      <td>{s.caption || "—"}</td>
                      <td>
                        <Badge tone={s.status === "approved" ? "ok" : s.status === "review" ? "warn" : "neutral"}>{s.status}</Badge>
                      </td>
                      <td>{new Date(s.createdAt || "").toLocaleDateString("ar")}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <p className="muted">عدد الوظائف المنشورة: {detail.jobsCount}</p>
          <div className="toolbar" style={{ marginTop: 16 }}>
            <button className="btn btn-ghost" onClick={() => setDetail(null)}>عودة</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <>
      <PageHeader title="المستخدمون" subtitle="إدارة الحسابات والحظر والتوثيق والصلاحيات" />
      <SuccessBox message={ok} />
      <ErrorBox message={error} />
      <div className="toolbar">
        <input placeholder="ابحث بالاسم أو البريد..." value={filter} onChange={(e) => setFilter(e.target.value)} />
        <select value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
          <option value="">كل الأدوار</option>
          <option value="seeker">باحث</option>
          <option value="recruiter">جهة توظيف</option>
        </select>
      </div>
      {loading && users.length === 0 ? (
        <Spinner label="جارِ التحميل..." />
      ) : shown.length === 0 ? (
        <Empty>لا نتائج.</Empty>
      ) : (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>الاسم</th>
                <th>البريد</th>
                <th>الدور</th>
                <th>الحالة</th>
                <th>تاريخ التسجيل</th>
                <th>إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((u) => (
                <tr key={u.uid} style={u.banned ? { opacity: 0.55 } : undefined}>
                  <td>{u.displayName || "—"}</td>
                  <td>{u.email}</td>
                  <td>{u.role === "seeker" ? "باحث" : u.role === "recruiter" ? "جهة توظيف" : "بدون دور"}</td>
                  <td>
                    <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
                      {u.isAdmin && <Badge tone="danger">Admin</Badge>}
                      {u.banned ? (
                        <Badge tone="danger">محظور</Badge>
                      ) : (
                        <Badge tone="ok">نشط</Badge>
                      )}
                      {u.isVerifiedRecruiter && <Badge tone="warn">موثّقة</Badge>}
                    </div>
                  </td>
                  <td>{new Date(u.createdAt || "").toLocaleDateString("ar")}</td>
                  <td>
                    <div className="row-actions">
                      <button className="btn btn-ghost" onClick={() => openDetail(u.uid)}>ملف</button>
                      {!u.isAdmin && (
                        <ConfirmButton
                          label={u.banned ? "تنشيط" : "حظر"}
                          onClick={() => act(() => call("adminSetUserStatus", { uid: u.uid, banned: !u.banned }), "تم تحديث حالة المستخدم")}
                          kind={u.banned ? "primary" : "danger"}
                        />
                      )}
                      {u.role === "recruiter" && (
                        <ConfirmButton
                          label={u.isVerifiedRecruiter ? "إلغاء التوثيق" : "توثيق"}
                          kind="ghost"
                          onClick={() => act(() => call("adminSetUserStatus", { uid: u.uid, verified: !u.isVerifiedRecruiter }), "تم تحديث التوثيق")}
                        />
                      )}
                      {u.isAdmin ? (
                        <ConfirmButton
                          label="إزالة Admin"
                          onClick={() => act(() => call("adminSetUserStatus", { uid: u.uid, isAdmin: false }), "أُزيلت صلاحية الادمن")}
                        />
                      ) : (
                        <ConfirmButton
                          label="منح Admin"
                          kind="primary"
                          onClick={() => act(() => call("adminSetUserStatus", { uid: u.uid, isAdmin: true }), "مُنحت صلاحية الادمن")}
                        />
                      )}
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
          <button className="btn btn-ghost" onClick={() => load(cursor, true)} disabled={loading}>
            {loading ? "..." : "عرض المزيد"}
          </button>
        </div>
      )}
    </>
  );
}