import { useState, type ReactNode } from "react";

export function Spinner({ label }: { label?: string }) {
  return (
    <div className="center">
      <span className="spinner" />
      {label && <p className="muted">{label}</p>}
    </div>
  );
}

export function Empty({ icon, children }: { icon?: ReactNode; children: ReactNode }) {
  return (
    <div className="empty">
      {icon}
      <p>{children}</p>
    </div>
  );
}

export function Badge({ tone, children }: { tone: "ok" | "warn" | "danger" | "neutral"; children: ReactNode }) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}

export function StatCard({ label, value, hint, icon, tone }: { label: string; value: number | string; hint?: string; icon?: ReactNode; tone?: string }) {
  return (
    <div className={`card stat ${tone || ""}`}>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      {hint && <div className="stat-hint">{hint}</div>}
      {icon && <div className="stat-icon">{icon}</div>}
    </div>
  );
}

/** زر يؤكد التنفيذ بنقرتين لتفادي الأخطاء. */
export function ConfirmButton({ label, confirm = "تأكيد؟", onClick, kind = "danger", busy }: {
  label: string;
  confirm?: string;
  onClick: () => Promise<void> | void;
  kind?: "danger" | "primary" | "ghost";
  busy?: boolean;
}) {
  const [armed, setArmed] = useState(false);
  return (
    <button
      className={`btn btn-${armed ? "danger" : kind}`}
      disabled={busy}
      onClick={async () => {
        if (!armed) {
          setArmed(true);
          setTimeout(() => setArmed(false), 2500);
          return;
        }
        setArmed(false);
        await onClick();
      }}
    >
      {busy ? "..." : armed ? confirm : label}
    </button>
  );
}

export function ErrorBox({ message }: { message: string }) {
  if (!message) return null;
  return <div className="alert alert-danger">{message}</div>;
}

export function SuccessBox({ message }: { message: string }) {
  if (!message) return null;
  return <div className="alert alert-ok">{message}</div>;
}

export function PageHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="page-head">
      <h1>{title}</h1>
      {subtitle && <p className="muted">{subtitle}</p>}
    </div>
  );
}