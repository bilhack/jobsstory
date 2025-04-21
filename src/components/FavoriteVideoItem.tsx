import { useEffect, useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface FavoriteVideoItemProps {
  videoId: string;
}

export default function FavoriteVideoItem({ videoId }: FavoriteVideoItemProps) {
  const [video, setVideo] = useState<any>(null);
  useEffect(() => {
    const fetchVideo = async () => {
      const snap = await getDoc(doc(db, 'videos', videoId));
      if (snap.exists()) setVideo(snap.data());
    };
    fetchVideo();
  }, [videoId]);

  if (!video) return (
    <div className="bg-gray-100 rounded-lg p-4 flex flex-col items-center animate-pulse min-h-[320px]">جاري التحميل...</div>
  );

  return (
    <div className="bg-[#f8fafc] rounded-lg shadow p-4 flex flex-col items-center">
      <video src={video.videoUrl || video.videoURL} poster={video.thumbnailUrl} controls className="w-full max-w-[260px] h-[320px] object-cover rounded mb-2" />
      <div className="font-bold text-[#1666b1]">{video.title || 'فيديو'}</div>
    </div>
  );
}
