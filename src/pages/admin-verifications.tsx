import { useState, useEffect } from 'react';
import { getAuth } from 'firebase/auth';
import { db } from '../lib/firebase';
import { collection, getDocs, updateDoc, doc, query, where } from 'firebase/firestore';

export default function AdminVerificationsPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    const fetchUsers = async () => {
      setLoading(true);
      setError(null);
      try {
        const q = query(collection(db, 'users'), where('commercialRecordURL', '!=', null));
        const snap = await getDocs(q);
        const usersList = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        setUsers(usersList);
      } catch (err: any) {
        setError('حدث خطأ أثناء جلب المستخدمين');
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const handleVerify = async (uid: string, accept: boolean) => {
    setError(null);
    setSuccess(null);
    try {
      const userRef = doc(db, 'users', uid);
      await updateDoc(userRef, {
        isVerifiedBusiness: accept,
        commercialVerificationMsg: accept ? 'تم قبول التحقق التجاري.' : 'تم رفض التحقق التجاري. يرجى إعادة رفع السجل التجاري الصحيح.'
      });
      setUsers(users => users.map(u => u.id === uid ? { ...u, isVerifiedBusiness: accept, commercialVerificationMsg: accept ? 'تم قبول التحقق التجاري.' : 'تم رفض التحقق التجاري. يرجى إعادة رفع السجل التجاري الصحيح.' } : u));
      setSuccess('تم تحديث حالة المستخدم بنجاح.');
    } catch (err) {
      setError('حدث خطأ أثناء تحديث حالة المستخدم.');
    }
  };

  return (
    <main className="max-w-3xl mx-auto mt-8 p-4 bg-white rounded shadow">
      <h1 className="text-2xl font-bold mb-6">مراجعة السجلات التجارية</h1>
      {loading ? <div>جاري التحميل...</div> :
        users.length === 0 ? <div>لا يوجد سجلات بحاجة للمراجعة.</div> :
        <table className="w-full border border-gray-200 text-right">
          <thead>
            <tr className="bg-gray-100">
              <th className="p-2">اسم المستخدم</th>
              <th className="p-2">البريد الإلكتروني</th>
              <th className="p-2">ملف السجل التجاري</th>
              <th className="p-2">الحالة</th>
              <th className="p-2">إجراءات</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.id} className={user.isVerifiedBusiness ? 'bg-green-50' : 'bg-yellow-50'}>
                <td className="p-2">{user.displayName || 'بدون اسم'}</td>
                <td className="p-2">{user.email}</td>
                <td className="p-2">
                  {user.commercialRecordURL ? <a href={user.commercialRecordURL} target="_blank" rel="noopener noreferrer" className="underline text-blue-700">عرض</a> : '—'}
                </td>
                <td className="p-2 font-bold">{user.isVerifiedBusiness ? <span className="text-green-700">موثوق ✅</span> : <span className="text-yellow-700">بانتظار المراجعة</span>}</td>
                <td className="p-2 flex gap-2">
                  {!user.isVerifiedBusiness && <>
                    <button onClick={() => handleVerify(user.id, true)} className="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded">قبول</button>
                    <button onClick={() => handleVerify(user.id, false)} className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded">رفض</button>
                  </>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      }
      {error && <div className="text-red-600 my-2">{error}</div>}
      {success && <div className="text-green-600 my-2">{success}</div>}
    </main>
  );
}
