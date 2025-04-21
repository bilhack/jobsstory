import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase';

export interface Experience {
  id: string;
  title: string;
  company: string;
  location?: string;
  startDate: string;
  endDate?: string;
  description?: string;
}

export interface Education {
  id: string;
  school: string;
  degree: string;
  field: string;
  startDate: string;
  endDate?: string;
  description?: string;
}

export interface Certification {
  id: string;
  name: string;
  authority: string;
  date: string;
}

export interface Project {
  id: string;
  name: string;
  description?: string;
  url?: string;
}

export interface UserProfile {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  role: 'jobseeker' | 'recruiter' | 'admin';
  videoURL?: string;
  about?: string;
  experience?: Experience[];
  education?: Education[];
  skills?: string[];
  certifications?: Certification[];
  languages?: string[];
  projects?: Project[];
  contact?: {
    phone?: string;
    linkedin?: string;
    website?: string;
    [key: string]: string | undefined;
  };
  isVerifiedBusiness?: boolean;
  commercialRecordURL?: string;
  headline?: string;
  createdAt?: any;
}

export async function createOrUpdateUserProfile(user: any, role: 'jobseeker' | 'recruiter' | 'admin') {
  if (!user) return;
  const ref = doc(db, 'users', user.uid);
  const data: UserProfile = {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
    role,
    createdAt: serverTimestamp(),
  };
  await setDoc(ref, data, { merge: true });
}

export async function getUserProfile(uid: string): Promise<UserProfile | null> {
  const ref = doc(db, 'users', uid);
  const snap = await getDoc(ref);
  if (snap.exists()) {
    return snap.data() as UserProfile;
  }
  return null;
}
