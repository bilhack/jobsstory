import { useState, useEffect } from 'react';
import { db } from '../lib/firebase';
import { collection, getDocs } from 'firebase/firestore';

export default function JobsPage() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchJobs = async () => {
      setLoading(true);
      const snap = await getDocs(collection(db, 'jobs'));
      setJobs(snap.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    };
    fetchJobs();
  }, []);

  return (
    <main className="max-w-2xl mx-auto mt-8 p-4 bg-white rounded shadow">
      <h1 className="text-2xl font-bold mb-6">الوظائف الشاغرة</h1>
      {loading ? <div>جاري التحميل...</div> :
        jobs.length === 0 ? <div>لا توجد وظائف حالياً.</div> :
        <ul className="space-y-6">
          {jobs.map(job => (
            <li key={job.id} className="border rounded p-4 bg-gray-50">
              <div className="flex items-center gap-2 mb-2">
                <span className="font-bold text-lg">{job.title}</span>
                {job.verifiedBadge && <span className="bg-green-200 text-green-800 px-2 py-1 rounded text-xs font-bold flex items-center gap-1">موثوق <span>✅</span></span>}
              </div>
              <div className="mb-1 text-gray-800 whitespace-pre-line">{job.description}</div>
              <div className="text-sm text-gray-500">{job.location && <>الموقع: {job.location}</>}</div>
              <div className="text-xs text-gray-400 mt-2">صاحب الإعلان: {job.displayName || 'مستخدم'} {job.verifiedBadge && <span className="ml-1">✅</span>}</div>
            </li>
          ))}
        </ul>
      }
    </main>
  );
}
