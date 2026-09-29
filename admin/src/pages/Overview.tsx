import { useEffect, useState } from "react";
import { call, errorMessage } from "../api";
import type { AdminStats } from "../types";
import { StatCard, Spinner, Empty, PageHeader, Badge, ErrorBox } from "../components/ui";

export default function Overview() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    call<AdminStats>("adminGetStats").then(setStats).catch((e) => setError(errorMessage(e)));
  }, []);

  if (error) return <ErrorBox message={error} />;
  if (!stats) return <Spinner label="جارِ جمع الإحصائيات..." />;

  return (
    <>
      <PageHeader title="نظرة عامة" subtitle="صحة المنصة في لمحة" />
      <div className="grid-4">
        <StatCard label="المستخدمون" value={stats.users} />
        <StatCard label="باحثون" value={stats.seekers} hint={`جهات توظيف: ${stats.recruiters}`} />
        <StatCard label="قصص قيد المراجعة" value={stats.reviewStories} hint={`إجمالي القصص: ${stats.stories}`} />
        <StatCard label="وظائف مفتوحة" value={stats.openJobs} hint={`إجمالي: ${stats.jobs}`} />
      </div>
      <div className="grid-4">
        <StatCard label="تقديمات جديدة" value={stats.pendingApplications} hint={`إجمالي التقديمات: ${stats.applications}`} />
        <StatCard label="جهات موثقة" value={stats.verifiedRecruiters} />
        <StatCard label="مستخدمون محظورون" value={stats.bannedUsers} />
      </div>

      <div className="card" style={{ marginTop: 18 }}>
        <h2>أحدث التسجيلات</h2>
        {stats.recentUsers.length === 0 ? (
          <Empty>لا يوجد مستخدمون بعد.</Empty>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>الاسم</th>
                  <th>البريد</th>
                  <th>الدور</th>
                  <th>تاريخ التسجيل</th>
                </tr>
              </thead>
              <tbody>
                {stats.recentUsers.map((u) => (
                  <tr key={u.uid}>
                    <td>{u.displayName || "—"}</td>
                    <td>{u.email}</td>
                    <td>
                      <Badge tone={u.role === "seeker" ? "neutral" : "warn"}>
                        {u.role === "seeker" ? "باحث" : u.role === "recruiter" ? "جهة توظيف" : "بدون دور"}
                      </Badge>
                    </td>
                    <td>{new Date(u.createdAt || "").toLocaleDateString("ar")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}