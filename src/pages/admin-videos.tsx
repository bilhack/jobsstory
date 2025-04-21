import { useEffect, useState } from 'react';
import { getDocs, collection, updateDoc, doc, deleteDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';

interface VideoDoc {
  id: string;
  uid: string;
  videoUrl: string;
  thumbnailUrl?: string;
  status?: 'pending' | 'approved' | 'rejected';
  createdAt?: any;
}

export default function AdminVideos() {
  const [videos, setVideos] = useState<VideoDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchVideos = async () => {
      try {
        const snapshot = await getDocs(collection(db, 'videos'));
        const videosList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as VideoDoc[];
        setVideos(videosList);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchVideos();
  }, []);

  const handleStatusChange = async (id: string, status: 'pending' | 'approved' | 'rejected') => {
    await updateDoc(doc(db, 'videos', id), { status });
    setVideos(videos => videos.map(v => (v.id === id ? { ...v, status } : v)));
  };

  const handleDeleteVideo = async (id: string) => {
    await deleteDoc(doc(db, 'videos', id));
    setVideos(videos => videos.filter(v => v.id !== id));
  };

  return (
    <div className="min-h-screen bg-[#f3f6fb]">
      <HeaderLinkedinWeb />
      <div className="max-w-5xl mx-auto mt-16 bg-white rounded-xl shadow p-8">
        <div className="flex gap-4 mb-8">
          <a href="/admin" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">المستخدمون</a>
          <a href="/admin-videos" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">الفيديوهات</a>
          <a href="/admin-sections" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">السكاشن</a>
        </div>
        <h1 className="text-2xl font-bold mb-6 text-[#1666b1]">إدارة فيديوهات المستخدمين</h1>
        {loading ? (
          <div>جاري التحميل...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="w-full border text-right">
            <thead>
              <tr className="bg-[#f3f6fb]">
                <th className="p-2">المستخدم</th>
                <th className="p-2">الفيديو</th>
                <th className="p-2">الحالة</th>
                <th className="p-2">تاريخ الرفع</th>
                <th className="p-2">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {videos.map(video => (
                <tr key={video.id} className="border-b">
                  <td className="p-2">{video.uid}</td>
                  <td className="p-2">
                    <video src={video.videoUrl} controls width={120} className="rounded shadow" />
                  </td>
                  <td className="p-2">
                    <select
                      className="border rounded px-2 py-1"
                      value={video.status || 'pending'}
                      onChange={e => handleStatusChange(video.id, e.target.value as any)}
                    >
                      <option value="pending">قيد المراجعة</option>
                      <option value="approved">مقبول</option>
                      <option value="rejected">مرفوض</option>
                    </select>
                  </td>
                  <td className="p-2">{video.createdAt ? new Date(video.createdAt.seconds * 1000).toLocaleDateString() : '-'}</td>
                  <td className="p-2">
                    <button
                      className="bg-red-500 hover:bg-red-700 text-white px-3 py-1 rounded"
                      onClick={() => handleDeleteVideo(video.id)}
                    >حذف</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
