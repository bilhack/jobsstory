import React from "react";
import { Experience } from "../lib/experienceProfile";

interface ProfileSectionExperienceProps {
  experience: Experience[];
  onAdd: () => void;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

const ProfileSectionExperience: React.FC<ProfileSectionExperienceProps> = ({ experience, onAdd, onEdit, onDelete }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M16 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
          الخبرة العملية
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onAdd}>إضافة</button>
      </div>
      <div>
        {experience.length === 0 && (
          <div className="text-gray-500 text-sm">لم تتم إضافة خبرات بعد.</div>
        )}
        <ul className="space-y-4">
          {experience.map(exp => (
            <li key={exp.id} className="border-b pb-3 last:border-0">
              <div className="flex justify-between items-center">
                <div>
                  <div className="font-semibold text-gray-900">{exp.title}</div>
                  <div className="text-gray-600 text-sm">{exp.company} · {exp.location}</div>
                  <div className="text-gray-500 text-xs">{exp.startDate} - {exp.endDate || "حتى الآن"}</div>
                  <div className="text-gray-700 mt-1 whitespace-pre-line">{exp.description}</div>
                </div>
                <div className="flex gap-2">
                  <button className="text-[#1666b1] hover:underline text-sm" onClick={() => onEdit(exp.id)}>تعديل</button>
                  <button className="text-red-500 hover:underline text-sm" onClick={() => onDelete(exp.id)}>حذف</button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default ProfileSectionExperience;
