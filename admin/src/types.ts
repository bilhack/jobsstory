export interface AdminStats {
  users: number;
  seekers: number;
  recruiters: number;
  verifiedRecruiters: number;
  bannedUsers: number;
  stories: number;
  reviewStories: number;
  jobs: number;
  openJobs: number;
  applications: number;
  pendingApplications: number;
  recentUsers: UserRow[];
}

export interface UserRow {
  uid: string;
  email: string;
  displayName: string;
  role: string;
  headline: string;
  location: string;
  isAdmin: boolean;
  banned: boolean;
  isVerifiedRecruiter: boolean;
  createdAt: string | null;
}

export interface StoryRow {
  id: string;
  ownerUid: string;
  ownerName: string;
  caption: string;
  thumbnailUrl: string;
  videoUrl: string;
  durationMs: number;
  status: string;
  featured: boolean;
  createdAt: string | null;
}

export interface JobRow {
  id: string;
  title: string;
  company: string;
  location: string;
  description: string;
  status: string;
  createdBy: string;
  recruiter: string;
  createdAt: string | null;
}

export interface ApplicationRow {
  id: string;
  jobId: string;
  jobTitle: string;
  seekerUid: string;
  seekerName: string;
  seekerEmail: string;
  status: string;
  storyId: string;
  appliedAt: string | null;
}

export interface UserDetail {
  user: UserRow;
  stories: { id: string; caption: string; status: string; createdAt: string | null }[];
  jobsCount: number;
}

export interface BroadcastResult {
  ok: boolean;
  targeted: number;
  sent: number;
}

export function fmtDate(iso: string | null): string {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("ar", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export const storyStatusLabels: Record<string, string> = {
  review: "قيد المراجعة",
  approved: "معتمدة",
  hidden: "مخفية",
};

export const userRoleLabels: Record<string, string> = {
  seeker: "باحث",
  recruiter: "جهة توظيف",
  "": "بدون دور",
};

export const applicationStatusLabels: Record<string, string> = {
  pending: "جديد",
  contacted: "تم التواصل",
  rejected: "مرفوض",
};