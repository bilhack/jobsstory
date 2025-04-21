import React from "react";

interface ProfileSectionAboutProps {
  about: string;
  onEdit: () => void;
}

const ProfileSectionAbout: React.FC<ProfileSectionAboutProps> = ({ about, onEdit }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M8 17l4 4 4-4m-4-5v9" /></svg>
          الملخص الشخصي
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onEdit}>تعديل</button>
      </div>
      <div className="text-gray-700 whitespace-pre-line min-h-[48px]">{about || "أضف ملخصًا عن نفسك..."}</div>
    </div>
  );
};

export default ProfileSectionAbout;
