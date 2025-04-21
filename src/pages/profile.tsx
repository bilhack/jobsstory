import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { auth } from '../lib/firebase';
import { getUserProfile } from '../lib/firestoreUser';
import { onAuthStateChanged, signOut, updateProfile } from 'firebase/auth';
import { addExperience, removeExperience, updateExperience } from '../lib/experienceProfile';
import { addEducation, removeEducation, updateEducation } from '../lib/educationProfile';
import { addSkill, removeSkill } from '../lib/skillsProfile';
import { addCertification, removeCertification, updateCertification } from '../lib/certificationProfile';
import { addLanguage, removeLanguage } from '../lib/languagesProfile';
import { addProject, removeProject, updateProject } from '../lib/projectsProfile';
import { updateContact } from '../lib/contactProfile';
import { uploadCommercialRecord } from '../lib/uploadCommercialRecord';
import type { Experience, Education, Certification, Project } from '../lib/firestoreUser';
import { Dialog } from '@headlessui/react';
import { Fragment } from 'react';
import { getProfileSections, ProfileSection } from '../lib/profileSections';
import { doc, getDoc, updateDoc, arrayUnion, arrayRemove } from 'firebase/firestore';
import { db } from '../lib/firebase';
import dynamic from 'next/dynamic';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';
import ProfileSectionModal, { ModalField } from '../components/ProfileSectionModal';
import { profileModalsConfig } from '../components/profileModalsConfig';
import Link from 'next/link';

const ProfileLinkedinWeb = dynamic(() => import('../components/ProfileLinkedinWeb'), { ssr: false });

