import { useRef, useState, useEffect } from 'react';
import * as bodyPix from '@tensorflow-models/body-pix';
import '@tensorflow/tfjs';

interface VideoRecorderProps {
  onRecorded: (file: File) => void;
}

const BACKGROUNDS = [
  { label: 'شفاف (بدون تغيير)', value: 'none' },
  { label: 'لون أزرق', value: 'blue' },
  { label: 'لون أخضر', value: 'green' },
  { label: 'خلفية بيضاء مع لوقو JobsStory', value: 'logo' },
];

export default function VideoRecorder({ onRecorded }: VideoRecorderProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [recording, setRecording] = useState(false);
  const [mediaRecorder, setMediaRecorder] = useState<MediaRecorder | null>(null);
  const [error, setError] = useState('');
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [recordedUrl, setRecordedUrl] = useState<string | null>(null);
  const [selectedBg, setSelectedBg] = useState('none');
  const [loadingModel, setLoadingModel] = useState(false);
  const [model, setModel] = useState<bodyPix.BodyPix | null>(null);
  const logo = typeof window !== 'undefined' ? new window.Image() : null;
  if (logo) logo.src = '/jobsstory-logo.png';

  // Show camera preview immediately when component mounts
  useEffect(() => {
    let localStream: MediaStream | null = null;
    const openCamera = async () => {
      try {
        const mediaStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
        localStream = mediaStream;
        setStream(mediaStream);
        if (videoRef.current) {
          videoRef.current.srcObject = mediaStream;
        }
      } catch (err) {
        setError('لا يمكن فتح الكاميرا. تأكد من إعطاء الصلاحية.');
      }
    };
    openCamera();
    return () => {
      if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
      }
    };
  }, []);

  // عند تغيير الخلفية أو تحميل النموذج أو فتح الكاميرا، فعّل المعالجة الفورية
  useEffect(() => {
    if (selectedBg === 'none' || !canvasRef.current || !videoRef.current || !model) return;
    let stopped = false;
    const drawFrame = async () => {
      if (stopped) return;
      if (!videoRef.current || !canvasRef.current) return;
      if (videoRef.current.readyState < 2) {
        requestAnimationFrame(drawFrame);
        return;
      }
      const segmentation = await model.segmentPerson(videoRef.current);
      const ctx = canvasRef.current.getContext('2d');
      ctx!.drawImage(videoRef.current, 0, 0, canvasRef.current.width, canvasRef.current.height);
      const imageData = ctx!.getImageData(0, 0, canvasRef.current.width, canvasRef.current.height);
      for (let i = 0; i < segmentation.data.length; i++) {
        if (segmentation.data[i] === 0) {
          // الخلفية
          if (selectedBg === 'blue') {
            imageData.data[i * 4 + 0] = 65;
            imageData.data[i * 4 + 1] = 105;
            imageData.data[i * 4 + 2] = 225;
          } else if (selectedBg === 'green') {
            imageData.data[i * 4 + 0] = 34;
            imageData.data[i * 4 + 1] = 197;
            imageData.data[i * 4 + 2] = 94;
          } else if (selectedBg === 'logo') {
            imageData.data[i * 4 + 0] = 255;
            imageData.data[i * 4 + 1] = 255;
            imageData.data[i * 4 + 2] = 255;
          }
        }
      }
      ctx!.putImageData(imageData, 0, 0);
      if (selectedBg === 'logo' && logo) {
        ctx!.drawImage(logo, canvasRef.current.width - 80, canvasRef.current.height - 80, 70, 70);
      }
      requestAnimationFrame(drawFrame);
    };
    drawFrame();
    return () => { stopped = true; };
  }, [selectedBg, model, stream]);

  // عند تغيير الخلفية، يجب إعادة تحميل النموذج فقط
  useEffect(() => {
    if (selectedBg === 'none') return;
    let mounted = true;
    setLoadingModel(true);
    bodyPix.load().then(net => {
      if (mounted) {
        setModel(net);
        setLoadingModel(false);
      }
    });
    return () => { mounted = false; };
  }, [selectedBg]);

  const startRecording = async () => {
    setError('');
    try {
      // الكاميرا تعمل بالفعل والمعاينة مفعلة
      // فقط ابدأ التسجيل من الـ stream المناسب
      const mediaStream = selectedBg === 'none' ? stream : (canvasRef.current as any).captureStream();
      const chunks: Blob[] = [];
      const recorder = new MediaRecorder(mediaStream, { mimeType: 'video/webm' });
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunks.push(e.data);
      };
      recorder.onstop = () => {
        const blob = new Blob(chunks, { type: 'video/webm' });
        setRecordedUrl(URL.createObjectURL(blob));
        const file = new File([blob], `recorded_${Date.now()}.webm`, { type: 'video/webm' });
        onRecorded(file);
        if (stream) stream.getTracks().forEach(track => track.stop());
      };
      recorder.start();
      setMediaRecorder(recorder);
      setRecording(true);
    } catch (err: any) {
      setError('تعذر بدء التسجيل');
    }
  };

  const stopRecording = () => {
    if (mediaRecorder && recording) {
      mediaRecorder.stop();
      setRecording(false);
      setMediaRecorder(null);
    }
  };

  return (
    <div className="mb-4">
      <div className="flex flex-col items-center gap-2">
        <div className="mb-2">
          <label className="font-semibold">اختر خلفية الفيديو:</label>
          <select value={selectedBg} onChange={e => setSelectedBg(e.target.value)} className="ml-2 border rounded px-2 py-1">
            {BACKGROUNDS.map(bg => (
              <option key={bg.value} value={bg.value}>{bg.label}</option>
            ))}
          </select>
        </div>
        {selectedBg !== 'none' && loadingModel && (
          <div className="text-blue-600 font-bold">جاري تحميل نموذج الذكاء الاصطناعي ...</div>
        )}
        {selectedBg === 'none' ? (
          <video ref={videoRef} autoPlay playsInline muted className="rounded w-full max-w-xs h-56 bg-black mb-2" />
        ) : (
          <canvas ref={canvasRef} width={320} height={224} className="rounded w-full max-w-xs h-56 bg-black mb-2" />
        )}
        {recordedUrl && (
          <video src={recordedUrl} controls className="rounded w-full max-w-xs h-56 bg-black mb-2" />
        )}
        {error && <div className="text-red-600">{error}</div>}
        <div className="flex gap-2">
          {!recording ? (
            <button onClick={startRecording} className="bg-green-600 text-white px-4 py-2 rounded" disabled={selectedBg !== 'none' && loadingModel}>بدء التسجيل</button>
          ) : (
            <button onClick={stopRecording} className="bg-red-600 text-white px-4 py-2 rounded">إيقاف التسجيل</button>
          )}
        </div>
      </div>
    </div>
  );
}
