import React from "react";
import { Project } from "../lib/projectsProfile";

interface ProfileSectionProjectsProps {
  projects: Project[];
  onAdd: () => void;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

const ProfileSectionProjects: React.FC<ProfileSectionProjectsProps> = ({ projects, onAdd, onEdit, onDelete }) => {
  return (
    <div className="bg-white rounded-xl shadow p-6 mb-6">
      <div className="flex justify-between items-center mb-2">
        <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2">
          <svg className="w-6 h-6 text-[#1666b1]" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4l3 3" /></svg>
          المشاريع
        </h2>
        <button className="text-[#1666b1] font-semibold hover:underline" onClick={onAdd}>إضافة</button>
      </div>
      <div>
        {projects.length === 0 && (
          <div className="text-gray-500 text-sm">لم تتم إضافة مشاريع بعد.</div>
        )}
        <ul className="space-y-4">
          {projects.map(project => (
            <li key={project.id} className="border-b pb-3 last:border-0">
              <div className="flex justify-between items-center">
                <div>
                  <div className="font-semibold text-gray-900">{project.name}</div>
                  <div className="text-gray-600 text-sm">{project.url && <a href={project.url} className="underline text-[#1666b1]" target="_blank" rel="noopener noreferrer">{project.url}</a>}</div>
                  <div className="text-gray-700 mt-1 whitespace-pre-line">{project.description}</div>
                </div>
                <div className="flex gap-2">
                  <button className="text-[#1666b1] hover:underline text-sm" onClick={() => onEdit(project.id)}>تعديل</button>
                  <button className="text-red-500 hover:underline text-sm" onClick={() => onDelete(project.id)}>حذف</button>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default ProfileSectionProjects;
