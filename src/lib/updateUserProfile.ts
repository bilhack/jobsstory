import { doc, updateDoc } from 'firebase/firestore';
import { db } from './firebase';

export async function updateUserProfile(uid: string, data: Partial<import('./firestoreUser').UserProfile>) {
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, data);
}
