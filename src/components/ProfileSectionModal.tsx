import React, { useRef } from 'react';
import { Dialog } from '@headlessui/react';

export interface ModalField {
  label: string;
  name: string;
  type: 'text' | 'textarea' | 'select' | 'date' | 'month' | 'number' | 'file';
  required?: boolean;
  options?: string[];
  placeholder?: string;
  multiple?: boolean;
  maxLength?: number;
}

interface ProfileSectionModalProps {
  open: boolean;
  title: string;
  fields: ModalField[];
  values: Record<string, any>;
  onChange: (name: string, value: any) => void;
  onClose: () => void;
  onSave: () => void;
  loading?: boolean;
  error?: string;
  saveLabel?: string;
}

const ProfileSectionModal: React.FC<ProfileSectionModalProps> = ({
  open,
  title,
  fields,
  values,
  onChange,
  onClose,
  onSave,
  loading,
  error,
  saveLabel = 'Save',
}) => {
  const fileRefs = useRef<{ [key: string]: HTMLInputElement | null }>({});

  return (
    <Dialog as="div" open={open} onClose={onClose} className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black bg-opacity-40" aria-hidden="true" />
      <Dialog.Panel className="bg-white rounded-xl shadow-xl w-full max-w-lg p-6 relative z-10">
        <Dialog.Title className="text-xl font-bold mb-4 text-[#1666b1]">{title}</Dialog.Title>
        <form
          className="space-y-4"
          onSubmit={e => {
            e.preventDefault();
            onSave();
          }}
        >
          {fields.map(field => (
            <div key={field.name} className="flex flex-col">
              <label className="font-semibold mb-1 text-[#1666b1]">
                {field.label}
                {field.required && <span className="text-red-500">*</span>}
              </label>
              {field.type === 'text' && (
                <input
                  type="text"
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  placeholder={field.placeholder || field.label}
                  required={field.required}
                  maxLength={field.maxLength}
                />
              )}
              {field.type === 'number' && (
                <input
                  type="number"
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  placeholder={field.placeholder || field.label}
                  required={field.required}
                />
              )}
              {field.type === 'month' && (
                <input
                  type="month"
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  required={field.required}
                />
              )}
              {field.type === 'date' && (
                <input
                  type="date"
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  required={field.required}
                />
              )}
              {field.type === 'select' && field.options && (
                <select
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  required={field.required}
                >
                  <option value="">اختر...</option>
                  {field.options.map(opt => (
                    <option key={opt} value={opt}>
                      {opt}
                    </option>
                  ))}
                </select>
              )}
              {field.type === 'textarea' && (
                <textarea
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1] min-h-[80px] resize-y"
                  name={field.name}
                  value={values[field.name] || ''}
                  onChange={e => onChange(field.name, e.target.value)}
                  placeholder={field.placeholder || field.label}
                  required={field.required}
                  maxLength={field.maxLength}
                />
              )}
              {field.type === 'file' && (
                <input
                  type="file"
                  className="border rounded px-3 py-2 focus:border-[#1666b1] focus:ring-2 focus:ring-[#1666b1]"
                  name={field.name}
                  multiple={field.multiple}
                  ref={el => (fileRefs.current[field.name] = el)}
                  onChange={e => onChange(field.name, field.multiple ? e.target.files : e.target.files?.[0])}
                />
              )}
            </div>
          ))}
          {error && <div className="text-red-500 text-sm text-center">{error}</div>}
          <div className="flex gap-2 mt-4 justify-end">
            <button
              type="button"
              className="bg-[#f58220] hover:bg-orange-600 text-white px-4 py-2 rounded font-bold"
              onClick={onClose}
              disabled={loading}
            >
              إلغاء
            </button>
            <button
              type="submit"
              className="bg-[#1666b1] hover:bg-[#12518e] text-white px-4 py-2 rounded font-bold"
              disabled={loading}
            >
              {loading ? 'جارٍ الحفظ...' : saveLabel}
            </button>
          </div>
        </form>
      </Dialog.Panel>
    </Dialog>
  );
};

export default ProfileSectionModal;
