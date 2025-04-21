import React from "react";
import { Education } from "../lib/educationProfile";

interface ProfileSectionEducationProps {
  education: Education[];
  onAdd: () => void;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

const ProfileSectionEducation: React.FC<ProfileSectionEducationProps> = ({ education, onAdd, onEdit, onDelete }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" /><path strokeLinecap="round" strokeLinejoin="round" d="M12 14l6.16-3.422A12.083 12.083 0 0121 13.255M12 14v7.5m0 0a3.75 3.75 0 11-7.5 0m7.5 0a3.75 3.75 0 107.5 0" /></svg>
          التعليم
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onAdd}>إضافة</button>
      </div>
      <div>
        {education.length === 0 && (
          <div className="text-gray-500 text-sm">لم تتم إضافة شهادات تعليمية بعد.</div>
        )}
        <ul className="space-y-4">
          {education.map(edu => (
            <li key={edu.id} className="border-b pb-3 last:border-0">
              <div className="flex justify-between items-center">
                <div>
                  <div className="font-semibold text-gray-900">{edu.school}</div>
                  <div className="text-gray-600 text-sm">{edu.degree} · {edu.fieldOfStudy}</div>
                  <div className="text-gray-500 text-xs">{edu.startDate} - {edu.endDate || "حتى الآن"}</div>
                  <div className="text-gray-700 mt-1 whitespace-pre-line">{edu.description}</div>
                </div>
                <div className="flex gap-2">
                  <button className="text-[#1666b1] hover:underline text-sm" onClick={() => onEdit(edu.id)}>تعديل</button>
                  <button className="text-red-500 hover:underline text-sm" onClick={() => onDelete(edu.id)}>حذف</button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default ProfileSectionEducation;
