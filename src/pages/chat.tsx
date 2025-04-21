import { useEffect, useState, useRef } from 'react';
import { getAuth, onAuthStateChanged, User as FirebaseUser } from 'firebase/auth';
import { db } from '../lib/firebase';
import { doc, getDoc, setDoc, collection, addDoc, onSnapshot, query, orderBy, serverTimestamp, where, getDocs } from 'firebase/firestore';
import HeaderLinkedinWeb from '../components/HeaderLinkedinWeb';
import ChatAttachment from '../components/ChatAttachment';
import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';

interface Message {
  id: string;
  senderId: string;
  receiverId: string;
  text: string;
  createdAt: any;
  attachmentUrl?: string;
  attachmentName?: string;
}

export default function ChatPage() {
  const [currentUser, setCurrentUser] = useState<FirebaseUser | null>(null);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [users, setUsers] = useState<any[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [attachmentUploading, setAttachmentUploading] = useState(false);
  const [conversations, setConversations] = useState<any[]>([]);
  const [userProfiles, setUserProfiles] = useState<Record<string, any>>({});
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const auth = getAuth();
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (!currentUser) return;
    // جلب جميع المستخدمين ما عدا المستخدم الحالي
    const fetchUsers = async () => {
      const usersSnap = await getDocs(collection(db, 'users'));
      const usersDocs = await usersSnap;
      const usersList = usersDocs.docs.filter(doc => doc.id !== currentUser.uid).map(doc => ({ uid: doc.id, ...doc.data() }));
      setUsers(usersList);
    };
    fetchUsers();
  }, [currentUser]);

  useEffect(() => {
    if (!currentUser) return;
    // جلب جميع الرسائل التي تخص المستخدم الحالي
    const q = query(
      collection(db, 'messages'),
      where('participants', 'array-contains', currentUser.uid),
      orderBy('createdAt', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      // جمع آخر رسالة مع كل مستخدم
      const convMap: Record<string, any> = {};
      snapshot.docs.forEach(docSnap => {
        const msg = docSnap.data();
        const otherId = msg.senderId === currentUser.uid ? msg.receiverId : msg.senderId;
        if (!convMap[otherId]) convMap[otherId] = { ...msg, id: docSnap.id };
      });
      setConversations(Object.values(convMap));
    });
    return () => unsubscribe();
  }, [currentUser]);

  useEffect(() => {
    if (!currentUser || !selectedUser) return;
    setLoading(true);
    // ترتيب الرسائل حسب الوقت
    const q = query(
      collection(db, 'messages'),
      where('participants', 'array-contains', currentUser.uid),
      orderBy('createdAt', 'asc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgs: Message[] = snapshot.docs
        .map(doc => ({ id: doc.id, ...doc.data() } as Message))
        .filter(msg =>
          (msg.senderId === currentUser.uid && msg.receiverId === selectedUser.uid) ||
          (msg.senderId === selectedUser.uid && msg.receiverId === currentUser.uid)
        );
      setMessages(msgs);
      setLoading(false);
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    });
    return () => unsubscribe();
  }, [currentUser, selectedUser]);

  useEffect(() => {
    const fetchUsers = async () => {
      const usersSnap = await getDocs(collection(db, 'users'));
      const map: Record<string, any> = {};
      usersSnap.forEach(doc => {
        map[doc.id] = doc.data();
      });
      setUserProfiles(map);
    };
    fetchUsers();
  }, []);

  const sendMessage = async (e: any) => {
    e.preventDefault();
    if (!currentUser || !selectedUser || !message.trim()) return;
    await addDoc(collection(db, 'messages'), {
      senderId: currentUser.uid,
      receiverId: selectedUser.uid,
      text: message,
      createdAt: serverTimestamp(),
      participants: [currentUser.uid, selectedUser.uid],
    });
    setMessage('');
  };

  const handleAttachmentUpload = async (file: File) => {
    if (!currentUser || !selectedUser) return;
    setAttachmentUploading(true);
    try {
      const storage = getStorage();
      const storageRef = ref(storage, `chat_attachments/${currentUser.uid}_${Date.now()}_${file.name}`);
      await uploadBytes(storageRef, file);
      const url = await getDownloadURL(storageRef);
      await addDoc(collection(db, 'messages'), {
        senderId: currentUser.uid,
        receiverId: selectedUser.uid,
        text: '',
        attachmentUrl: url,
        attachmentName: file.name,
        createdAt: serverTimestamp(),
        participants: [currentUser.uid, selectedUser.uid],
      });
    } catch {
      alert('حدث خطأ أثناء رفع الملف');
    } finally {
      setAttachmentUploading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#f3f6fb]">
      <HeaderLinkedinWeb />
      <div className="max-w-4xl mx-auto mt-20 bg-white rounded-xl shadow flex overflow-hidden" style={{ minHeight: 500 }}>
        {/* قائمة المحادثات الجانبية */}
        <div className="w-1/3 border-r bg-[#f8fafc] p-4 overflow-y-auto">
          <h2 className="text-lg font-bold mb-4 text-[#1666b1]">المحادثات</h2>
          {conversations.length === 0 ? (
            <div className="text-gray-500">لا توجد محادثات بعد.</div>
          ) : (
            <ul>
              {conversations.map(conv => {
                const otherId = conv.senderId === currentUser?.uid ? conv.receiverId : conv.senderId;
                const user = userProfiles[otherId] || {};
                return (
                  <li
                    key={otherId}
                    className={`flex items-center gap-2 p-2 rounded cursor-pointer hover:bg-[#e6f0fa] ${selectedUser?.uid === otherId ? 'bg-[#d0e7fa]' : ''}`}
                    onClick={() => setSelectedUser({ uid: otherId, ...user })}
                  >
                    <img src={user.photoURL || '/user.png'} alt="User" className="w-8 h-8 rounded-full border" />
                    <div className="flex-1">
                      <div className="font-bold text-[#1666b1]">{user.displayName || 'مستخدم'}</div>
                      <div className="text-xs text-gray-600 truncate max-w-[120px]">{conv.text || (conv.attachmentName ? `📎 ${conv.attachmentName}` : '')}</div>
                    </div>
                    <div className="text-xs text-gray-400 min-w-[60px] text-end">
                      {conv.createdAt?.toDate ? conv.createdAt.toDate().toLocaleDateString('ar-EG', { hour: '2-digit', minute: '2-digit' }) : ''}
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
        {/* نافذة الدردشة */}
        <div className="flex-1 flex flex-col">
          {selectedUser ? (
            <>
              <div className="flex items-center gap-2 border-b p-4 bg-[#f8fafc]">
                <img src={selectedUser.photoURL || '/user.png'} alt="User" className="w-8 h-8 rounded-full border" />
                <span className="font-bold text-[#1666b1]">{selectedUser.displayName || 'مستخدم'}</span>
              </div>
              <div className="flex-1 p-4 overflow-y-auto" style={{ minHeight: 300, maxHeight: 400 }}>
                {loading ? (
                  <div>جاري تحميل الرسائل...</div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {messages.map(msg => (
                      <div
                        key={msg.id}
                        className={`max-w-[70%] px-3 py-2 rounded-lg text-sm ${msg.senderId === currentUser?.uid ? 'bg-[#1666b1] text-white self-end' : 'bg-gray-200 text-gray-900 self-start'}`}
                      >
                        {msg.text && <span>{msg.text}</span>}
                        {msg.attachmentUrl && (
                          <a
                            href={msg.attachmentUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="block mt-1 underline text-blue-600"
                          >
                            📎 {msg.attachmentName || 'ملف مرفق'}
                          </a>
                        )}
                      </div>
                    ))}
                    <div ref={messagesEndRef} />
                  </div>
                )}
              </div>
              <form onSubmit={sendMessage} className="flex gap-2 p-4 border-t bg-[#f8fafc] items-center">
                <ChatAttachment onUpload={handleAttachmentUpload} />
                <input
                  type="text"
                  className="flex-1 border rounded-full px-4 py-2 focus:outline-none"
                  placeholder="اكتب رسالتك..."
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  disabled={attachmentUploading}
                />
                <button type="submit" className="bg-[#1666b1] text-white px-6 py-2 rounded-full font-bold hover:bg-[#12518e]" disabled={attachmentUploading}>إرسال</button>
                {attachmentUploading && <span className="text-xs text-gray-500">جاري رفع الملف...</span>}
              </form>
            </>
          ) : (
            <div className="flex items-center justify-center flex-1 text-gray-500">اختر مستخدمًا لبدء المحادثة</div>
          )}
        </div>
      </div>
    </div>
  );
}
