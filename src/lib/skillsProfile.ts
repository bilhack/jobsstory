import { db } from './firebase';
import { doc, updateDoc, getDoc } from 'firebase/firestore';

export async function addSkill(uid: string, skill: string) {
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    skills: (await getDoc(userRef)).data()?.skills ? [...(await getDoc(userRef)).data()?.skills, skill] : [skill]
  });
}

export async function removeSkill(uid: string, skill: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.skills) return;
  const newSkills = userData.skills.filter((s: string) => s !== skill);
  await updateDoc(userRef, { skills: newSkills });
}
