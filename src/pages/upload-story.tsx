import { useState } from 'react';
import { getAuth } from 'firebase/auth';
import { db, storage } from '../lib/firebase';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { useRouter } from 'next/router';
import VideoRecorder from '../components/VideoRecorder';

export default function UploadStory() {
  const [video, setVideo] = useState<File | null>(null);
  const [title, setTitle] = useState('');
  const [desc, setDesc] = useState('');
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState('');
  const router = useRouter();

  const handleVideoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      if (file.type.startsWith('video/') && file.size <= 65 * 1024 * 1024) {
        setVideo(file);
        setError('');
      } else {
        setError('يجب أن يكون الملف فيديو وأقل من 60 ثانية (حجم 65MB تقريبًا)');
      }
    }
  };

  const handleRecorded = (file: File) => {
    setVideo(file);
    setError('');
  };

  const handleUpload = async () => {
    if (!video || !title) {
      setError('يرجى اختيار فيديو وكتابة عنوان');
      return;
    }
    setUploading(true);
    setError('');
    try {
      const auth = getAuth();
      const user = auth.currentUser;
      if (!user) throw new Error('يجب تسجيل الدخول');
      // رفع الفيديو
      const videoRef = ref(storage, `videos/${user.uid}_${Date.now()}`);
      const uploadTask = uploadBytesResumable(videoRef, video);
      uploadTask.on('state_changed', (snap) => {
        setProgress(Math.round((snap.bytesTransferred / snap.totalBytes) * 100));
      });
      await uploadTask;
      const videoUrl = await getDownloadURL(videoRef);
      // حفظ البيانات في Firestore
      await addDoc(collection(db, 'videos'), {
        uid: user.uid,
        videoUrl,
        title,
        desc,
        createdAt: serverTimestamp(),
      });
      setUploading(false);
      setProgress(0);
      setVideo(null);
      setTitle('');
      setDesc('');
      router.push('/feed');
    } catch (err: any) {
      setError(err.message || 'حدث خطأ أثناء رفع الفيديو');
      setUploading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#f3f6fb] flex flex-col items-center justify-center py-12 px-4">
      <div className="bg-white rounded-xl shadow-lg p-8 w-full max-w-lg">
        <h2 className="text-2xl font-bold text-[#1666b1] mb-6 text-center">رفع فيديو السيرة الذاتية (60 ثانية)</h2>
        <div className="mb-6">
          <h3 className="text-lg font-semibold text-gray-700 mb-2">يمكنك تسجيل فيديو جديد مباشرة من الكاميرا:</h3>
          <VideoRecorder onRecorded={handleRecorded} />
          <div className="text-center text-gray-500 text-sm mb-2">أو اختر فيديو من جهازك</div>
        </div>
        <input
          type="file"
          accept="video/*"
          onChange={handleVideoChange}
          className="mb-4 w-full border rounded px-3 py-2"
        />
        {video && (
          <video src={URL.createObjectURL(video)} controls className="w-full rounded mb-4 max-h-[300px]" />
        )}
        <input
          type="text"
          placeholder="عنوان الفيديو (مثال: مطور واجهات أمامية)"
          value={title}
          onChange={e => setTitle(e.target.value)}
          className="mb-4 w-full border rounded px-3 py-2"
        />
        <textarea
          placeholder="وصف مختصر (اختياري)"
          value={desc}
          onChange={e => setDesc(e.target.value)}
          className="mb-4 w-full border rounded px-3 py-2"
        />
        {error && <div className="text-red-600 mb-4 text-center">{error}</div>}
        {uploading && (
          <div className="mb-4 text-center text-blue-600">جاري رفع الفيديو... {progress}%</div>
        )}
        <button
          onClick={handleUpload}
          disabled={uploading}
          className="bg-[#1666b1] text-white font-bold w-full py-3 rounded hover:bg-[#145a99] transition"
        >
          رفع الفيديو
        </button>
      </div>
    </div>
  );
}
