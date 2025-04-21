import { ModalField } from './ProfileSectionModal';

export const profileModalsConfig: Record<string, { title: string; fields: ModalField[] }> = {
  education: {
    title: 'إضافة تعليم',
    fields: [
      { label: 'اسم المؤسسة التعليمية', name: 'school', type: 'text', required: true },
      { label: 'الدرجة العلمية', name: 'degree', type: 'text', required: true },
      { label: 'التخصص', name: 'field', type: 'text', required: true },
      { label: 'تاريخ البدء', name: 'startDate', type: 'month', required: true },
      { label: 'تاريخ الانتهاء أو المتوقع', name: 'endDate', type: 'month' },
      { label: 'المعدل/الدرجة', name: 'grade', type: 'text' },
      { label: 'الأنشطة والجمعيات', name: 'activities', type: 'text' },
      { label: 'الوصف', name: 'description', type: 'textarea', maxLength: 1000 },
      { label: 'المهارات', name: 'skills', type: 'text', placeholder: 'افصل بين المهارات بفاصلة' },
      { label: 'ملفات أو صور', name: 'media', type: 'file', multiple: true },
    ],
  },
  experience: {
    title: 'إضافة خبرة',
    fields: [
      { label: 'المسمى الوظيفي', name: 'title', type: 'text', required: true },
      { label: 'اسم الشركة', name: 'company', type: 'text', required: true },
      { label: 'الموقع الجغرافي', name: 'location', type: 'text' },
      { label: 'تاريخ البدء', name: 'startDate', type: 'month', required: true },
      { label: 'تاريخ الانتهاء أو المتوقع', name: 'endDate', type: 'month' },
      { label: 'الوصف', name: 'description', type: 'textarea', maxLength: 1000 },
      { label: 'المهارات', name: 'skills', type: 'text', placeholder: 'افصل بين المهارات بفاصلة' },
      { label: 'ملفات أو صور', name: 'media', type: 'file', multiple: true },
    ],
  },
  certification: {
    title: 'إضافة شهادة',
    fields: [
      { label: 'اسم الشهادة', name: 'name', type: 'text', required: true },
      { label: 'الجهة المانحة', name: 'authority', type: 'text', required: true },
      { label: 'تاريخ الإصدار', name: 'date', type: 'date', required: true },
      { label: 'الوصف', name: 'description', type: 'textarea', maxLength: 500 },
      { label: 'ملفات أو صور', name: 'media', type: 'file', multiple: true },
    ],
  },
  project: {
    title: 'إضافة مشروع',
    fields: [
      { label: 'اسم المشروع', name: 'name', type: 'text', required: true },
      { label: 'الرابط', name: 'url', type: 'text', placeholder: 'https://...' },
      { label: 'الوصف', name: 'description', type: 'textarea', maxLength: 1000 },
      { label: 'المهارات', name: 'skills', type: 'text', placeholder: 'افصل بين المهارات بفاصلة' },
      { label: 'ملفات أو صور', name: 'media', type: 'file', multiple: true },
    ],
  },
  skill: {
    title: 'إضافة مهارة',
    fields: [
      { label: 'المهارة', name: 'skill', type: 'text', required: true },
    ],
  },
  language: {
    title: 'إضافة لغة',
    fields: [
      { label: 'اللغة', name: 'name', type: 'text', required: true },
      { label: 'المستوى', name: 'level', type: 'select', options: ['مبتدئ', 'متوسط', 'متقدم', 'محترف'], required: true },
      { label: 'شهادة لغة (اختياري)', name: 'certificate', type: 'text' },
      { label: 'ملفات أو صور', name: 'media', type: 'file', multiple: true },
    ],
  },
  contact: {
    title: 'تعديل بيانات التواصل',
    fields: [
      { label: 'البريد الإلكتروني', name: 'email', type: 'text', required: true },
      { label: 'رقم الجوال', name: 'phone', type: 'text' },
      { label: 'LinkedIn', name: 'linkedin', type: 'text', placeholder: 'https://linkedin.com/in/...' },
      { label: 'الموقع الشخصي', name: 'website', type: 'text', placeholder: 'https://...' },
    ],
  },
};
