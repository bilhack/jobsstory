import { db } from './firebase';
import { doc, updateDoc } from 'firebase/firestore';

export async function updateContact(uid: string, contact: Record<string, string>) {
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, { contact });
}
