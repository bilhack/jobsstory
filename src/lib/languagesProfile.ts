import { db } from './firebase';
import { doc, updateDoc, getDoc } from 'firebase/firestore';

export async function addLanguage(uid: string, lang: string) {
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    languages: (await getDoc(userRef)).data()?.languages ? [...(await getDoc(userRef)).data()?.languages, lang] : [lang]
  });
}

export async function removeLanguage(uid: string, lang: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.languages) return;
  const newLangs = userData.languages.filter((l: string) => l !== lang);
  await updateDoc(userRef, { languages: newLangs });
}
