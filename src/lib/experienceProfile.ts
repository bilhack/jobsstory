import { db } from './firebase';
import { doc, updateDoc, arrayUnion, arrayRemove, getDoc } from 'firebase/firestore';
import { Experience } from './firestoreUser';

export async function addExperience(uid: string, exp: Omit<Experience, 'id'>) {
  const id = Date.now().toString();
  const expWithId = { ...exp, id };
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    experience: arrayUnion(expWithId)
  });
  return expWithId;
}

export async function removeExperience(uid: string, expId: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.experience) return;
  const expToRemove = userData.experience.find((e: any) => e.id === expId);
  if (expToRemove) {
    await updateDoc(userRef, {
      experience: arrayRemove(expToRemove)
    });
  }
}

export async function updateExperience(uid: string, updatedExp: Experience) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.experience) return;
  const oldExp = userData.experience.find((e: any) => e.id === updatedExp.id);
  if (oldExp) {
    await updateDoc(userRef, {
      experience: arrayRemove(oldExp)
    });
    await updateDoc(userRef, {
      experience: arrayUnion(updatedExp)
    });
  }
}
