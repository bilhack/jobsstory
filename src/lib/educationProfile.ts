import { db } from './firebase';
import { doc, updateDoc, arrayUnion, arrayRemove, getDoc } from 'firebase/firestore';
import { Education } from './firestoreUser';

export async function addEducation(uid: string, edu: Omit<Education, 'id'>) {
  const id = Date.now().toString();
  const eduWithId = { ...edu, id };
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    education: arrayUnion(eduWithId)
  });
  return eduWithId;
}

export async function removeEducation(uid: string, eduId: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.education) return;
  const eduToRemove = userData.education.find((e: any) => e.id === eduId);
  if (eduToRemove) {
    await updateDoc(userRef, {
      education: arrayRemove(eduToRemove)
    });
  }
}

export async function updateEducation(uid: string, updatedEdu: Education) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.education) return;
  const oldEdu = userData.education.find((e: any) => e.id === updatedEdu.id);
  if (oldEdu) {
    await updateDoc(userRef, {
      education: arrayRemove(oldEdu)
    });
    await updateDoc(userRef, {
      education: arrayUnion(updatedEdu)
    });
  }
}
