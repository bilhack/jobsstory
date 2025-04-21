import React from "react";
import Link from "next/link";

const HeaderLinkedinWeb: React.FC = () => {
  return (
    <header className="w-full bg-white shadow-sm fixed top-0 left-0 z-50 border-b border-gray-200">
      <div className="max-w-7xl mx-auto flex items-center justify-between px-6 py-1 h-[56px]">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2">
          <img src="/logo.svg" alt="JobsStory Logo" className="w-8 h-8" />
          <span className="font-bold text-xl text-[#1666b1] hidden lg:block">JobsStory</span>
        </Link>
        {/* Search Bar */}
        <div className="flex-1 flex justify-center mx-6">
          <div className="relative w-full max-w-xs">
            <input
              type="text"
              placeholder="Search..."
              className="w-full rounded-md border border-gray-300 bg-[#f3f6fb] pl-10 pr-3 py-1.5 text-sm focus:outline-none focus:border-[#1666b1]"
            />
            <svg className="absolute left-2 top-1.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8" /><path d="M21 21l-4.35-4.35" /></svg>
          </div>
        </div>
        {/* Navigation Icons */}
        <nav className="flex items-center gap-6 text-gray-600 text-xs">
          <Link href="/" className="flex flex-col items-center hover:text-[#1666b1]">
            <svg className="w-6 h-6 mb-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M3 12l9-9 9 9" /><path d="M9 21V9h6v12" /></svg>
            Home
          </Link>
          <Link href="/network" className="flex flex-col items-center hover:text-[#1666b1]">
            <svg className="w-6 h-6 mb-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><circle cx="7" cy="7" r="4" /><circle cx="17" cy="17" r="4" /><path d="M7 17v-4a4 4 0 014-4h2" /></svg>
            Network
          </Link>
          <Link href="/jobs" className="flex flex-col items-center hover:text-[#1666b1]">
            <svg className="w-6 h-6 mb-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><rect x="2" y="7" width="20" height="14" rx="2" /><path d="M16 3v4M8 3v4" /></svg>
            Jobs
          </Link>
          <Link href="/messaging" className="flex flex-col items-center hover:text-[#1666b1]">
            <svg className="w-6 h-6 mb-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" /></svg>
            Messaging
          </Link>
          <Link href="/notifications" className="flex flex-col items-center hover:text-[#1666b1]">
            <svg className="w-6 h-6 mb-0.5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M18 8a6 6 0 00-12 0v5a2 2 0 01-2 2h16a2 2 0 01-2-2z" /><path d="M13.73 21a2 2 0 01-3.46 0" /></svg>
            Notifications
          </Link>
          {/* Profile Dropdown */}
          <div className="relative group">
            <button className="flex flex-col items-center focus:outline-none">
              <img src="/default-avatar.png" alt="profile" className="w-6 h-6 rounded-full border border-gray-300 mb-0.5" />
              <span>Me</span>
            </button>
            <div className="absolute right-0 mt-2 w-40 bg-white border border-gray-200 rounded shadow-lg opacity-0 group-hover:opacity-100 pointer-events-none group-hover:pointer-events-auto transition-opacity z-50">
              <Link href="/profile" className="block px-4 py-2 text-sm hover:bg-[#f3f6fb]">View Profile</Link>
              <button className="block w-full text-left px-4 py-2 text-sm hover:bg-[#f3f6fb]">Logout</button>
            </div>
          </div>
        </nav>
      </div>
    </header>
  );
};

export default HeaderLinkedinWeb;
