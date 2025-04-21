import { useEffect, useState } from 'react';
import { getAuth, onAuthStateChanged, User as FirebaseUser } from 'firebase/auth';
import { db } from '../lib/firebase';
import { doc, getDoc, collection, getDocs } from 'firebase/firestore';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';
import Link from 'next/link';

interface VideoDoc {
  id: string;
  uid: string;
  videoUrl: string;
  thumbnailUrl?: string;
  title?: string;
}

export default function FavoritesPage() {
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null);
  const [favorites, setFavorites] = useState<VideoDoc[]>([]);
  const [usersMap, setUsersMap] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (!currentUser) return;
    setLoading(true);
    const fetchFavorites = async () => {
      try {
        // Get user's savedVideos
        const userRef = doc(db, 'users', currentUser.uid);
        const userSnap = await getDoc(userRef);
        const userData = userSnap.data();
        const savedIds: string[] = userData?.savedVideos || [];
        if (!savedIds.length) {
          setFavorites([]);
          setLoading(false);
          return;
        }
        // Fetch videos
        const videosSnap = await getDocs(collection(db, 'videos'));
        const favs: VideoDoc[] = [];
        videosSnap.forEach(docSnap => {
          if (savedIds.includes(docSnap.id)) {
            favs.push({ id: docSnap.id, ...docSnap.data() } as VideoDoc);
          }
        });
        setFavorites(favs);
        // Fetch users for profiles
        const usersSnap = await getDocs(collection(db, 'users'));
        const map: Record<string, any> = {};
        usersSnap.forEach(userDoc => {
          map[userDoc.id] = userDoc.data();
        });
        setUsersMap(map);
      } catch (err: any) {
        setError('حدث خطأ أثناء تحميل المفضلات');
      } finally {
        setLoading(false);
      }
    };
    fetchFavorites();
  }, [currentUser]);

  return (
    <div className="min-h-screen bg-[#f3f6fb]">
      <HeaderLinkedinWeb />
      <div className="max-w-3xl mx-auto mt-20 bg-white rounded-xl shadow p-6">
        <h1 className="text-2xl font-bold text-[#1666b1] mb-6">قائمة المفضلات</h1>
        {loading ? (
          <div>جاري التحميل...</div>
        ) : error ? (
          <div className="text-red-600">{error}</div>
        ) : favorites.length === 0 ? (
          <div className="text-center text-gray-500">لا توجد فيديوهات مضافة للمفضلة.</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {favorites.map(video => (
              <div key={video.id} className="bg-[#f8fafc] rounded-lg shadow p-4 flex flex-col items-center">
                <video
                  src={video.videoUrl}
                  poster={video.thumbnailUrl}
                  controls
                  className="w-full max-w-[260px] h-[320px] object-cover rounded mb-2"
                />
                <div className="flex items-center gap-2 mb-2">
                  <img
                    src={usersMap[video.uid]?.photoURL || '/user.png'}
                    alt="User"
                    className="w-10 h-10 rounded-full border"
                  />
                  <span className="font-bold text-[#1666b1]">{usersMap[video.uid]?.displayName || 'مستخدم'}</span>
                </div>
                <div className="flex gap-2 mt-2">
                  <Link href={`/profile/${video.uid}`} legacyBehavior>
                    <a className="bg-[#1666b1] text-white px-4 py-1 rounded-full font-bold hover:bg-[#12518e]">عرض البروفايل</a>
                  </Link>
                  <button className="bg-[#f58220] text-white px-4 py-1 rounded-full font-bold hover:bg-[#c96a12]" onClick={() => window.open(`mailto:${usersMap[video.uid]?.email || ''}`)}>
                    إرسال رسالة
                  </button>
                </div>
                <div className="mt-2 text-sm text-gray-700">
                  <span>السيرة الذاتية:</span>
                  <span className="block font-bold text-gray-900">{usersMap[video.uid]?.bio || 'لا توجد سيرة ذاتية'}</span>
                </div>
                <div className="mt-2 text-sm text-gray-700">
                  <span>الأوراق والشهادات:</span>
                  <span className="block font-bold text-gray-900">{Array.isArray(usersMap[video.uid]?.certifications) && usersMap[video.uid]?.certifications.length > 0 ? usersMap[video.uid].certifications.map((c:any) => c.name).join(', ') : 'لا يوجد'}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
