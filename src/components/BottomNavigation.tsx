import Link from 'next/link';
import { useRouter } from 'next/router';

const navItems = [
  { href: '/feed', label: 'الرئيسية', icon: '🏠' },
  { href: '/search', label: 'بحث', icon: '🔍' },
  { href: '/upload-story', label: 'رفع', icon: '➕' },
  { href: '/notifications', label: 'إشعارات', icon: '🔔' },
  { href: '/profile', label: 'حسابي', icon: '👤' },
];

export default function BottomNavigation() {
  const router = useRouter();
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-black bg-opacity-90 border-t border-gray-800 flex justify-around items-center h-16 md:hidden">
      {navItems.map(item => (
        <Link href={item.href} key={item.href} legacyBehavior>
          <a className={`flex flex-col items-center justify-center px-2 py-1 text-xs font-bold transition-colors duration-200 ${router.pathname === item.href ? 'text-yellow-400' : 'text-white'}`}
            style={{ fontSize: '1.7rem' }}
          >
            <span>{item.icon}</span>
            <span className="text-[0.7rem] mt-1">{item.label}</span>
          </a>
        </Link>
      ))}
    </nav>
  );
}
