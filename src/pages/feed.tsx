import { useEffect, useState, useRef } from 'react';
import { getDocs, collection, doc, getDoc, updateDoc, arrayUnion } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { getAuth, onAuthStateChanged, User as FirebaseUser } from 'firebase/auth';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';
import BottomNavigation from '../components/BottomNavigation';

interface VideoDoc {
  id: string;
  uid: string;
  videoUrl: string;
  thumbnailUrl?: string;
  likes?: string[];
  createdAt?: any;
}

export default function FeedPage() {
  const [videos, setVideos] = useState<VideoDoc[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeIdx, setActiveIdx] = useState(0);
  const videoRefs = useRef<(HTMLVideoElement | null)[]>([]);
  const [usersMap, setUsersMap] = useState<Record<string, { displayName: string; photoURL?: string }>>({});
  const [savedVideos, setSavedVideos] = useState<string[]>([]);
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null);

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    const fetchVideos = async () => {
      try {
        const snapshot = await getDocs(collection(db, 'videos'));
        let list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as VideoDoc[];
        // ترتيب الأحدث أولاً
        list = list.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));
        setVideos(list);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchVideos();
  }, []);

  useEffect(() => {
    const fetchUsers = async () => {
      const snapshot = await getDocs(collection(db, 'users'));
      const map: Record<string, { displayName: string; photoURL?: string }> = {};
      snapshot.docs.forEach(doc => {
        const d = doc.data();
        map[doc.id] = { displayName: d.displayName || 'مستخدم', photoURL: d.photoURL };
      });
      setUsersMap(map);
    };
    fetchUsers();
  }, []);

  useEffect(() => {
    // تحميل الفيديوهات المحفوظة للمستخدم الحالي عند تسجيل الدخول
    if (!currentUser) return;
    const fetchSaved = async () => {
      const userRef = doc(db, 'users', currentUser.uid);
      const userSnap = await getDoc(userRef);
      const userData = userSnap.data();
      setSavedVideos(userData?.savedVideos || []);
    };
    fetchSaved();
  }, [currentUser]);

  // تشغيل الفيديو النشط وإيقاف الباقي
  useEffect(() => {
    videoRefs.current.forEach((video, idx) => {
      if (video) {
        if (idx === activeIdx) {
          video.play();
        } else {
          video.pause();
          video.currentTime = 0;
        }
      }
    });
  }, [activeIdx, videos]);

  // التمرير الرأسي
  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const scrollPos = e.currentTarget.scrollTop;
    const height = window.innerHeight;
    const idx = Math.round(scrollPos / height);
    setActiveIdx(idx);
  };

  // لايك الفيديو
  const handleLike = async (videoId: string) => {
    if (!currentUser) {
      alert('يجب تسجيل الدخول لتسجيل الإعجاب');
      return;
    }
    const userId = currentUser.uid;
    const videoRef = doc(db, 'videos', videoId);
    const videoSnap = await getDoc(videoRef);
    const videoData = videoSnap.data();
    if (!videoData) return;
    if (Array.isArray(videoData.likes) && videoData.likes.includes(userId)) return;
    await updateDoc(videoRef, { likes: arrayUnion(userId) });
    setVideos(videos => videos.map(v => v.id === videoId ? { ...v, likes: [...(v.likes || []), userId] } : v));
  };

  // زر حفظ الفيديو
  const handleSave = async (videoId: string) => {
    if (!currentUser) {
      alert('يجب تسجيل الدخول لحفظ الفيديو');
      return;
    }
    setSavedVideos(arr => arr.includes(videoId) ? arr : [...arr, videoId]);
    // حفظ الفيديو في حساب المستخدم في Firestore
    const userRef = doc(db, 'users', currentUser.uid);
    await updateDoc(userRef, {
      savedVideos: arrayUnion(videoId)
    });
  };

  // زر مشاركة الفيديو
  const handleShare = (videoUrl: string) => {
    if (navigator.share) {
      navigator.share({ url: videoUrl, title: 'شاهد سيرتي على JobsStory!' });
    } else {
      navigator.clipboard.writeText(videoUrl);
      alert('تم نسخ رابط الفيديو!');
    }
  };

  return (
    <div className="min-h-screen bg-black">
      <HeaderLinkedinWeb />
      <div className="fixed top-0 left-0 right-0 z-20">
        <div className="max-w-xl mx-auto flex justify-between items-center p-4">
          <img src="/logo.png" alt="JobsStory" className="h-10" />
          <span className="text-white font-bold text-xl">القصص الوظيفية</span>
        </div>
      </div>
      <div
        className="relative w-full h-screen overflow-y-scroll snap-y snap-mandatory bg-black"
        onScroll={handleScroll}
        style={{ scrollSnapType: 'y mandatory' }}
      >
        {loading ? (
          <div className="flex justify-center items-center h-screen">
            <span className="text-white text-lg font-bold">جاري تحميل الفيديوهات ...</span>
          </div>
        ) : error ? (
          <div className="flex justify-center items-center h-screen">
            <span className="text-red-600 text-lg font-bold">{error}</span>
          </div>
        ) : (
          videos.map((video, idx) => (
            <div
              key={video.id}
              className="snap-center flex flex-col justify-center items-center h-screen relative bg-black"
              style={{ minHeight: '100vh' }}
            >
              <div className="relative flex flex-col items-center justify-center min-h-[80vh] w-full">
                <video
                  ref={el => (videoRefs.current[idx] = el)}
                  src={video.videoUrl}
                  controls={false}
                  loop
                  muted
                  className="w-full max-w-[430px] h-[80vh] object-cover rounded-xl shadow-2xl mx-auto border-4 border-gray-900"
                  poster={video.thumbnailUrl}
                  playsInline
                  autoPlay={idx === activeIdx}
                  style={{ background: '#111' }}
                />
                {/* أزرار التفاعل الجانبية */}
                <div className="absolute right-6 top-1/2 -translate-y-1/2 flex flex-col gap-6 z-20">
                  <button
                    className={`flex flex-col items-center justify-center bg-white bg-opacity-90 hover:bg-opacity-100 rounded-full p-4 shadow-xl transition text-gray-900 ${video.likes?.includes(currentUser?.uid) ? 'opacity-60' : ''}`}
                    onClick={() => handleLike(video.id)}
                    disabled={!currentUser || video.likes?.includes(currentUser?.uid)}
                  >
                    <span className="text-3xl">👍</span>
                    <span className="text-xs text-gray-700 font-bold mt-1">{video.likes ? video.likes.length : 0}</span>
                  </button>
                  <button
                    className={`flex flex-col items-center justify-center bg-white bg-opacity-90 hover:bg-opacity-100 rounded-full p-4 shadow-xl transition text-gray-900 ${savedVideos.includes(video.id) ? 'opacity-60' : ''}`}
                    onClick={() => handleSave(video.id)}
                    disabled={!currentUser || savedVideos.includes(video.id)}
                  >
                    <span className="text-3xl">💾</span>
                    <span className="text-xs text-gray-700 font-bold mt-1">حفظ</span>
                  </button>
                  <button
                    className="flex flex-col items-center justify-center bg-white bg-opacity-90 hover:bg-opacity-100 rounded-full p-4 shadow-xl transition text-gray-900"
                    onClick={() => handleShare(video.videoUrl)}
                  >
                    <span className="text-3xl">🔗</span>
                    <span className="text-xs text-gray-700 font-bold mt-1">مشاركة</span>
                  </button>
                  <button
                    className={`flex flex-col items-center justify-center bg-yellow-400 hover:bg-yellow-500 rounded-full p-4 shadow-xl transition text-gray-900 ${savedVideos.includes(video.id) ? 'opacity-60' : ''}`}
                    onClick={() => handleSave(video.id)}
                    disabled={!currentUser || savedVideos.includes(video.id)}
                    title="إضافة إلى المفضلة"
                  >
                    <span className="text-3xl">⭐</span>
                    <span className="text-xs text-gray-700 font-bold mt-1">مفضلة</span>
                  </button>
                </div>
                {/* بيانات صاحب الفيديو */}
                <div className="absolute bottom-24 left-0 right-0 flex flex-col items-center">
                  <div className="flex items-center gap-3 mb-2 bg-black bg-opacity-60 px-4 py-2 rounded-full shadow">
                    <img
                      src={usersMap[video.uid]?.photoURL || '/user.png'}
                      alt="User"
                      className="w-12 h-12 rounded-full border-2 border-white shadow"
                    />
                    <span className="text-white font-bold text-lg">{usersMap[video.uid]?.displayName || 'مستخدم'}</span>
                  </div>
                </div>
              </div>
            </div>
          ))
        )}
        {/* شريط التنقل السفلي */}
        <BottomNavigation />
      </div>
    </div>
  );
}
