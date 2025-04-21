import { useRef } from 'react';

interface ChatAttachmentProps {
  onUpload: (file: File) => void;
}

export default function ChatAttachment({ onUpload }: ChatAttachmentProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onUpload(e.target.files[0]);
      e.target.value = '';
    }
  };

  return (
    <>
      <button
        type="button"
        className="p-2 rounded-full hover:bg-gray-200 text-xl"
        title="إرفاق ملف"
        onClick={() => fileInputRef.current?.click()}
      >
        📎
      </button>
      <input
        ref={fileInputRef}
        type="file"
        style={{ display: 'none' }}
        onChange={handleFileChange}
      />
    </>
  );
}
