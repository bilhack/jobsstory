import React from "react";

interface ProfileSectionContactProps {
  email: string;
  phone?: string;
  linkedin?: string;
  website?: string;
  onEdit: () => void;
}

const ProfileSectionContact: React.FC<ProfileSectionContactProps> = ({ email, phone, linkedin, website, onEdit }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M21 10.5a8.38 8.38 0 01-1.9.7c-.5.1-.7-.2-.7-.5v-1.2c0-.3.2-.6.5-.7A7.72 7.72 0 0021 7.5a7.72 7.72 0 00-2.1-2.3c-.3-.2-.5-.4-.5-.7v-1.2c0-.3.2-.6.7-.5.6.2 1.3.4 1.9.7A8.38 8.38 0 0121 10.5z" /></svg>
          بيانات التواصل
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onEdit}>تعديل</button>
      </div>
      <div className="space-y-1 text-gray-700">
        <div><span className="font-semibold">البريد الإلكتروني:</span> {email}</div>
        {phone && <div><span className="font-semibold">الجوال:</span> {phone}</div>}
        {linkedin && <div><span className="font-semibold">LinkedIn:</span> <a href={linkedin} className="text-[#1666b1] underline" target="_blank" rel="noopener noreferrer">{linkedin}</a></div>}
        {website && <div><span className="font-semibold">الموقع الشخصي:</span> <a href={website} className="text-[#1666b1] underline" target="_blank" rel="noopener noreferrer">{website}</a></div>}
      </div>
    </div>
  );
};

export default ProfileSectionContact;
