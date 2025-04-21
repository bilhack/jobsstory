import React from "react";
import { Certification } from "../lib/certificationProfile";

interface ProfileSectionCertificationsProps {
  certifications: Certification[];
  onAdd: () => void;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

const ProfileSectionCertifications: React.FC<ProfileSectionCertificationsProps> = ({ certifications, onAdd, onEdit, onDelete }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6l4 2" /></svg>
          الشهادات
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onAdd}>إضافة</button>
      </div>
      <div>
        {certifications.length === 0 && (
          <div className="text-gray-500 text-sm">لم تتم إضافة شهادات بعد.</div>
        )}
        <ul className="space-y-4">
          {certifications.map(cert => (
            <li key={cert.id} className="border-b pb-3 last:border-0">
              <div className="flex justify-between items-center">
                <div>
                  <div className="font-semibold text-gray-900">{cert.name}</div>
                  <div className="text-gray-600 text-sm">{cert.authority}</div>
                  <div className="text-gray-500 text-xs">{cert.date}</div>
                </div>
                <div className="flex gap-2">
                  <button className="text-[#1666b1] hover:underline text-sm" onClick={() => onEdit(cert.id)}>تعديل</button>
                  <button className="text-red-500 hover:underline text-sm" onClick={() => onDelete(cert.id)}>حذف</button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default ProfileSectionCertifications;
