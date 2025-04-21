import { db } from './firebase';
import { doc, updateDoc, arrayUnion, arrayRemove, getDoc } from 'firebase/firestore';
import { Certification } from './firestoreUser';

export async function addCertification(uid: string, cert: Omit<Certification, 'id'>) {
  const id = Date.now().toString();
  const certWithId = { ...cert, id };
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    certifications: arrayUnion(certWithId)
  });
  return certWithId;
}

export async function removeCertification(uid: string, certId: string) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.certifications) return;
  const certToRemove = userData.certifications.find((c: any) => c.id === certId);
  if (certToRemove) {
    await updateDoc(userRef, {
      certifications: arrayRemove(certToRemove)
    });
  }
}

export async function updateCertification(uid: string, updatedCert: Certification) {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  const userData = userSnap.data();
  if (!userData || !userData.certifications) return;
  const oldCert = userData.certifications.find((c: any) => c.id === updatedCert.id);
  if (oldCert) {
    await updateDoc(userRef, {
      certifications: arrayRemove(oldCert)
    });
    await updateDoc(userRef, {
      certifications: arrayUnion(updatedCert)
    });
  }
}
