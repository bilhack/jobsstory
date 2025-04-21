import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';

export async function uploadCommercialRecord(file: File, uid: string): Promise<string> {
  const storage = getStorage();
  const fileRef = ref(storage, `commercialRecords/${uid}/${Date.now()}_${file.name}`);
  await uploadBytes(fileRef, file);
  return await getDownloadURL(fileRef);
}
