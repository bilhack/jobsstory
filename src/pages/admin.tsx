import { useEffect, useState } from 'react';
import { getDocs, collection, updateDoc, doc, deleteDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';

interface UserAdmin {
  uid: string;
  displayName: string;
  email: string;
  role: string;
  isVerifiedBusiness?: boolean;
}

export default function AdminPanel() {
  const [users, setUsers] = useState<UserAdmin[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const snapshot = await getDocs(collection(db, 'users'));
        const usersList = snapshot.docs.map(doc => ({ uid: doc.id, ...doc.data() })) as UserAdmin[];
        setUsers(usersList);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const handleRoleChange = async (uid: string, newRole: string) => {
    await updateDoc(doc(db, 'users', uid), { role: newRole });
    setUsers(users => users.map(u => (u.uid === uid ? { ...u, role: newRole } : u)));
  };

  const handleDeleteUser = async (uid: string) => {
    await deleteDoc(doc(db, 'users', uid));
    setUsers(users => users.filter(u => u.uid !== uid));
  };

  return (
    <div className="min-h-screen bg-[#f3f6fb]">
      <HeaderLinkedinWeb />
      <div className="max-w-4xl mx-auto mt-16 bg-white rounded-xl shadow p-8">
        <h1 className="text-2xl font-bold mb-6 text-[#1666b1]">لوحة تحكم الأدمن</h1>
        <div className="flex gap-4 mb-8">
          <a href="/admin" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">المستخدمون</a>
          <a href="/admin-videos" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">الفيديوهات</a>
        </div>
        {loading ? (
          <div>جاري التحميل...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="w-full border text-right">
            <thead>
              <tr className="bg-[#f3f6fb]">
                <th className="p-2">الاسم</th>
                <th className="p-2">البريد الإلكتروني</th>
                <th className="p-2">الدور</th>
                <th className="p-2">شركة موثقة</th>
                <th className="p-2">إجراءات</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.uid} className="border-b">
                  <td className="p-2">{user.displayName}</td>
                  <td className="p-2">{user.email}</td>
                  <td className="p-2">
                    <select
                      className="border rounded px-2 py-1"
                      value={user.role}
                      onChange={e => handleRoleChange(user.uid, e.target.value)}
                    >
                      <option value="jobseeker">باحث عن عمل</option>
                      <option value="recruiter">صاحب عمل</option>
                      <option value="admin">أدمن</option>
                    </select>
                  </td>
                  <td className="p-2 text-center">{user.isVerifiedBusiness ? '✔️' : '-'}</td>
                  <td className="p-2">
                    <button
                      className="bg-red-500 hover:bg-red-700 text-white px-3 py-1 rounded"
                      onClick={() => handleDeleteUser(user.uid)}
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
