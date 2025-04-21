import { useEffect, useState, Fragment } from 'react';
import { Dialog } from '@headlessui/react';
import { collection, getDocs, addDoc, updateDoc, deleteDoc, doc, orderBy, query } from 'firebase/firestore';
import { db } from '../../lib/firebase';

interface ProfileField {
  label: string;
  type: 'text' | 'number' | 'date' | 'select';
  options?: string[];
  required?: boolean;
  order: number;
}

interface ProfileSection {
  id: string;
  title: string;
  order: number;
  fields: ProfileField[];
}

export default function AdminProfileSections() {
  const [sections, setSections] = useState<ProfileSection[]>([]);
  const [loading, setLoading] = useState(true);
  const [showSectionModal, setShowSectionModal] = useState(false);
  const [editSection, setEditSection] = useState<ProfileSection | null>(null);
  const [sectionForm, setSectionForm] = useState<{ title: string; order: number }>({ title: '', order: 0 });
  const [showFieldModal, setShowFieldModal] = useState(false);
  const [editField, setEditField] = useState<{ sectionId: string; field: ProfileField | null }>({ sectionId: '', field: null });
  const [fieldForm, setFieldForm] = useState<ProfileField>({ label: '', type: 'text', order: 0, required: false });

  // جلب السكاشن من Firestore
  useEffect(() => {
    const fetchSections = async () => {
      setLoading(true);
      const q = query(collection(db, 'profile_sections'), orderBy('order'));
      const snapshot = await getDocs(q);
      const data = snapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })) as ProfileSection[];
      setSections(data);
      setLoading(false);
    };
    fetchSections();
  }, []);

  // إضافة أو تعديل سكشن
  const handleSaveSection = async (e: React.FormEvent) => {
    e.preventDefault();
    if (editSection) {
      await updateDoc(doc(db, 'profile_sections', editSection.id), { title: sectionForm.title, order: sectionForm.order });
    } else {
      await addDoc(collection(db, 'profile_sections'), { title: sectionForm.title, order: sectionForm.order, fields: [] });
    }
    setShowSectionModal(false);
    setSectionForm({ title: '', order: 0 });
    setEditSection(null);
    // إعادة التحديث
    const q = query(collection(db, 'profile_sections'), orderBy('order'));
    const snapshot = await getDocs(q);
    const data = snapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })) as ProfileSection[];
    setSections(data);
  };

  // حذف سكشن
  const handleDeleteSection = async (sectionId: string) => {
    await deleteDoc(doc(db, 'profile_sections', sectionId));
    setSections(sections.filter(s => s.id !== sectionId));
  };

  // إضافة أو تعديل حقل
  const handleSaveField = async (e: React.FormEvent) => {
    e.preventDefault();
    const section = sections.find(s => s.id === editField.sectionId);
    if (!section) return;
    let fields = [...section.fields];
    if (editField.field) {
      // تعديل
      fields = fields.map(f => f.label === editField.field?.label ? fieldForm : f);
    } else {
      // إضافة
      fields.push(fieldForm);
    }
    await updateDoc(doc(db, 'profile_sections', section.id), { fields });
    setShowFieldModal(false);
    setFieldForm({ label: '', type: 'text', order: 0, required: false });
    setEditField({ sectionId: '', field: null });
    // تحديث السكاشن
    const q = query(collection(db, 'profile_sections'), orderBy('order'));
    const snapshot = await getDocs(q);
    const data = snapshot.docs.map(docSnap => ({ id: docSnap.id, ...docSnap.data() })) as ProfileSection[];
    setSections(data);
  };

  // حذف حقل
  const handleDeleteField = async (sectionId: string, label: string) => {
    const section = sections.find(s => s.id === sectionId);
    if (!section) return;
    const fields = section.fields.filter(f => f.label !== label);
    await updateDoc(doc(db, 'profile_sections', sectionId), { fields });
    // تحديث السكاشن
    setSections(sections.map(s => s.id === sectionId ? { ...s, fields } : s));
  };

  return (
    <main className="max-w-3xl mx-auto bg-white shadow-md rounded-lg mt-10 p-6">
      <h1 className="text-2xl font-bold mb-6 text-[#1666b1]">إدارة أقسام البروفايل</h1>
      <button className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold mb-6" onClick={() => { setShowSectionModal(true); setEditSection(null); setSectionForm({ title: '', order: sections.length }); }}>إضافة سكشن جديد</button>
      {loading ? <div>جاري التحميل...</div> : (
        <div className="space-y-6">
          {sections.map(section => (
            <div key={section.id} className="bg-[#f5f6fa] rounded-lg p-4 shadow flex flex-col gap-2">
              <div className="flex items-center justify-between mb-2">
                <h2 className="text-lg font-bold text-[#1666b1]">{section.title}</h2>
                <div className="flex gap-2">
                  <button className="bg-[#f58220] hover:bg-orange-600 text-white px-3 py-1 rounded font-bold" onClick={() => { setEditSection(section); setSectionForm({ title: section.title, order: section.order }); setShowSectionModal(true); }}>تعديل</button>
                  <button className="bg-red-600 hover:bg-red-700 text-white px-3 py-1 rounded font-bold" onClick={() => handleDeleteSection(section.id)}>حذف</button>
                </div>
              </div>
              <div className="flex flex-col gap-1">
                {section.fields.length === 0 && <div className="text-gray-400">لا توجد حقول بعد</div>}
                {section.fields.map(field => (
                  <div key={field.label} className="flex items-center justify-between bg-white rounded p-2 shadow-sm">
                    <div className="flex flex-col">
                      <span className="font-semibold text-[#1666b1]">{field.label}</span>
                      <span className="text-xs text-gray-500">{field.type}{field.required && <span className="text-red-500 ml-2">*</span>}</span>
                    </div>
                    <div className="flex gap-2">
                      <button className="bg-[#1666b1] hover:bg-[#12518e] text-white px-2 py-1 rounded text-sm font-bold" onClick={() => { setEditField({ sectionId: section.id, field }); setFieldForm(field); setShowFieldModal(true); }}>تعديل</button>
                      <button className="bg-red-500 hover:bg-red-600 text-white px-2 py-1 rounded text-sm font-bold" onClick={() => handleDeleteField(section.id, field.label)}>حذف</button>
                    </div>
                  </div>
                ))}
              </div>
              <button className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold mt-2 w-fit" onClick={() => { setEditField({ sectionId: section.id, field: null }); setFieldForm({ label: '', type: 'text', order: section.fields.length, required: false }); setShowFieldModal(true); }}>إضافة حقل</button>
            </div>
          ))}
        </div>
      )}

      {/* Modal إضافة/تعديل سكشن */}
      <Dialog as={Fragment} open={showSectionModal} onClose={() => setShowSectionModal(false)}>
        <div className="fixed inset-0 bg-black bg-opacity-30 z-40 flex items-center justify-center">
          <Dialog.Panel className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <Dialog.Title className="text-xl font-bold mb-4 text-[#1666b1]">{editSection ? 'تعديل سكشن' : 'إضافة سكشن جديد'}</Dialog.Title>
            <form onSubmit={handleSaveSection} className="space-y-3">
              <input type="text" placeholder="اسم السكشن" value={sectionForm.title} onChange={e => setSectionForm(f => ({ ...f, title: e.target.value }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
              <input type="number" placeholder="الترتيب" value={sectionForm.order} onChange={e => setSectionForm(f => ({ ...f, order: Number(e.target.value) }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
              <div className="flex gap-2 mt-2">
                <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold">حفظ</button>
                <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={() => setShowSectionModal(false)}>إلغاء</button>
              </div>
            </form>
          </Dialog.Panel>
        </div>
      </Dialog>

      {/* Modal إضافة/تعديل حقل */}
      <Dialog as={Fragment} open={showFieldModal} onClose={() => setShowFieldModal(false)}>
        <div className="fixed inset-0 bg-black bg-opacity-30 z-50 flex items-center justify-center">
          <Dialog.Panel className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <Dialog.Title className="text-xl font-bold mb-4 text-[#1666b1]">{editField.field ? 'تعديل حقل' : 'إضافة حقل جديد'}</Dialog.Title>
            <form onSubmit={handleSaveField} className="space-y-3">
              <input type="text" placeholder="اسم الحقل" value={fieldForm.label} onChange={e => setFieldForm(f => ({ ...f, label: e.target.value }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
              <select value={fieldForm.type} onChange={e => setFieldForm(f => ({ ...f, type: e.target.value as ProfileField['type'] }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]">
                <option value="text">نص</option>
                <option value="number">رقم</option>
                <option value="date">تاريخ</option>
                <option value="select">قائمة منسدلة</option>
              </select>
              {fieldForm.type === 'select' && (
                <input type="text" placeholder="القيم (مفصولة بفاصلة)" value={fieldForm.options?.join(',') || ''} onChange={e => setFieldForm(f => ({ ...f, options: e.target.value.split(',').map(opt => opt.trim()) }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
              )}
              <div className="flex items-center gap-2">
                <input type="checkbox" checked={fieldForm.required} onChange={e => setFieldForm(f => ({ ...f, required: e.target.checked }))} />
                <label>مطلوب</label>
              </div>
              <input type="number" placeholder="ترتيب الحقل" value={fieldForm.order} onChange={e => setFieldForm(f => ({ ...f, order: Number(e.target.value) }))} className="w-full border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
              <div className="flex gap-2 mt-2">
                <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold">حفظ</button>
                <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={() => setShowFieldModal(false)}>إلغاء</button>
              </div>
            </form>
          </Dialog.Panel>
        </div>
      </Dialog>
    </main>
  );
}