export default function ProfilePage() {
  const [user, setUser] = useState<any>(null);
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [editMode, setEditMode] = useState(false);
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState<'jobseeker' | 'recruiter' | 'admin' | undefined>(undefined);
  const [video, setVideo] = useState<File | null>(null);
  const [videoURL, setVideoURL] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [expList, setExpList] = useState<Experience[]>([]);
  const [expEdit, setExpEdit] = useState<Experience | null>(null);
  const [expForm, setExpForm] = useState<Omit<Experience, 'id'>>({
    title: '', company: '', location: '', startDate: '', endDate: '', description: ''
  });
  const [expLoading, setExpLoading] = useState(false);
  const [about, setAbout] = useState('');
  const [aboutEdit, setAboutEdit] = useState(false);
  const [aboutSaving, setAboutSaving] = useState(false);
  const [eduList, setEduList] = useState<Education[]>([]);
  const [eduEdit, setEduEdit] = useState<Education | null>(null);
  const [eduForm, setEduForm] = useState<Omit<Education, 'id'>>({
    school: '', degree: '', field: '', startDate: '', endDate: '', description: ''
  });
  const [eduLoading, setEduLoading] = useState(false);
  const [skills, setSkills] = useState<string[]>([]);
  const [skillInput, setSkillInput] = useState('');
  const [skillLoading, setSkillLoading] = useState(false);
  const [certList, setCertList] = useState<Certification[]>([]);
  const [certEdit, setCertEdit] = useState<Certification | null>(null);
  const [certForm, setCertForm] = useState<Omit<Certification, 'id'>>({ name: '', authority: '', date: '' });
  const [certLoading, setCertLoading] = useState(false);
  const [languages, setLanguages] = useState<string[]>([]);
  const [langInput, setLangInput] = useState('');
  const [langLoading, setLangLoading] = useState(false);
  const [projects, setProjects] = useState<Project[]>([]);
  const [projectEdit, setProjectEdit] = useState<Project | null>(null);
  const [projectForm, setProjectForm] = useState<Omit<Project, 'id'>>({ name: '', description: '', url: '' });
  const [projectLoading, setProjectLoading] = useState(false);
  const [contact, setContact] = useState<{ phone?: string; linkedin?: string; website?: string }>({});
  const [contactEdit, setContactEdit] = useState(false);
  const [contactLoading, setContactLoading] = useState(false);
  const [commercialRecord, setCommercialRecord] = useState<File | null>(null);
  const [commercialRecordURL, setCommercialRecordURL] = useState<string | undefined>(undefined);
  const [isVerifiedBusiness, setIsVerifiedBusiness] = useState<boolean>(false);
  const [commercialLoading, setCommercialLoading] = useState(false);
  const [commercialMsg, setCommercialMsg] = useState<string | null>(null);
  const router = useRouter();

  const [showSectionModal, setShowSectionModal] = useState(false);
  const [showEduModal, setShowEduModal] = useState(false);

  // --- State for Modal ---
  const [modalSection, setModalSection] = useState<string | null>(null);
  const [modalValues, setModalValues] = useState<Record<string, any>>({});
  const [modalLoading, setModalLoading] = useState(false);
  const [modalError, setModalError] = useState<string | null>(null);

  // --- Modal Open/Close Handlers ---
  const openModal = (section: string, values: Record<string, any> = {}) => {
    setModalSection(section);
    setModalValues(values);
    setModalError(null);
  };
  const closeModal = () => {
    setModalSection(null);
    setModalValues({});
    setModalError(null);
  };

  // --- Modal Change Handler ---
  const handleModalChange = (name: string, value: any) => {
    setModalValues(prev => ({ ...prev, [name]: value }));
  };

  // --- Modal Save Handler (حفظ بيانات المودال ديناميكياً) ---
  const handleModalSave = async () => {
    setModalLoading(true);
    setModalError(null);
    try {
      if (!modalSection) return;
      // uid المستخدم الحالي
      const uid = user?.uid;
      if (!uid) throw new Error('لم يتم العثور على المستخدم');
      // حفظ حسب نوع القسم
      if (modalSection === 'experience') {
        if (modalValues.id) {
          // تعديل
          await updateExperience(uid, modalValues);
        } else {
          // إضافة
          await addExperience(uid, modalValues);
        }
      } else if (modalSection === 'education') {
        if (modalValues.id) {
          await updateEducation(uid, modalValues);
        } else {
          await addEducation(uid, modalValues);
        }
      } else if (modalSection === 'skill') {
        if (typeof modalValues.skill === 'string' && modalValues.skill.trim()) {
          await addSkill(uid, modalValues.skill.trim());
        }
      } else if (modalSection === 'certification') {
        if (modalValues.id) {
          await updateCertification(uid, modalValues);
        } else {
          await addCertification(uid, modalValues);
        }
      } else if (modalSection === 'project') {
        if (modalValues.id) {
          await updateProject(uid, modalValues);
        } else {
          await addProject(uid, modalValues);
        }
      } else if (modalSection === 'language') {
        if (typeof modalValues.name === 'string' && modalValues.name.trim()) {
          await addLanguage(uid, modalValues.name.trim());
        }
      } else if (modalSection === 'contact') {
        await updateContact(uid, modalValues);
      }
      // بعد الحفظ، أعد تحميل بيانات البروفايل
      const updatedProfile = await getUserProfile(uid);
      setProfile(updatedProfile);
      setModalLoading(false);
      closeModal();
    } catch (err: any) {
      setModalError(err.message || 'حدث خطأ أثناء الحفظ');
      setModalLoading(false);
    }
  };

  // نموذج التعليم المؤقت
  const [eduModalForm, setEduModalForm] = useState({
    school: '',
    degree: '',
    field: '',
    startDate: '',
    endDate: '',
    grade: '',
    activities: '',
    description: '',
  });

  const handleOpenSectionModal = () => setShowSectionModal(true);
  const handleCloseSectionModal = () => setShowSectionModal(false);
  const handleOpenEduModal = () => {
    setShowSectionModal(false);
    setShowEduModal(true);
  };
  const handleCloseEduModal = () => setShowEduModal(false);

  const handleSaveEducation = (e: React.FormEvent) => {
    e.preventDefault();
    // يمكنك هنا ربط الحفظ مع Firestore
    setEduList([...eduList, { ...eduModalForm, id: Date.now().toString() }]);
    setShowEduModal(false);
    setEduModalForm({ school: '', degree: '', field: '', startDate: '', endDate: '', grade: '', activities: '', description: '' });
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (!firebaseUser) {
        router.push('/auth');
        return;
      }
      setUser(firebaseUser);
      const userProfile = await getUserProfile(firebaseUser.uid);
      setProfile(userProfile);
      setNewName(firebaseUser.displayName || userProfile?.displayName || '');
      setNewRole(userProfile?.role);
      setVideoURL(userProfile?.videoURL || null);
      setExpList(userProfile?.experience || []);
      setAbout(userProfile?.about || '');
      setEduList(userProfile?.education || []);
      setSkills(userProfile?.skills || []);
      setCertList(userProfile?.certifications || []);
      setLanguages(userProfile?.languages || []);
      setProjects(userProfile?.projects || []);
      setContact(userProfile?.contact || {});
      setIsVerifiedBusiness(userProfile?.isVerifiedBusiness || false);
      setCommercialRecordURL(userProfile?.commercialRecordURL);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [router]);

  const handleLogout = async () => {
    await signOut(auth);
    router.push('/auth');
  };

  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setSaving(true);
    try {
      await updateProfile(user, { displayName: newName });
      await (await import('../lib/updateUserProfile')).updateUserProfile(user.uid, {
        displayName: newName,
        role: newRole,
      });
      setEditMode(false);
      router.reload();
    } catch (err) {
      alert('حدث خطأ أثناء تحديث البيانات');
    } finally {
      setSaving(false);
    }
  };

  const handleVideoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setVideo(e.target.files[0]);
    }
  };

  const handleVideoUpload = async () => {
    if (!video || !user) return;
    setSaving(true);
    try {
      const { uploadVideo } = await import('../lib/uploadVideo');
      const url = await uploadVideo(video, user.uid);
      await (await import('../lib/updateUserProfile')).updateUserProfile(user.uid, {
        videoURL: url,
      });
      setVideoURL(url);
      setVideo(null);
      alert('تم رفع الفيديو بنجاح!');
    } catch (err) {
      alert('حدث خطأ أثناء رفع الفيديو');
    } finally {
      setSaving(false);
    }
  };

  // إضافة خبرة جديدة
  const handleExpAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setExpLoading(true);
    try {
      const newExp = await addExperience(user.uid, expForm);
      setExpList(prev => [...prev, newExp]);
      setExpForm({ title: '', company: '', location: '', startDate: '', endDate: '', description: '' });
    } finally {
      setExpLoading(false);
    }
  };

  // حذف خبرة
  const handleExpRemove = async (id: string) => {
    if (!user) return;
    setExpLoading(true);
    try {
      await removeExperience(user.uid, id);
      setExpList(prev => prev.filter(e => e.id !== id));
    } finally {
      setExpLoading(false);
    }
  };

  // تعديل خبرة
  const handleExpEdit = (exp: Experience) => {
    setExpEdit(exp);
    setExpForm({
      title: exp.title,
      company: exp.company,
      location: exp.location || '',
      startDate: exp.startDate,
      endDate: exp.endDate || '',
      description: exp.description || ''
    });
  };
  const handleExpUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !expEdit) return;
    setExpLoading(true);
    try {
      const updatedExp: Experience = { ...expEdit, ...expForm };
      await updateExperience(user.uid, updatedExp);
      setExpList(prev => prev.map(e => (e.id === updatedExp.id ? updatedExp : e)));
      setExpEdit(null);
      setExpForm({ title: '', company: '', location: '', startDate: '', endDate: '', description: '' });
    } finally {
      setExpLoading(false);
    }
  };
  const handleExpCancel = () => {
    setExpEdit(null);
    setExpForm({ title: '', company: '', location: '', startDate: '', endDate: '', description: '' });
  };

  // حفظ الملخص الشخصي
  const handleAboutSave = async () => {
    if (!user) return;
    setAboutSaving(true);
    try {
      await (await import('../lib/updateUserProfile')).updateUserProfile(user.uid, { about });
      setAboutEdit(false);
    } finally {
      setAboutSaving(false);
    }
  };

  // قسم التعليم
  const handleEduAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setEduLoading(true);
    try {
      const newEdu = await addEducation(user.uid, eduForm);
      setEduList(prev => [...prev, newEdu]);
      setEduForm({ school: '', degree: '', field: '', startDate: '', endDate: '', description: '' });
    } finally {
      setEduLoading(false);
    }
  };
  const handleEduRemove = async (id: string) => {
    if (!user) return;
    setEduLoading(true);
    try {
      await removeEducation(user.uid, id);
      setEduList(prev => prev.filter(e => e.id !== id));
    } finally {
      setEduLoading(false);
    }
  };
  const handleEduEdit = (edu: Education) => {
    setEduEdit(edu);
    setEduForm({
      school: edu.school,
      degree: edu.degree,
      field: edu.field,
      startDate: edu.startDate,
      endDate: edu.endDate || '',
      description: edu.description || ''
    });
  };
  const handleEduUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !eduEdit) return;
    setEduLoading(true);
    try {
      const updatedEdu: Education = { ...eduEdit, ...eduForm };
      await updateEducation(user.uid, updatedEdu);
      setEduList(prev => prev.map(e => (e.id === updatedEdu.id ? updatedEdu : e)));
      setEduEdit(null);
      setEduForm({ school: '', degree: '', field: '', startDate: '', endDate: '', description: '' });
    } finally {
      setEduLoading(false);
    }
  };
  const handleEduCancel = () => {
    setEduEdit(null);
    setEduForm({ school: '', degree: '', field: '', startDate: '', endDate: '', description: '' });
  };

  // المهارات
  const handleSkillAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !skillInput.trim()) return;
    setSkillLoading(true);
    try {
      await addSkill(user.uid, skillInput.trim());
      setSkills(prev => [...prev, skillInput.trim()]);
      setSkillInput('');
    } finally {
      setSkillLoading(false);
    }
  };
  const handleSkillRemove = async (skill: string) => {
    if (!user) return;
    setSkillLoading(true);
    try {
      await removeSkill(user.uid, skill);
      setSkills(prev => prev.filter(s => s !== skill));
    } finally {
      setSkillLoading(false);
    }
  };

  // الشهادات
  const handleCertAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setCertLoading(true);
    try {
      const newCert = await addCertification(user.uid, certForm);
      setCertList(prev => [...prev, newCert]);
      setCertForm({ name: '', authority: '', date: '' });
    } finally {
      setCertLoading(false);
    }
  };
  const handleCertRemove = async (id: string) => {
    if (!user) return;
    setCertLoading(true);
    try {
      await removeCertification(user.uid, id);
      setCertList(prev => prev.filter(c => c.id !== id));
    } finally {
      setCertLoading(false);
    }
  };
  const handleCertEdit = (cert: Certification) => {
    setCertEdit(cert);
    setCertForm({ name: cert.name, authority: cert.authority, date: cert.date });
  };
  const handleCertUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !certEdit) return;
    setCertLoading(true);
    try {
      const updatedCert: Certification = { ...certEdit, ...certForm };
      await updateCertification(user.uid, updatedCert);
      setCertList(prev => prev.map(c => (c.id === updatedCert.id ? updatedCert : c)));
      setCertEdit(null);
      setCertForm({ name: '', authority: '', date: '' });
    } finally {
      setCertLoading(false);
    }
  };
  const handleCertCancel = () => {
    setCertEdit(null);
    setCertForm({ name: '', authority: '', date: '' });
  };

  // اللغات
  const handleLangAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !langInput.trim()) return;
    setLangLoading(true);
    try {
      await addLanguage(user.uid, langInput.trim());
      setLanguages(prev => [...prev, langInput.trim()]);
      setLangInput('');
    } finally {
      setLangLoading(false);
    }
  };
  const handleLangRemove = async (lang: string) => {
    if (!user) return;
    setLangLoading(true);
    try {
      await removeLanguage(user.uid, lang);
      setLanguages(prev => prev.filter(l => l !== lang));
    } finally {
      setLangLoading(false);
    }
  };

  // المشاريع
  const handleProjectAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setProjectLoading(true);
    try {
      const newProject = await addProject(user.uid, projectForm);
      setProjects(prev => [...prev, newProject]);
      setProjectForm({ name: '', description: '', url: '' });
    } finally {
      setProjectLoading(false);
    }
  };
  const handleProjectRemove = async (id: string) => {
    if (!user) return;
    setProjectLoading(true);
    try {
      await removeProject(user.uid, id);
      setProjects(prev => prev.filter(p => p.id !== id));
    } finally {
      setProjectLoading(false);
    }
  };
  const handleProjectEdit = (project: Project) => {
    setProjectEdit(project);
    setProjectForm({ name: project.name, description: project.description || '', url: project.url || '' });
  };
  const handleProjectUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user || !projectEdit) return;
    setProjectLoading(true);
    try {
      const updatedProject: Project = { ...projectEdit, ...projectForm };
      await updateProject(user.uid, updatedProject);
      setProjects(prev => prev.map(p => (p.id === updatedProject.id ? updatedProject : p)));
      setProjectEdit(null);
      setProjectForm({ name: '', description: '', url: '' });
    } finally {
      setProjectLoading(false);
    }
  };
  const handleProjectCancel = () => {
    setProjectEdit(null);
    setProjectForm({ name: '', description: '', url: '' });
  };

  // التواصل
  const handleContactSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;
    setContactLoading(true);
    try {
      await updateContact(user.uid, contact);
      setContactEdit(false);
    } finally {
      setContactLoading(false);
    }
  };

  // رفع السجل التجاري
  const handleCommercialUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    setCommercialMsg(null);
    if (!user || !commercialRecord) return;
    setCommercialLoading(true);
    try {
      const url = await uploadCommercialRecord(commercialRecord, user.uid);
      await (await import('../lib/updateUserProfile')).updateUserProfile(user.uid, { commercialRecordURL: url, isVerifiedBusiness: false });
      setCommercialRecordURL(url);
      setIsVerifiedBusiness(false);
      setCommercialMsg('تم رفع السجل التجاري بنجاح. سيتم مراجعته من قبل الإدارة قريبًا.');
      setCommercialRecord(null);
    } catch (err) {
      setCommercialMsg('حدث خطأ أثناء رفع السجل التجاري. حاول مرة أخرى.');
    } finally {
      setCommercialLoading(false);
    }
  };

  // تعريف المتغيرات الخاصة بالسكاشن الديناميكية
  const [showDynamicModal, setShowDynamicModal] = useState<string | null>(null);
  const [dynamicForm, setDynamicForm] = useState<Record<string, any>>({});
  const [dynamicEditIndex, setDynamicEditIndex] = useState<{ sectionId: string; index: number | null }>({ sectionId: '', index: null });
  const [dynamicLoading, setDynamicLoading] = useState(false);
  const [dynamicError, setDynamicError] = useState<string | null>(null);
  const [dynamicSections, setDynamicSections] = useState<any[]>([]);
  const [dynamicItems, setDynamicItems] = useState<Record<string, any[]>>({});

  // تحميل السكاشن الديناميكية من الأدمن عند تحميل الصفحة
  useEffect(() => {
    (async () => {
      const sections = await getProfileSections();
      setDynamicSections(sections);
    })();
  }, []);

  // تحميل بيانات العناصر الديناميكية للمستخدم
  useEffect(() => {
    if (!user) return;
    (async () => {
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      const userData = userDoc.data() || {};
      const items: Record<string, any[]> = {};
      dynamicSections.forEach(section => {
        const key = section.title;
        items[key] = userData[key] || [];
      });
      setDynamicItems(items);
    })();
  }, [user, dynamicSections]);

  // فتح مودال إضافة/تعديل عنصر ديناميكي
  const handleOpenDynamicModal = (sectionId: string, item?: any, index?: number) => {
    setShowDynamicModal(sectionId);
    setDynamicEditIndex({ sectionId, index: index ?? null });
    const section = dynamicSections.find(s => s.id === sectionId);
    if (!section) return;
    const form: Record<string, any> = {};
    section.fields.forEach(field => {
      form[field.label] = item ? item[field.label] || '' : '';
    });
    setDynamicForm(form);
  };

  // غلق مودال الديناميكي
  const handleCloseDynamicModal = () => {
    setShowDynamicModal(null);
    setDynamicForm({});
    setDynamicEditIndex({ sectionId: '', index: null });
  };

  // حفظ عنصر جديد أو تحديث عنصر موجود
  const handleSaveDynamicItem = async (sectionId: string) => {
    if (!user) return;
    setDynamicLoading(true);
    setDynamicError(null);
    try {
      const section = dynamicSections.find(s => s.id === sectionId);
      if (!section) throw new Error('القسم غير موجود');
      const key = section.title;
      let items = [...(dynamicItems[key] || [])];
      if (dynamicEditIndex.index !== null) {
        // تعديل عنصر
        items[dynamicEditIndex.index] = { ...dynamicForm, id: items[dynamicEditIndex.index].id };
      } else {
        // إضافة عنصر جديد
        items.push({ ...dynamicForm, id: Date.now().toString() });
      }
      await updateDoc(doc(db, 'users', user.uid), { [key]: items });
      setDynamicItems(prev => ({ ...prev, [key]: items }));
      setDynamicLoading(false);
      handleCloseDynamicModal();
    } catch (err: any) {
      setDynamicError(err.message || 'حدث خطأ أثناء الحفظ');
      setDynamicLoading(false);
    }
  };

  // حذف عنصر ديناميكي
  const handleRemoveDynamicItem = async (sectionId: string, index: number) => {
    if (!user) return;
    const section = dynamicSections.find(s => s.id === sectionId);
    if (!section) return;
    const key = section.title;
    let items = [...(dynamicItems[key] || [])];
    items.splice(index, 1);
    await updateDoc(doc(db, 'users', user.uid), { [key]: items });
    setDynamicItems(prev => ({ ...prev, [key]: items }));
  };

  const [isDesktop, setIsDesktop] = useState(false);
  useEffect(() => {
    if (typeof window !== 'undefined') {
      setIsDesktop(window.innerWidth >= 1024);
      const handleResize = () => {
        setIsDesktop(window.innerWidth >= 1024);
      };
      window.addEventListener('resize', handleResize);
      return () => window.removeEventListener('resize', handleResize);
    }
  }, []);

  // حل مشكلة ReferenceError: handleExpAddModal is not defined
  // تعريف دوال الربط مع ProfileLinkedinWeb
  const handleExpAddModal = () => openModal('experience');
  const handleExpEditModal = (id: string) => {
    const exp = expList.find(e => e.id === id);
    if (exp) openModal('experience', exp);
  };
  const handleEduAddModal = () => openModal('education');
  const handleEduEditModal = (id: string) => {
    const edu = eduList.find(e => e.id === id);
    if (edu) openModal('education', edu);
  };
  const handleSkillAddModal = () => openModal('skill');
  const handleCertAddModal = () => openModal('certification');
  const handleCertEditModal = (id: string) => {
    const cert = certList.find(c => c.id === id);
    if (cert) openModal('certification', cert);
  };
  const handleProjectAddModal = () => openModal('project');
  const handleProjectEditModal = (id: string) => {
    const project = projects.find(p => p.id === id);
    if (project) openModal('project', project);
  };
  const handleLangAddModal = () => openModal('language');
  const handleLangEditModal = (id: string) => {
    const lang = languages.find(l => l.id === id);
    if (lang) openModal('language', lang);
  };

  // جلب الفيديوهات المفضلة لهذا المستخدم (إذا كان يعرض بروفايل غيره)
  const [favoriteVideos, setFavoriteVideos] = useState<any[]>([]);
  useEffect(() => {
    if (!profile?.savedVideos || !Array.isArray(profile.savedVideos) || profile.savedVideos.length === 0) {
      setFavoriteVideos([]);
      return;
    }
    const fetchFavs = async () => {
      const videosSnap = await getDocs(collection(db, 'videos'));
      const favs: any[] = [];
      videosSnap.forEach(docSnap => {
        if (profile.savedVideos.includes(docSnap.id)) {
          favs.push({ id: docSnap.id, ...docSnap.data() });
        }
      });
      setFavoriteVideos(favs);
    };
    fetchFavs();
  }, [profile]);

  if (loading) return <div className="flex items-center justify-center min-h-screen">جاري التحميل...</div>;

  if (isDesktop) {
    return (
      <>
        <HeaderLinkedinWeb />
        <div className="pt-[64px]">
          <ProfileLinkedinWeb
            user={profile}
            sections={dynamicSections}
            onAboutEdit={() => setAboutEdit(true)}
            onExperienceAdd={handleExpAddModal}
            onExperienceEdit={handleExpEditModal}
            onExperienceDelete={id => handleExpRemove(id)}
            onEducationAdd={handleEduAddModal}
            onEducationEdit={handleEduEditModal}
            onEducationDelete={id => handleEduRemove(id)}
            onSkillsAdd={handleSkillAddModal}
            onSkillsDelete={skill => handleSkillRemove(skill)}
            onCertAdd={handleCertAddModal}
            onCertEdit={handleCertEditModal}
            onCertDelete={id => handleCertRemove(id)}
            onProjectsAdd={handleProjectAddModal}
            onProjectsEdit={handleProjectEditModal}
            onProjectsDelete={id => handleProjectRemove(id)}
            onLanguagesAdd={handleLangAddModal}
            onLanguagesEdit={handleLangEditModal}
            onLanguagesDelete={id => handleLangRemove(id)}
            onContactEdit={() => openModal('contact', profile?.contact || {})}
          />
        </div>
      </>
    );
  }

  return (
    <main className="max-w-4xl mx-auto mt-16 bg-white rounded-xl shadow p-8">
      <div className="flex flex-col md:flex-row md:items-center gap-6 mb-8">
        <img src={profile?.photoURL || '/user.png'} alt="User" className="w-28 h-28 rounded-full border-4 border-[#1666b1] shadow" />
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-2">
            <h1 className="text-2xl font-bold text-[#1666b1]">{profile?.displayName || 'مستخدم'}</h1>
            <span className="bg-[#f3f6fb] text-[#1666b1] rounded px-3 py-1 text-xs font-bold">{profile?.role === 'recruiter' ? 'جهة توظيف' : profile?.role === 'admin' ? 'أدمن' : 'باحث عن عمل'}</span>
          </div>
          <div className="text-gray-600 mb-2">{profile?.email}</div>
          <div className="flex gap-2">
            {/* زر إرسال رسالة مباشرة */}
            <Link href={profile?.uid ? `/chat?user=${profile.uid}` : '/chat'} legacyBehavior>
              <a className="bg-[#1666b1] hover:bg-[#12518e] text-white px-6 py-2 rounded-full font-bold">إرسال رسالة</a>
            </Link>
            {/* زر حفظ المستخدم كمفضل (اختياري) */}
          </div>
        </div>
      </div>
      {/* فيديو المستخدم */}
      {profile?.videoUrl && (
        <div className="mb-8 flex justify-center">
          <video src={profile.videoUrl} controls className="rounded-xl shadow-lg max-w-[400px] w-full" poster={profile.thumbnailUrl} />
        </div>
      )}
      {/* قسم الفيديوهات المفضلة */}
      {favoriteVideos.length > 0 && (
        <div className="mb-8">
          <h2 className="text-xl font-bold text-[#1666b1] mb-4">فيديوهات مفضلة</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {favoriteVideos.map(video => (
              <div key={video.id} className="bg-[#f8fafc] rounded-lg shadow p-4 flex flex-col items-center">
                <video src={video.videoUrl} poster={video.thumbnailUrl} controls className="w-full max-w-[260px] h-[320px] object-cover rounded mb-2" />
                <div className="font-bold text-[#1666b1]">{video.title || 'فيديو'}</div>
              </div>
            ))}
          </div>
        </div>
      )}
      {/* قسم الخبرة العملية */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">الخبرة العملية</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('experience')}
          >
            + إضافة خبرة
          </button>
        </div>
        {isVerifiedBusiness && (
          <form onSubmit={expEdit ? handleExpUpdate : handleExpAdd} className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-4">
            <input type="text" placeholder="المسمى الوظيفي" value={expForm.title} onChange={e => setExpForm(f => ({ ...f, title: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
            <input type="text" placeholder="اسم الشركة" value={expForm.company} onChange={e => setExpForm(f => ({ ...f, company: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
            <input type="text" placeholder="الموقع (اختياري)" value={expForm.location} onChange={e => setExpForm(f => ({ ...f, location: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
            <input type="month" placeholder="تاريخ البدء" value={expForm.startDate} onChange={e => setExpForm(f => ({ ...f, startDate: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
            <input type="month" placeholder="تاريخ الانتهاء (اختياري)" value={expForm.endDate} onChange={e => setExpForm(f => ({ ...f, endDate: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
            <input type="text" placeholder="وصف مختصر (اختياري)" value={expForm.description} onChange={e => setExpForm(f => ({ ...f, description: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] col-span-1 md:col-span-2" />
            <div className="col-span-1 md:col-span-2 flex gap-2">
              <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={expLoading}>{expEdit ? 'تحديث' : 'إضافة'}</button>
              {expEdit && <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={handleExpCancel}>إلغاء</button>}
            </div>
          </form>
        )}
        <ul className="space-y-2">
          {expList.map((exp, idx) => (
            <li key={exp.id || idx} className="bg-gray-100 p-3 rounded flex flex-col md:flex-row md:items-center md:justify-between">
              <div>
                <div className="font-semibold">{exp.title} - {exp.company}</div>
                <div className="text-xs text-gray-600">{exp.startDate} - {exp.endDate || 'الآن'} | {exp.location}</div>
                {exp.description && <div className="text-sm mt-1">{exp.description}</div>}
              </div>
              <div className="flex gap-2 mt-2 md:mt-0">
                <button
                  className="text-[#f58220] hover:underline text-sm"
                  onClick={() => openModal('experience', exp)}
                >تعديل</button>
                <button className="text-red-600 underline" onClick={() => handleExpRemove(exp.id)}>حذف</button>
              </div>
            </li>
          ))}
        </ul>
      </div>
      <hr className="my-4" />
      {/* قسم التعليم */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">التعليم</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('education')}
          >
            + إضافة تعليم
          </button>
        </div>
        <form onSubmit={eduEdit ? handleEduUpdate : handleEduAdd} className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-4">
          <input type="text" placeholder="اسم المؤسسة التعليمية" value={eduForm.school} onChange={e => setEduForm(f => ({ ...f, school: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="text" placeholder="الدرجة العلمية" value={eduForm.degree} onChange={e => setEduForm(f => ({ ...f, degree: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="text" placeholder="التخصص" value={eduForm.field} onChange={e => setEduForm(f => ({ ...f, field: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="month" placeholder="تاريخ البدء" value={eduForm.startDate} onChange={e => setEduForm(f => ({ ...f, startDate: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="month" placeholder="تاريخ الانتهاء (اختياري)" value={eduForm.endDate} onChange={e => setEduForm(f => ({ ...f, endDate: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
          <input type="text" placeholder="وصف مختصر (اختياري)" value={eduForm.description} onChange={e => setEduForm(f => ({ ...f, description: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] col-span-1 md:col-span-2" />
          <div className="col-span-1 md:col-span-2 flex gap-2">
            <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={eduLoading}>{eduEdit ? 'تحديث' : 'إضافة'}</button>
            {eduEdit && <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={handleEduCancel}>إلغاء</button>}
          </div>
        </form>
        <ul className="space-y-2">
          {eduList.map((edu, idx) => (
            <li key={edu.id || idx} className="bg-gray-100 p-3 rounded flex flex-col md:flex-row md:items-center md:justify-between">
              <div>
                <div className="font-semibold">{edu.degree} - {edu.school}</div>
                <div className="text-xs text-gray-600">{edu.startDate} - {edu.endDate || 'الآن'} | {edu.field}</div>
                {edu.description && <div className="text-sm mt-1">{edu.description}</div>}
              </div>
              <div className="flex gap-2 mt-2 md:mt-0">
                <button
                  className="text-[#f58220] hover:underline text-sm"
                  onClick={() => openModal('education', edu)}
                >تعديل</button>
                <button className="text-red-600 underline" onClick={() => handleEduRemove(edu.id)}>حذف</button>
              </div>
            </li>
          ))}
        </ul>
      </div>
      <hr className="my-4" />
      {/* المهارات */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">المهارات</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('skill')}
          >
            + إضافة مهارة
          </button>
        </div>
        <form onSubmit={handleSkillAdd} className="flex gap-2 mb-2">
          <input type="text" placeholder="أضف مهارة..." value={skillInput} onChange={e => setSkillInput(e.target.value)} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] flex-1" />
          <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={skillLoading}>إضافة</button>
        </form>
        <div className="flex flex-wrap gap-2">
          {skills.map((skill, idx) => (
            <span key={skill.id || idx} className="bg-gray-200 px-3 py-1 rounded-full flex items-center gap-1">
              {skill}
              <button
                className="text-[#f58220] hover:underline text-sm"
                onClick={() => openModal('skill', skill)}
              >تعديل</button>
              <button className="text-red-600 underline" onClick={() => handleSkillRemove(skill)}>×</button>
            </span>
          ))}
        </div>
      </div>
      <hr className="my-4" />
      {/* الشهادات */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">الشهادات</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('certification')}
          >
            + إضافة شهادة
          </button>
        </div>
        <form onSubmit={certEdit ? handleCertUpdate : handleCertAdd} className="grid grid-cols-1 md:grid-cols-3 gap-2 mb-4">
          <input type="text" placeholder="اسم الشهادة" value={certForm.name} onChange={e => setCertForm(f => ({ ...f, name: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="text" placeholder="الجهة المانحة" value={certForm.authority} onChange={e => setCertForm(f => ({ ...f, authority: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="month" placeholder="تاريخ الحصول" value={certForm.date} onChange={e => setCertForm(f => ({ ...f, date: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <div className="col-span-1 md:col-span-3 flex gap-2">
            <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={certLoading}>{certEdit ? 'تحديث' : 'إضافة'}</button>
            {certEdit && <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={handleCertCancel}>إلغاء</button>}
          </div>
        </form>
        <ul className="space-y-2">
          {certList.map((cert, idx) => (
            <li key={cert.id || idx} className="bg-gray-100 p-3 rounded flex flex-col md:flex-row md:items-center md:justify-between">
              <div>
                <div className="font-semibold">{cert.name}</div>
                <div className="text-xs text-gray-600">{cert.authority} | {cert.date}</div>
              </div>
              <div className="flex gap-2 mt-2 md:mt-0">
                <button
                  className="text-[#f58220] hover:underline text-sm"
                  onClick={() => openModal('certification', cert)}
                >تعديل</button>
                <button className="text-red-600 underline" onClick={() => handleCertRemove(cert.id)}>حذف</button>
              </div>
            </li>
          ))}
        </ul>
      </div>
      <hr className="my-4" />
      {/* اللغات */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">اللغات</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('language')}
          >
            + إضافة لغة
          </button>
        </div>
        <form onSubmit={handleLangAdd} className="flex gap-2 mb-2">
          <input type="text" placeholder="أضف لغة..." value={langInput} onChange={e => setLangInput(e.target.value)} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] flex-1" />
          <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={langLoading}>إضافة</button>
        </form>
        <div className="flex flex-wrap gap-2">
          {languages.map((lang, idx) => (
            <span key={lang.id || idx} className="bg-gray-200 px-3 py-1 rounded-full flex items-center gap-1">
              {lang}
              <button
                className="text-[#f58220] hover:underline text-sm"
                onClick={() => openModal('language', lang)}
              >تعديل</button>
              <button className="text-red-600 underline" onClick={() => handleLangRemove(lang)}>×</button>
            </span>
          ))}
        </div>
      </div>
      <hr className="my-4" />
      {/* المشاريع */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">المشاريع</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('project')}
          >
            + إضافة مشروع
          </button>
        </div>
        <form onSubmit={projectEdit ? handleProjectUpdate : handleProjectAdd} className="grid grid-cols-1 md:grid-cols-3 gap-2 mb-4">
          <input type="text" placeholder="اسم المشروع" value={projectForm.name} onChange={e => setProjectForm(f => ({ ...f, name: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" required />
          <input type="text" placeholder="رابط المشروع (اختياري)" value={projectForm.url} onChange={e => setProjectForm(f => ({ ...f, url: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
          <input type="text" placeholder="وصف مختصر (اختياري)" value={projectForm.description} onChange={e => setProjectForm(f => ({ ...f, description: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] col-span-1 md:col-span-3" />
          <div className="col-span-1 md:col-span-3 flex gap-2">
            <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={projectLoading}>{projectEdit ? 'تحديث' : 'إضافة'}</button>
            {projectEdit && <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={handleProjectCancel}>إلغاء</button>}
          </div>
        </form>
        <ul className="space-y-2">
          {projects.map((project, idx) => (
            <li key={project.id || idx} className="bg-gray-100 p-3 rounded flex flex-col md:flex-row md:items-center md:justify-between">
              <div>
                <div className="font-semibold">{project.name}</div>
                <div className="text-xs text-gray-600">{project.url}</div>
                {project.description && <div className="text-sm mt-1">{project.description}</div>}
              </div>
              <div className="flex gap-2 mt-2 md:mt-0">
                <button
                  className="text-[#f58220] hover:underline text-sm"
                  onClick={() => openModal('project', project)}
                >تعديل</button>
                <button className="text-red-600 underline" onClick={() => handleProjectRemove(project.id)}>حذف</button>
              </div>
            </li>
          ))}
        </ul>
      </div>
      <hr className="my-4" />
      {/* بيانات التواصل */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h2 className="text-lg font-bold text-[#1666b1]">بيانات التواصل</h2>
          <button
            className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
            onClick={() => openModal('contact', profile?.contact || {})}
          >
            تعديل
          </button>
        </div>
        {contactEdit ? (
          <form onSubmit={handleContactSave} className="grid grid-cols-1 md:grid-cols-3 gap-2 mb-4">
            <input type="text" placeholder="رقم الهاتف" value={contact.phone || ''} onChange={e => setContact(c => ({ ...c, phone: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
            <input type="text" placeholder="رابط LinkedIn" value={contact.linkedin || ''} onChange={e => setContact(c => ({ ...c, linkedin: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
            <input type="text" placeholder="الموقع الإلكتروني" value={contact.website || ''} onChange={e => setContact(c => ({ ...c, website: e.target.value }))} className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]" />
            <div className="col-span-1 md:col-span-3 flex gap-2">
              <button type="submit" className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold" disabled={contactLoading}>{contactLoading ? 'جارٍ الحفظ...' : 'حفظ'}</button>
              <button type="button" className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold" onClick={() => setContactEdit(false)}>إلغاء</button>
            </div>
          </form>
        ) : (
          <div className="flex flex-col gap-2">
            <div>رقم الهاتف: {contact.phone || <span className="text-gray-400">غير محدد</span>}</div>
            <div>LinkedIn: {contact.linkedin ? <a href={contact.linkedin} className="underline text-[#1666b1]" target="_blank" rel="noopener noreferrer">{contact.linkedin}</a> : <span className="text-gray-400">غير محدد</span>}</div>
            <div>الموقع الإلكتروني: {contact.website ? <a href={contact.website} className="underline text-[#1666b1]" target="_blank" rel="noopener noreferrer">{contact.website}</a> : <span className="text-gray-400">غير محدد</span>}</div>
          </div>
        )}
      </div>
      <hr className="my-4" />
      {/* --- السكاشن الديناميكية من الأدمن --- */}
      {dynamicSections.length > 0 && (
        <div className="space-y-8 mt-8">
          {dynamicSections.map(section => {
            const items = dynamicItems[section.title] || [];
            return (
              <div key={section.id} className="bg-white rounded-xl shadow-md p-5">
                <div className="flex items-center justify-between mb-2">
                  <h2 className="font-bold text-lg text-[#1666b1]">{section.title}</h2>
                  <button
                    className="bg-[#1666b1] hover:bg-[#12518e] text-white px-3 py-1 rounded font-bold"
                    onClick={() => handleOpenDynamicModal(section.id)}
                  >
                    إضافة
                  </button>
                </div>
                {items.length === 0 ? (
                  <div className="text-gray-400">لا توجد بيانات بعد</div>
                ) : (
                  <ul className="space-y-2">
                    {items.map((item, idx) => (
                      <li key={item.id} className="bg-[#f5f6fa] rounded p-3 flex flex-col md:flex-row md:items-center md:justify-between">
                        <div>
                          {section.fields.map(field => (
                            <div key={field.label} className="text-sm"><span className="font-semibold text-[#1666b1]">{field.label}:</span> {item[field.label]}</div>
                          ))}
                        </div>
                        <div className="flex gap-2 mt-2 md:mt-0">
                          <button
                            className="text-[#f58220] hover:underline text-sm"
                            onClick={() => handleOpenDynamicModal(section.id, item, idx)}
                          >تعديل</button>
                          <button className="text-red-600 underline" onClick={() => handleRemoveDynamicItem(section.id, idx)}>حذف</button>
                        </div>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            );
          })}
        </div>
      )}
      <hr className="my-4" />
      {/* Profile Modals */}
      <ProfileSectionModal
        open={!!showDynamicModal}
        title={profileModalsConfig[showDynamicModal]?.title || ''}
        fields={profileModalsConfig[showDynamicModal]?.fields || []}
        values={dynamicForm}
        onChange={(name, value) => setDynamicForm(prev => ({ ...prev, [name]: value }))}
        onClose={handleCloseDynamicModal}
        onSave={() => handleSaveDynamicItem(showDynamicModal)}
        loading={dynamicLoading}
        error={dynamicError || ''}
      />
      <hr className="my-4" />
      <div className="flex flex-col gap-3">
        {/* يمكن إضافة المزيد من بيانات الملف الشخصي هنا */}
        <button onClick={handleLogout} className="bg-red-500 hover:bg-red-600 text-white py-2 rounded">تسجيل الخروج</button>
      </div>
    </main>
  );
}
