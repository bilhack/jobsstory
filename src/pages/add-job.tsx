import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { getAuth } from 'firebase/auth';
import { db } from '../lib/firebase';
import { collection, addDoc, query, where, getDocs } from 'firebase/firestore';
import { getUserProfile } from '../lib/firestoreUser';

export default function AddJobPage() {
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [jobCount, setJobCount] = useState(0);
  const router = useRouter();

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = auth.onAuthStateChanged(async (firebaseUser) => {
      if (firebaseUser) {
        setUser(firebaseUser);
        const userProfile = await getUserProfile(firebaseUser.uid);
        setProfile(userProfile);
        // احسب عدد الوظائف التي أضافها المستخدم
        const jobsRef = collection(db, 'jobs');
        const q = query(jobsRef, where('uid', '==', firebaseUser.uid));
        const snap = await getDocs(q);
        setJobCount(snap.size);
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    if (!user || !profile) return;
    // الحد: وظيفة واحدة فقط إذا لم يتم التحقق
    if (!profile.isVerifiedBusiness && jobCount >= 1) {
      setError('يمكنك إضافة وظيفة واحدة فقط حتى يتم التحقق من هويتك التجارية.');
      return;
    }
    if (!title || !description) {
      setError('يرجى تعبئة جميع الحقول المطلوبة.');
      return;
    }
    try {
      await addDoc(collection(db, 'jobs'), {
        uid: user.uid,
        title,
        description,
        location,
        createdAt: new Date(),
        isVerifiedBusiness: profile.isVerifiedBusiness || false,
        displayName: profile.displayName,
        verifiedBadge: profile.isVerifiedBusiness || false,
      });
      setSuccess('تمت إضافة الوظيفة بنجاح!');
      setTitle('');
      setDescription('');
      setLocation('');
      setJobCount(j => j + 1);
    } catch (err: any) {
      setError(err.message || 'حدث خطأ أثناء إضافة الوظيفة.');
    }
  };

  if (loading) return <div className="flex items-center justify-center min-h-screen">جاري التحميل...</div>;

  if (!user) return <div className="text-center mt-12">يجب تسجيل الدخول لإضافة وظيفة.</div>;

  return (
    <main className="max-w-xl mx-auto mt-8 p-4 bg-white rounded shadow">
      <h1 className="text-2xl font-bold mb-4">إضافة وظيفة شاغرة</h1>
      {profile?.isVerifiedBusiness ? (
        <div className="mb-4 flex items-center gap-2 text-green-700">
          <span className="text-lg">✅</span>
          <span>حسابك موثوق ويمكنك إضافة وظائف غير محدودة</span>
        </div>
      ) : (
        <div className="mb-4 flex items-center gap-2 text-yellow-700">
          <span className="text-lg">⚠️</span>
          <span>يمكنك إضافة وظيفة واحدة فقط حتى يتم التحقق من هويتك التجارية</span>
        </div>
      )}
      <form onSubmit={handleSubmit} className="flex flex-col gap-3">
        <input type="text" placeholder="المسمى الوظيفي" value={title} onChange={e => setTitle(e.target.value)} className="border px-3 py-2 rounded" required />
        <textarea placeholder="وصف الوظيفة" value={description} onChange={e => setDescription(e.target.value)} className="border px-3 py-2 rounded min-h-[100px]" required />
        <input type="text" placeholder="الموقع (اختياري)" value={location} onChange={e => setLocation(e.target.value)} className="border px-3 py-2 rounded" />
        <button type="submit" className="bg-blue-700 hover:bg-blue-800 text-white py-2 rounded">إضافة الوظيفة</button>
        {error && <div className="text-red-600 text-center text-sm">{error}</div>}
        {success && <div className="text-green-600 text-center text-sm">{success}</div>}
      </form>
    </main>
  );
}
