import { useEffect, useState } from "react";
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword, GoogleAuthProvider, signInWithPopup, signOut, type User } from "firebase/auth";
import { app, firebaseConfig } from "./firebase";
import { call, errorMessage } from "./api";
import Overview from "./pages/Overview";
import Users from "./pages/Users";
import Stories from "./pages/Stories";
import Jobs from "./pages/Jobs";
import Applications from "./pages/Applications";
import Broadcast from "./pages/Broadcast";
import { Spinner, ErrorBox } from "./components/ui";

const auth = getAuth(app);

type TabId = "overview" | "users" | "stories" | "jobs" | "applications" | "broadcast";

const NAV: { id: TabId; label: string; icon: JSX.Element }[] = [
  { id: "overview", label: "نظرة عامة", icon: <IconDashboard /> },
  { id: "users", label: "المستخدمون", icon: <IconUsers /> },
  { id: "stories", label: "القصص", icon: <IconFilm /> },
  { id: "jobs", label: "الوظائف", icon: <IconBriefcase /> },
  { id: "applications", label: "التقديمات", icon: <IconInbox /> },
  { id: "broadcast", label: "إشعار البث", icon: <IconBell /> },
];

export default function App() {
  const [user, setUser] = useState<User | null | undefined>(undefined);

  useEffect(() => onAuthStateChanged(auth, setUser), []);

  if (user === undefined) return <Spinner label="جارِ التحقق من الجلسة..." />;
  if (!user) return <Login />;
  return <Main />;
}

function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err) {
      setError(authMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const google = async () => {
    setBusy(true);
    setError("");
    try {
      await signInWithPopup(auth, new GoogleAuthProvider());
    } catch (err) {
      setError(authMessage(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="login-wrap">
      <form className="card login-card" onSubmit={submit}>
        <div className="brand" style={{ padding: "0 0 14px" }}>
          <div className="brand-logo">J</div>
          <div>
            <div className="brand-name">JobsStory</div>
            <div className="brand-sub">لوحة تحكم المشرف</div>
          </div>
        </div>
        <ErrorBox message={error} />
        <div className="field">
          <label>البريد الإلكتروني</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" required />
        </div>
        <div className="field">
          <label>كلمة المرور</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" required />
        </div>
        <button className="btn btn-primary" type="submit" disabled={busy} style={{ padding: "12px", marginBottom: 10 }}>
          {busy ? "..." : "دخول"}
        </button>
        <button className="btn btn-ghost" type="button" onClick={google} disabled={busy}>
          الدخول عبر Google
        </button>
        <p className="muted" style={{ marginTop: 14, fontSize: 11.5 }}>
          لا يُمنح الدخول إلا لحساب يحمل isAdmin: true في وثيقته (users/&lt;uid&gt;).
        </p>
      </form>
    </div>
  );
}

function Main() {
  const [tab, setTab] = useState<TabId>("overview");
  const [denied, setDenied] = useState("");

  useEffect(() => {
    call("adminPing").catch((e) => setDenied(errorMessage(e)));
  }, []);

  if (denied) {
    return (
      <div className="login-wrap">
        <div className="card login-card" style={{ textAlign: "center" }}>
          <div style={{ fontSize: 30, fontWeight: 900 }}>ممنوع الوصول</div>
          <p className="muted" style={{ margin: "12px 0 18px" }}>{denied}</p>
          <button className="btn btn-ghost" onClick={() => signOut(auth)}>تسجيل الخروج</button>
        </div>
      </div>
    );
  }

  return (
    <div className="app">
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-logo">J</div>
          <div>
            <div className="brand-name">JobsStory</div>
            <div className="brand-sub">لوحة تحكم المشرف</div>
          </div>
        </div>
        {NAV.map((n) => (
          <button key={n.id} className={`nav-item ${tab === n.id ? "active" : ""}`} onClick={() => setTab(n.id)}>
            {n.icon}
            {n.label}
          </button>
        ))}
        <div className="sidebar-foot">
          <button className="nav-item" onClick={() => signOut(auth)}>
            <IconSignOut />
            تسجيل الخروج
          </button>
        </div>
      </aside>
      <main className="content">
        {tab === "overview" && <Overview />}
        {tab === "users" && <Users />}
        {tab === "stories" && <Stories />}
        {tab === "jobs" && <Jobs />}
        {tab === "applications" && <Applications />}
        {tab === "broadcast" && <Broadcast />}
      </main>
    </div>
  );
}

function authMessage(error: unknown): string {
  const code = (error as { code?: string })?.code ?? "";
  const map: Record<string, string> = {
    "auth/invalid-credential": "بيانات الدخول غير صحيحة.",
    "auth/wrong-password": "كلمة المرور غير صحيحة.",
    "auth/user-not-found": "لا يوجد حساب بهذا البريد.",
    "auth/invalid-email": "البريد الإلكتروني غير صالح.",
    "auth/network-request-failed": "تعذّر الاتصال بالإنترنت.",
    "auth/popup-closed-by-user": "أُغلقت نافذة الدخول قبل الإكمال.",
  };
  return map[code] || `تعذّر تسجيل الدخول (${code || "unknown"})`;
}

function stroke(): React.SVGAttributes<SVGElement> {
  return { fill: "none", stroke: "currentColor", strokeWidth: 2, strokeLinecap: "round", strokeLinejoin: "round" };
}

function IconDashboard() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <rect x="3" y="3" width="7" height="9" rx="2" {...stroke()} />
      <rect x="14" y="3" width="7" height="5" rx="2" {...stroke()} />
      <rect x="14" y="12" width="7" height="9" rx="2" {...stroke()} />
      <rect x="3" y="16" width="7" height="5" rx="2" {...stroke()} />
    </svg>
  );
}

function IconUsers() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <circle cx="9" cy="8" r="3.5" {...stroke()} />
      <path d="M2.5 20c1-3.5 3.7-5 6.5-5s5.5 1.5 6.5 5" {...stroke()} />
      <circle cx="17" cy="9" r="3" {...stroke()} />
      <path d="M16 15.5c2.6.3 4.6 1.8 5.5 4.5" {...stroke()} />
    </svg>
  );
}

function IconFilm() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <rect x="3" y="4" width="18" height="16" rx="3" {...stroke()} />
      <path d="M7 8h.01M17 8h.01M7 13h.01M17 13h.01M7 17h.01M17 17h.01" {...stroke()} />
    </svg>
  );
}

function IconBriefcase() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <rect x="3" y="7" width="18" height="13" rx="3" {...stroke()} />
      <path d="M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2m-9 5h18" {...stroke()} />
    </svg>
  );
}

function IconInbox() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <path d="M4 4h16l2 7v7a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-7l2-7Z" {...stroke()} />
      <path d="M2 11h6l2 3h4l2-3h6" {...stroke()} />
    </svg>
  );
}

function IconBell() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <path d="M6 9a6 6 0 1 1 12 0c0 5 2 6 2 6H4s2-1 2-6Z" {...stroke()} />
      <path d="M10 19a2 2 0 0 0 4 0" {...stroke()} />
    </svg>
  );
}

function IconSignOut() {
  return (
    <svg width={18} height={18} viewBox="0 0 24 24">
      <path d="M15 4h2a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-2" {...stroke()} />
      <path d="M9 16l-4-4 4-4M5 12h10" {...stroke()} />
    </svg>
  );
}