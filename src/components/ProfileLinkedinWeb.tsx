import React from "react";
import { UserProfile } from "../lib/firestoreUser";
import { ProfileSection } from "../lib/profileSections";
import ProfileSectionAbout from "./ProfileSectionAbout";
import ProfileSectionExperience from "./ProfileSectionExperience";
import ProfileSectionEducation from "./ProfileSectionEducation";
import ProfileSectionSkills from "./ProfileSectionSkills";
import ProfileSectionCertifications from "./ProfileSectionCertifications";
import ProfileSectionProjects from "./ProfileSectionProjects";
import ProfileSectionLanguages from "./ProfileSectionLanguages";
import ProfileSectionContact from "./ProfileSectionContact";
import Link from 'next/link';
import FavoriteVideoItem from './FavoriteVideoItem';

// Placeholder for all section components (Experience, Education, Skills, etc.)
// Will be implemented in detail in subsequent steps

interface ProfileLinkedinWebProps {
  user: UserProfile;
  sections: ProfileSection[];
  // Event handlers for each section
  onAboutEdit?: () => void;
  onExperienceAdd?: () => void;
  onExperienceEdit?: (id: string) => void;
  onExperienceDelete?: (id: string) => void;
  onEducationAdd?: () => void;
  onEducationEdit?: (id: string) => void;
  onEducationDelete?: (id: string) => void;
  onSkillsAdd?: () => void;
  onSkillsDelete?: (skill: string) => void;
  onCertAdd?: () => void;
  onCertEdit?: (id: string) => void;
  onCertDelete?: (id: string) => void;
  onProjectsAdd?: () => void;
  onProjectsEdit?: (id: string) => void;
  onProjectsDelete?: (id: string) => void;
  onLanguagesAdd?: () => void;
  onLanguagesEdit?: (id: string) => void;
  onLanguagesDelete?: (id: string) => void;
  onContactEdit?: () => void;
}

const ProfileLinkedinWeb: React.FC<ProfileLinkedinWebProps> = ({
  user,
  sections,
  onAboutEdit,
  onExperienceAdd,
  onExperienceEdit,
  onExperienceDelete,
  onEducationAdd,
  onEducationEdit,
  onEducationDelete,
  onSkillsAdd,
  onSkillsDelete,
  onCertAdd,
  onCertEdit,
  onCertDelete,
  onProjectsAdd,
  onProjectsEdit,
  onProjectsDelete,
  onLanguagesAdd,
  onLanguagesEdit,
  onLanguagesDelete,
  onContactEdit,
}) => {
  // عرض الفيديو الشخصي (videoUrl)
  const hasVideo = !!user.videoUrl;
  // فيديوهات مفضلة
  const favoriteVideos = Array.isArray(user.savedVideos) ? user.savedVideos : [];

  return (
    <div className="bg-[#f3f6fb] min-h-screen pb-10">
      {/* Cover Photo & Avatar */}
      <div className="relative bg-white rounded-b-2xl shadow-md max-w-3xl mx-auto">
        <div className="h-40 bg-gradient-to-r from-[#1666b1] to-[#1e90ff] rounded-t-2xl"></div>
        <div className="absolute left-1/2 -translate-x-1/2 top-24">
          <img
            src={user.photoURL || "/default-avatar.png"}
            alt="avatar"
            className="w-36 h-36 rounded-full border-4 border-white shadow-lg object-cover"
          />
        </div>
        <div className="pt-28 pb-6 text-center">
          <h1 className="text-2xl font-bold text-gray-900">{user.displayName}</h1>
          {/* headline */}
          <p className="text-gray-600 text-base mt-1">{user.headline || user.role || "المسمى الوظيفي"}</p>
          {/* location */}
          <p className="text-gray-500 text-sm mt-1">{user.experience?.[0]?.location || "الموقع الجغرافي"}</p>
          <div className="flex justify-center gap-4 mt-4">
            {/* زر إرسال رسالة مباشرة */}
            <Link href={user.uid ? `/chat?user=${user.uid}` : '/chat'} legacyBehavior>
              <a className="bg-[#1666b1] text-white rounded-lg px-5 py-2 font-semibold hover:bg-[#145a99] transition">إرسال رسالة</a>
            </Link>
            <button className="bg-white border border-[#1666b1] text-[#1666b1] rounded-lg px-5 py-2 font-semibold hover:bg-[#f3f6fb] transition">إضافة قسم</button>
            <button className="bg-white border border-gray-300 text-gray-700 rounded-lg px-5 py-2 font-semibold hover:bg-gray-100 transition">المزيد</button>
          </div>
        </div>
        {/* عرض الفيديو الشخصي */}
        {hasVideo && (
          <div className="mb-8 flex justify-center">
            <video src={user.videoUrl} controls className="rounded-xl shadow-lg max-w-[400px] w-full" poster={user.thumbnailUrl} />
          </div>
        )}
        {/* قسم الفيديوهات المفضلة */}
        {favoriteVideos.length > 0 && (
          <div className="mb-8 px-6">
            <h2 className="text-xl font-bold text-[#1666b1] mb-4">فيديوهات مفضلة</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {favoriteVideos.map((videoId: string) => (
                <FavoriteVideoItem key={videoId} videoId={videoId} />
              ))}
            </div>
          </div>
        )}
      </div>

      {/* About Section */}
      <div className="max-w-3xl mx-auto mt-6">
        <ProfileSectionAbout about={user.about || ""} onEdit={onAboutEdit || (() => {})} />
      </div>

      {/* Experience Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionExperience
          experience={user.experience || []}
          onAdd={onExperienceAdd || (() => {})}
          onEdit={onExperienceEdit || (() => {})}
          onDelete={onExperienceDelete || (() => {})}
        />
      </div>

      {/* Education Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionEducation
          education={user.education || []}
          onAdd={onEducationAdd || (() => {})}
          onEdit={onEducationEdit || (() => {})}
          onDelete={onEducationDelete || (() => {})}
        />
      </div>

      {/* Skills Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionSkills
          skills={user.skills || []}
          onAdd={onSkillsAdd || (() => {})}
          onDelete={onSkillsDelete || (() => {})}
        />
      </div>

      {/* Certifications Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionCertifications
          certifications={user.certifications || []}
          onAdd={onCertAdd || (() => {})}
          onEdit={onCertEdit || (() => {})}
          onDelete={onCertDelete || (() => {})}
        />
      </div>

      {/* Projects Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionProjects
          projects={user.projects || []}
          onAdd={onProjectsAdd || (() => {})}
          onEdit={onProjectsEdit || (() => {})}
          onDelete={onProjectsDelete || (() => {})}
        />
      </div>

      {/* Languages Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionLanguages
          languages={user.languages || []}
          onAdd={onLanguagesAdd || (() => {})}
          onEdit={onLanguagesEdit || (() => {})}
          onDelete={onLanguagesDelete || (() => {})}
        />
      </div>

      {/* Contact Section */}
      <div className="max-w-3xl mx-auto">
        <ProfileSectionContact
          email={user.email || ""}
          phone={user.contact?.phone}
          linkedin={user.contact?.linkedin}
          website={user.contact?.website}
          onEdit={onContactEdit || (() => {})}
        />
      </div>
    </div>
  );
};

export default ProfileLinkedinWeb;
