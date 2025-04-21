import React from "react";

interface ProfileSectionSkillsProps {
  skills: string[];
  onAdd: () => void;
  onDelete: (skill: string) => void;
}

const ProfileSectionSkills: React.FC<ProfileSectionSkillsProps> = ({ skills, onAdd, onDelete }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6l4 2" /></svg>
          المهارات
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onAdd}>إضافة</button>
      </div>
      <div>
        {skills.length === 0 && (
          <div className="text-gray-500 text-sm">لم تتم إضافة مهارات بعد.</div>
        )}
        <ul className="flex flex-wrap gap-2 mt-2">
          {skills.map(skill => (
            <li key={skill} className="bg-[#f3f6fb] text-[#1666b1] px-3 py-1 rounded-full text-sm flex items-center gap-1">
              {skill}
              <button className="ml-1 text-red-500 hover:underline" onClick={() => onDelete(skill)} title="حذف المهارة">×</button>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default ProfileSectionSkills;
