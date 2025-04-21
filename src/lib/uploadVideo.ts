import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';

export async function uploadVideo(file: File, uid: string): Promise<string> {
  const storage = getStorage();
  const videoRef = ref(storage, `videos/${uid}/${Date.now()}_${file.name}`);
  await uploadBytes(videoRef, file);
  const url = await getDownloadURL(videoRef);
  return url;
}
