import { useState } from 'react';
import { auth } from '../lib/firebase';
import { GoogleAuthProvider, FacebookAuthProvider, signInWithPopup } from 'firebase/auth';
import { createOrUpdateUserProfile } from '../lib/firestoreUser';
import Image from 'next/image';
import { useRouter } from 'next/router';

const googleProvider = new GoogleAuthProvider();
const facebookProvider = new FacebookAuthProvider();

export default function AuthPage() {
  const [mode, setMode] = useState<'login' | 'register'>('register');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [emailSent, setEmailSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleGoogleLogin = async () => {
    setError(null);
    try {
      const result = await signInWithPopup(auth, googleProvider);
      const user = result.user;
      await createOrUpdateUserProfile(user, 'jobseeker');
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleFacebookLogin = async () => {
    setError(null);
    try {
      const result = await signInWithPopup(auth, facebookProvider);
      const user = result.user;
      await createOrUpdateUserProfile(user, 'jobseeker');
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleLinkedInLogin = () => {
    setError('تسجيل الدخول عبر لينكدإن يتطلب إعدادًا مخصصًا. سيتم دعمه قريبًا.');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);
    console.log('START LOGIN');
    try {
      if (!email || !password) {
        setError('يرجى إدخال البريد وكلمة المرور');
        setLoading(false);
        return;
      }
      if (mode === 'register') {
        if (!name) {
          setError('يرجى إدخال الاسم الكامل');
          setLoading(false);
          return;
        }
        if (password !== confirmPassword) {
          setError('كلمتا المرور غير متطابقتين');
          setLoading(false);
          return;
        }
      }
      if (mode === 'register') {
        console.log('before createUserWithEmailAndPassword');
        const { createUserWithEmailAndPassword, updateProfile, sendEmailVerification } = await import('firebase/auth');
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        console.log('after createUserWithEmailAndPassword', userCredential);
        if (userCredential.user) {
          console.log('before updateProfile');
          await updateProfile(userCredential.user, { displayName: name });
          console.log('after updateProfile');
          await createOrUpdateUserProfile(userCredential.user, 'jobseeker');
          console.log('after createOrUpdateUserProfile');
          await sendEmailVerification(userCredential.user);
          console.log('after sendEmailVerification');
          setSuccess('تم التسجيل بنجاح! يرجى التحقق من بريدك الإلكتروني لتفعيل الحساب.');
          setEmailSent(true);
        }
      } else {
        console.log('before signInWithEmailAndPassword');
        const { signInWithEmailAndPassword } = await import('firebase/auth');
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        console.log('after signInWithEmailAndPassword', userCredential);
        if (userCredential.user) {
          if (!userCredential.user.emailVerified) {
            setError('يجب عليك تفعيل بريدك الإلكتروني أولاً. تحقق من صندوق الوارد أو أعد إرسال رابط التحقق.');
            setSuccess(null);
            setLoading(false);
            console.log('BLOCKED: email not verified');
            return;
          }
          console.log('before createOrUpdateUserProfile');
          await createOrUpdateUserProfile(userCredential.user, 'jobseeker');
          console.log('after createOrUpdateUserProfile');
          router.push('/profile');
          console.log('after router.push');
        }
      }
    } catch (err: any) {
      console.error('Auth error:', err);
      if (err.code === 'auth/user-not-found') {
        setError('البريد الإلكتروني غير مسجل.');
      } else if (err.code === 'auth/wrong-password') {
        setError('كلمة المرور غير صحيحة.');
      } else if (err.code === 'auth/too-many-requests') {
        setError('تم حظر المحاولة مؤقتًا بسبب محاولات خاطئة متكررة. حاول لاحقًا.');
      } else if (err.code === 'auth/invalid-email') {
        setError('البريد الإلكتروني غير صالح.');
      } else if (err.message) {
        setError(err.message);
      } else {
        setError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      }
    } finally {
      setLoading(false);
      console.log('END LOGIN');
    }
  };

  return (
    <main className="flex flex-col items-center justify-center min-h-screen bg-gray-50 px-4">
      <div className="w-full max-w-md bg-white rounded-lg shadow-md p-8">
        <div className="flex justify-center mb-6">
          <Image src="/jobsstory-logo.png" alt="JobsStory Logo" width={180} height={60} />
        </div>
        <h2 className="text-2xl font-bold mb-2 text-center">انضم إلى JobsStory</h2>
        <p className="text-gray-500 text-center mb-6">منصة التوظيف بالفيديوهات القصيرة</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          {loading && <div className="text-center text-blue-700">جاري المعالجة...</div>}
          {mode === 'register' && (
            <input type="text" placeholder="الاسم الكامل" value={name} onChange={e => setName(e.target.value)} className="w-full border rounded px-3 py-2" required />
          )}
          <input type="email" placeholder="البريد الإلكتروني" value={email} onChange={e => setEmail(e.target.value)} className="w-full border rounded px-3 py-2" required />
          <input type="password" placeholder="كلمة المرور" value={password} onChange={e => setPassword(e.target.value)} className="w-full border rounded px-3 py-2" required />
          {mode === 'register' && (
            <input type="password" placeholder="تأكيد كلمة المرور" value={confirmPassword} onChange={e => setConfirmPassword(e.target.value)} className="w-full border rounded px-3 py-2" required />
          )}
          <div className="flex gap-2 mt-2">
            <button type="submit" className="flex-1 bg-blue-700 text-white py-2 rounded">{mode === 'register' ? 'تسجيل' : 'دخول'}</button>
          </div>
          {error && <div className="text-red-600 text-center text-sm mt-2">{error}</div>}
          {success && <div className="text-green-600 text-center text-sm mt-2">{success}</div>}
          {((mode === 'register' && emailSent) || (mode === 'login' && error && error.includes('تفعيل بريدك الإلكتروني'))) && (
            <button type="button" className="block mx-auto mt-2 text-blue-700 underline text-sm" onClick={async () => {
              const { getAuth, sendEmailVerification } = await import('firebase/auth');
              const user = getAuth().currentUser;
              if (user) {
                await sendEmailVerification(user);
                setSuccess('تمت إعادة إرسال رابط التحقق إلى بريدك الإلكتروني.');
              }
            }}>
              لم يصلك الإيميل؟ أعد إرسال رابط التحقق
            </button>
          )}
        </form>
        <div className="flex items-center my-4">
          <div className="flex-1 h-px bg-gray-200" />
          <span className="mx-2 text-gray-400 text-sm">أو</span>
          <div className="flex-1 h-px bg-gray-200" />
        </div>
        <button onClick={handleGoogleLogin} className="w-full mb-2 bg-red-500 text-white py-2 rounded">الدخول عبر Google</button>
        <button onClick={handleFacebookLogin} className="w-full mb-2 bg-blue-700 text-white py-2 rounded">الدخول عبر Facebook</button>
        <button onClick={handleLinkedInLogin} className="w-full mb-4 bg-blue-900 text-white py-2 rounded">الدخول عبر LinkedIn</button>
        <div className="text-center text-sm text-gray-600 mb-2">
          {mode === 'register' ? 'لديك حساب؟' : 'ليس لديك حساب؟'}
          <button className="ml-1 underline" onClick={() => setMode(mode === 'register' ? 'login' : 'register')}>
            {mode === 'register' ? 'دخول' : 'تسجيل'}
          </button>
        </div>
        <div className="text-xs text-gray-400 text-center mb-2">بالتسجيل أنت توافق على <a href="#" className="underline">الشروط</a> و <a href="#" className="underline">سياسة الخصوصية</a>.</div>
      </div>
    </main>
  );
}
