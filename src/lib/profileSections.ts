import { collection, getDocs, orderBy, query } from 'firebase/firestore';
import { db } from './firebase';

export interface ProfileField {
  label: string;
  type: 'text' | 'number' | 'date' | 'select';
  options?: string[];
  required?: boolean;
  order: number;
}

export interface ProfileSection {
  id: string;
  title: string;
  order: number;
  fields: ProfileField[];
}

export async function getProfileSections(): Promise<ProfileSection[]> {
  const q = query(collection(db, 'profile_sections'), orderBy('order'));
  const snapshot = await getDocs(q);
  return snapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })) as ProfileSection[];
}
