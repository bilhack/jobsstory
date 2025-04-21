import { useEffect, useState } from 'react';
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';

interface SectionField {
  label: string;
  type: string;
}

interface ProfileSection {
  id: string;
  title: string;
  fields: SectionField[];
}

export default function AdminSections() {
  const [sections, setSections] = useState<ProfileSection[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newSection, setNewSection] = useState<{ title: string; fields: SectionField[] }>({ title: '', fields: [] });
  const [fieldInput, setFieldInput] = useState<{ label: string; type: string }>({ label: '', type: 'text' });
  const [notif, setNotif] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showNotif = (type: 'success' | 'error', message: string) => {
    setNotif({ type, message });
    setTimeout(() => setNotif(null), 2500);
  };

  useEffect(() => {
    const fetchSections = async () => {
      try {
        const snapshot = await getDocs(collection(db, 'profileSections'));
        const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })) as ProfileSection[];
        setSections(list);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };
    fetchSections();
  }, []);

  const handleAddField = () => {
    if (!fieldInput.label) return;
    setNewSection(prev => ({ ...prev, fields: [...prev.fields, { ...fieldInput }] }));
    setFieldInput({ label: '', type: 'text' });
  };

  const handleRemoveField = (idx: number) => {
    setNewSection(prev => ({ ...prev, fields: prev.fields.filter((_, i) => i !== idx) }));
  };

  const handleAddSection = async () => {
    if (!newSection.title || newSection.fields.length === 0) return;
    try {
      const docRef = await addDoc(collection(db, 'profileSections'), newSection);
      setSections(sections => [...sections, { ...newSection, id: docRef.id }]);
      setNewSection({ title: '', fields: [] });
      showNotif('success', 'تم إضافة السكشن بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء إضافة السكشن');
    }
  };

  const handleDeleteSection = async (id: string) => {
    try {
      await deleteDoc(doc(db, 'profileSections', id));
      setSections(sections => sections.filter(s => s.id !== id));
      showNotif('success', 'تم حذف السكشن بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء حذف السكشن');
    }
  };

  // للتعديل البسيط (العنوان فقط)
  const handleSectionTitleEdit = async (id: string, newTitle: string) => {
    try {
      await updateDoc(doc(db, 'profileSections', id), { title: newTitle });
      setSections(sections => sections.map(s => (s.id === id ? { ...s, title: newTitle } : s)));
      showNotif('success', 'تم تعديل عنوان السكشن بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء تعديل عنوان السكشن');
    }
  };

  // تعديل الحقول داخل السكشن
  const handleFieldLabelEdit = async (sectionId: string, idx: number, newLabel: string) => {
    try {
      const section = sections.find(s => s.id === sectionId);
      if (!section) return;
      const updatedFields = section.fields.map((f, i) => i === idx ? { ...f, label: newLabel } : f);
      await updateDoc(doc(db, 'profileSections', sectionId), { fields: updatedFields });
      setSections(sections => sections.map(s => s.id === sectionId ? { ...s, fields: updatedFields } : s));
      showNotif('success', 'تم تعديل اسم الحقل بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء تعديل اسم الحقل');
    }
  };
  const handleFieldTypeEdit = async (sectionId: string, idx: number, newType: string) => {
    try {
      const section = sections.find(s => s.id === sectionId);
      if (!section) return;
      const updatedFields = section.fields.map((f, i) => i === idx ? { ...f, type: newType } : f);
      await updateDoc(doc(db, 'profileSections', sectionId), { fields: updatedFields });
      setSections(sections => sections.map(s => s.id === sectionId ? { ...s, fields: updatedFields } : s));
      showNotif('success', 'تم تعديل نوع الحقل بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء تعديل نوع الحقل');
    }
  };
  const handleRemoveFieldFromSection = async (sectionId: string, idx: number) => {
    try {
      const section = sections.find(s => s.id === sectionId);
      if (!section) return;
      const updatedFields = section.fields.filter((_, i) => i !== idx);
      await updateDoc(doc(db, 'profileSections', sectionId), { fields: updatedFields });
      setSections(sections => sections.map(s => s.id === sectionId ? { ...s, fields: updatedFields } : s));
      showNotif('success', 'تم حذف الحقل بنجاح');
    } catch {
      showNotif('error', 'حدث خطأ أثناء حذف الحقل');
    }
  };

  return (
    <div className="min-h-screen bg-[#f3f6fb]">
      <HeaderLinkedinWeb />
      <div className="max-w-4xl mx-auto mt-16 bg-white rounded-xl shadow p-8">
        {notif && (
          <div className={`mb-4 px-4 py-2 rounded text-white font-bold ${notif.type === 'success' ? 'bg-green-600' : 'bg-red-600'}`}>
            {notif.message}
          </div>
        )}
        <h1 className="text-2xl font-bold mb-6 text-[#1666b1]">إدارة السكاشن الديناميكية للبروفايل</h1>
        <div className="flex gap-4 mb-8">
          <a href="/admin" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">المستخدمون</a>
          <a href="/admin-videos" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">الفيديوهات</a>
          <a href="/admin-sections" className="px-4 py-2 rounded font-bold text-white bg-[#1666b1] hover:bg-[#12518e]">السكاشن</a>
        </div>
        {loading ? (
          <div>جاري التحميل...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <>
            <div className="mb-8">
              <h2 className="text-lg font-bold mb-2">إضافة سكشن جديد</h2>
              <input
                type="text"
                className="border rounded px-3 py-2 mb-2 w-full"
                placeholder="اسم السكشن (مثال: الجوائز)"
                value={newSection.title}
                onChange={e => setNewSection(prev => ({ ...prev, title: e.target.value }))}
              />
              <div className="flex gap-2 mb-2">
                <input
                  type="text"
                  className="border rounded px-3 py-2 flex-1"
                  placeholder="اسم الحقل (مثال: اسم الجائزة)"
                  value={fieldInput.label}
                  onChange={e => setFieldInput(prev => ({ ...prev, label: e.target.value }))}
                />
                <select
                  className="border rounded px-2 py-2"
                  value={fieldInput.type}
                  onChange={e => setFieldInput(prev => ({ ...prev, type: e.target.value }))}
                >
                  <option value="text">نص</option>
                  <option value="date">تاريخ</option>
                  <option value="number">رقم</option>
                </select>
                <button
                  className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold"
                  onClick={handleAddField}
                >إضافة حقل</button>
              </div>
              <ul className="mb-2">
                {newSection.fields.map((f, idx) => (
                  <li key={idx} className="flex items-center gap-2">
                    <span>{f.label} ({f.type})</span>
                    <button className="text-red-600 underline" onClick={() => handleRemoveField(idx)}>حذف</button>
                  </li>
                ))}
              </ul>
              <button
                className="bg-green-600 hover:bg-green-800 text-white px-5 py-2 rounded font-bold"
                onClick={handleAddSection}
              >حفظ السكشن</button>
            </div>
            <hr className="my-6" />
            <h2 className="text-xl font-bold mb-4">جميع السكاشن</h2>
            <ul>
              {sections.map(section => (
                <li key={section.id} className="mb-4 p-4 border rounded-xl bg-[#f8fafc]">
                  <div className="flex items-center gap-2 mb-2">
                    <input
                      type="text"
                      className="border rounded px-2 py-1 font-bold text-[#1666b1] w-1/2"
                      value={section.title}
                      onChange={e => handleSectionTitleEdit(section.id, e.target.value)}
                    />
                    <button className="bg-red-500 hover:bg-red-700 text-white px-3 py-1 rounded" onClick={() => handleDeleteSection(section.id)}>حذف</button>
                  </div>
                  <ul className="list-disc pr-6">
                    {section.fields.map((f, idx) => (
                      <li key={idx} className="flex items-center gap-2 mb-1">
                        <input
                          type="text"
                          className="border rounded px-2 py-1 text-sm"
                          value={f.label}
                          onChange={e => handleFieldLabelEdit(section.id, idx, e.target.value)}
                        />
                        <select
                          className="border rounded px-2 py-1 text-sm"
                          value={f.type}
                          onChange={e => handleFieldTypeEdit(section.id, idx, e.target.value)}
                        >
                          <option value="text">نص</option>
                          <option value="date">تاريخ</option>
                          <option value="number">رقم</option>
                        </select>
                        <button className="text-red-600 underline" onClick={() => handleRemoveFieldFromSection(section.id, idx)}>حذف</button>
                      </li>
                    ))}
                  </ul>
                </li>
              ))}
            </ul>
          </>
        )}
      </div>
    </div>
  );
}
