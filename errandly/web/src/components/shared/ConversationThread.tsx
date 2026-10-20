'use client';

import { useState, useEffect, useRef } from 'react';
import { useParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { messageApi, uploadApi } from '@/lib/api';
import { subscribeErrandChannel } from '@/lib/pusher';
import { useAuthStore } from '@/store/authStore';
import Link from 'next/link';
import {
  ArrowLeft,
  Loader2,
  Send,
  Mic,
  Image as ImageIcon,
  Video as VideoIcon,
  Play,
  Pause,
  X,
  Trash2,
  FileText,
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';

type Props = {
  backHref: string;
};

interface ChatMessage {
  id: number | string;
  sender_id: number;
  type?: 'text' | 'image' | 'voice' | 'video' | 'system' | 'location';
  content?: string;
  media_url?: string;
  media_type?: string;
  duration_seconds?: number;
  created_at: string;
  sender?: {
    id?: number;
    first_name?: string;
    last_name?: string;
    profile_image?: string;
  };
}

const resolveMediaUrl = (url?: string | null) => {
  if (!url) return '';
  if (url.startsWith('data:')) return url;

  const isClientHttps = typeof window !== 'undefined' && window.location.protocol === 'https:';

  if (url.startsWith('http://') || url.startsWith('https://')) {
    if (isClientHttps || url.includes('sslip.io')) {
      return url.replace(/^http:\/\//i, 'https://');
    }
    return url;
  }

  const rawApiBase = (process.env.NEXT_PUBLIC_API_URL || 'https://errandly-web-yob65x-3fabb8-169-58-145-66.sslip.io/api').replace(/\/api\/?$/, '');
  const apiBase = isClientHttps || rawApiBase.includes('sslip.io')
    ? rawApiBase.replace(/^http:\/\//i, 'https://')
    : rawApiBase;

  return `${apiBase}/${url.replace(/^\/+/, '')}`;
};

export default function ConversationThread({ backHref }: Props) {
  const params = useParams();
  const publicId = params.publicId as string;
  const { user } = useAuthStore();
  const queryClient = useQueryClient();

  const [text, setText] = useState('');
  const [liveMessages, setLiveMessages] = useState<ChatMessage[]>([]);
  const [activeMediaPreview, setActiveMediaPreview] = useState<string | null>(null);

  // Audio Recording states
  const [isRecording, setIsRecording] = useState(false);
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const timerRef = useRef<NodeJS.Timeout | null>(null);

  // File uploading states
  const [isUploading, setIsUploading] = useState(false);
  const imageInputRef = useRef<HTMLInputElement>(null);
  const videoInputRef = useRef<HTMLInputElement>(null);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const { data, isLoading } = useQuery({
    queryKey: ['conversation', publicId],
    queryFn: () => messageApi.getConversation(publicId).then((r) => r.data),
    enabled: !!publicId,
    refetchInterval: 15000,
  });

  // Sync query data to liveMessages
  useEffect(() => {
    if (data?.data) {
      setLiveMessages(data.data);
    }
  }, [data]);

  useEffect(() => {
    scrollToBottom();
  }, [liveMessages]);

  // Real-time Pusher Subscription
  useEffect(() => {
    if (!publicId) return;

    const unsubscribe = subscribeErrandChannel(publicId, (eventName, rawData: any) => {
      if (eventName === 'NewMessage' && rawData) {
        setLiveMessages((prev) => {
          if (prev.some((m) => m.id === rawData.id)) return prev;
          return [...prev, rawData];
        });
        scrollToBottom();
        queryClient.invalidateQueries({ queryKey: ['conversations'] });
      }
    });

    return () => {
      if (unsubscribe) unsubscribe();
    };
  }, [publicId, queryClient]);

  // Text Send Mutation
  const sendMutation = useMutation({
    mutationFn: (payload: { content?: string; media_url?: string; type?: string; duration_seconds?: number }) =>
      messageApi.send(publicId, payload),
    onSuccess: (res) => {
      setText('');
      const newMsg = res.data;
      if (newMsg) {
        setLiveMessages((prev) => (prev.some((m) => m.id === newMsg.id) ? prev : [...prev, newMsg]));
      }
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
      scrollToBottom();
    },
    onError: (e: any) => {
      toast.error(e.response?.data?.message || 'Could not send message');
    },
  });

  // Start Voice Recording
  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) {
          audioChunksRef.current.push(e.data);
        }
      };

      mediaRecorder.start();
      setIsRecording(true);
      setRecordingSeconds(0);

      timerRef.current = setInterval(() => {
        setRecordingSeconds((prev) => prev + 1);
      }, 1000);
    } catch (err) {
      toast.error('Microphone access is required to record voice notes');
    }
  };

  // Stop & Cancel Voice Recording
  const cancelRecording = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach((track) => track.stop());
    }
    setIsRecording(false);
    setRecordingSeconds(0);
    audioChunksRef.current = [];
  };

  // Stop & Send Voice Recording
  const stopAndSendRecording = async () => {
    if (!mediaRecorderRef.current || mediaRecorderRef.current.state === 'inactive') return;

    if (timerRef.current) clearInterval(timerRef.current);
    const duration = recordingSeconds;

    mediaRecorderRef.current.onstop = async () => {
      const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
      mediaRecorderRef.current?.stream.getTracks().forEach((track) => track.stop());
      setIsRecording(false);
      setRecordingSeconds(0);

      if (duration < 1) {
        toast.error('Voice note too short');
        return;
      }

      setIsUploading(true);
      try {
        const uploadRes = await uploadApi.upload(audioBlob, 'chat', `voice_${Date.now()}.webm`);
        const mediaUrl = uploadRes.data.url;

        await sendMutation.mutateAsync({
          type: 'voice',
          media_url: mediaUrl,
          duration_seconds: duration,
        });
      } catch (err: any) {
        toast.error(err.response?.data?.message || 'Failed to upload voice note');
      } finally {
        setIsUploading(false);
      }
    };

    mediaRecorderRef.current.stop();
  };

  // Handle File Upload (Image / Video)
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>, type: 'image' | 'video') => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Reset input
    e.target.value = '';

    setIsUploading(true);
    const loadingToast = toast.loading(`Uploading ${type}...`);
    try {
      const uploadRes = await uploadApi.upload(file, 'chat');
      const mediaUrl = uploadRes.data.url;

      await sendMutation.mutateAsync({
        type,
        media_url: mediaUrl,
      });
      toast.success(`${type === 'image' ? 'Photo' : 'Video'} sent!`, { id: loadingToast });
    } catch (err: any) {
      toast.error(err.response?.data?.message || `Failed to upload ${type}`, { id: loadingToast });
    } finally {
      setIsUploading(false);
    }
  };

  const formatTimer = (totalSecs: number) => {
    const mins = Math.floor(totalSecs / 60);
    const secs = totalSecs % 60;
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] pb-20 bg-background text-on-background">
      {/* Top Header */}
      <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-white/10 bg-white dark:bg-[#121317] sticky top-16 z-10">
        <div className="flex items-center gap-3">
          <Link href={backHref} className="p-2 rounded-xl hover:bg-gray-100 dark:hover:bg-white/10 transition">
            <ArrowLeft className="w-5 h-5 text-gray-700 dark:text-gray-200" />
          </Link>
          <div>
            <h1 className="font-bold text-[#0E0F13] dark:text-white text-base">Errand Chat</h1>
            <p className="text-xs text-gray-500 dark:text-gray-400">Real-time messaging & media</p>
          </div>
        </div>
      </div>

      {/* Messages List */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-6 h-6 animate-spin text-[#F97316]" />
          </div>
        ) : liveMessages.length === 0 ? (
          <div className="text-center py-12">
            <div className="w-12 h-12 rounded-full bg-orange-500/10 text-[#F97316] flex items-center justify-center mx-auto mb-3">
              <FileText className="w-6 h-6" />
            </div>
            <p className="text-gray-500 dark:text-gray-400 text-sm font-medium">No messages yet.</p>
            <p className="text-xs text-gray-400 mt-1">Send a message, voice note, photo, or video!</p>
          </div>
        ) : (
          liveMessages.map((msg) => {
            const mine = msg.sender_id === user?.id;
            return (
              <div key={msg.id} className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                <div
                  className={`max-w-[85%] sm:max-w-[70%] rounded-2xl px-4 py-3 text-sm shadow-sm ${
                    mine
                      ? 'bg-[#F97316] text-white rounded-br-xs'
                      : 'bg-white dark:bg-[#1A1B22] border border-gray-100 dark:border-white/10 text-[#0E0F13] dark:text-white rounded-bl-xs'
                  }`}
                >
                  {/* Media Rendering: Photo */}
                  {msg.type === 'image' && msg.media_url && (
                    <div className="mb-2">
                      <img
                        src={resolveMediaUrl(msg.media_url)}
                        alt="Shared image"
                        className="rounded-xl max-h-60 w-auto object-cover cursor-pointer hover:opacity-95 transition"
                        onClick={() => setActiveMediaPreview(resolveMediaUrl(msg.media_url))}
                      />
                    </div>
                  )}

                  {/* Media Rendering: Video */}
                  {msg.type === 'video' && msg.media_url && (
                    <div className="mb-2">
                      <video
                        src={resolveMediaUrl(msg.media_url)}
                        controls
                        playsInline
                        preload="metadata"
                        className="rounded-xl max-h-64 w-full bg-black/40"
                      />
                    </div>
                  )}

                  {/* Media Rendering: Voice Note */}
                  {msg.type === 'voice' && msg.media_url && (
                    <div className="my-1">
                      <VoiceMessagePlayer
                        mediaUrl={resolveMediaUrl(msg.media_url)}
                        duration={msg.duration_seconds || 0}
                        mine={mine}
                      />
                    </div>
                  )}

                  {/* Text Content */}
                  {msg.content && <p className="whitespace-pre-wrap break-words">{msg.content}</p>}

                  {/* Timestamp */}
                  <p
                    className={`text-[10px] mt-1 text-right font-medium ${
                      mine ? 'text-orange-100' : 'text-gray-400 dark:text-gray-500'
                    }`}
                  >
                    {formatDistanceToNow(new Date(msg.created_at), { addSuffix: true })}
                  </p>
                </div>
              </div>
            );
          })
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Hidden File Inputs */}
      <input
        ref={imageInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => handleFileUpload(e, 'image')}
      />
      <input
        ref={videoInputRef}
        type="file"
        accept="video/*"
        className="hidden"
        onChange={(e) => handleFileUpload(e, 'video')}
      />

      {/* Image Lightbox Modal */}
      {activeMediaPreview && (
        <div
          className="fixed inset-0 z-50 bg-black/90 flex items-center justify-center p-4 backdrop-blur-sm"
          onClick={() => setActiveMediaPreview(null)}
        >
          <button
            className="absolute top-5 right-5 p-2 rounded-full bg-white/10 hover:bg-white/20 text-white transition"
            onClick={() => setActiveMediaPreview(null)}
          >
            <X className="w-6 h-6" />
          </button>
          <img
            src={resolveMediaUrl(activeMediaPreview)}
            alt="Enlarged view"
            className="max-h-[90vh] max-w-[90vw] object-contain rounded-xl"
          />
        </div>
      )}

      {/* Recording Bar or Input Form */}
      {isRecording ? (
        <div className="p-4 bg-white dark:bg-[#121317] border-t border-gray-100 dark:border-white/10 flex items-center justify-between gap-3 animate-in fade-in duration-200">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-red-500 animate-ping" />
            <span className="text-sm font-semibold text-red-500">Recording audio...</span>
            <span className="text-sm font-mono text-gray-700 dark:text-gray-200 ml-2">
              {formatTimer(recordingSeconds)}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={cancelRecording}
              className="p-2.5 rounded-xl text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition"
              title="Cancel recording"
            >
              <Trash2 className="w-5 h-5" />
            </button>
            <button
              onClick={stopAndSendRecording}
              className="px-4 py-2 bg-[#F97316] text-white rounded-xl font-semibold flex items-center gap-1.5 hover:bg-[#ea580c] transition shadow-md shadow-orange-500/20"
            >
              <Send className="w-4 h-4" />
              <span>Send</span>
            </button>
          </div>
        </div>
      ) : (
        <form
          className="p-3 sm:p-4 bg-white dark:bg-[#121317] border-t border-gray-100 dark:border-white/10 flex items-center gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            if (!text.trim() || sendMutation.isPending || isUploading) return;
            sendMutation.mutate({ content: text.trim(), type: 'text' });
          }}
        >
          {/* Action buttons: Image, Video, Mic */}
          <div className="flex items-center gap-1">
            <button
              type="button"
              disabled={isUploading}
              onClick={() => imageInputRef.current?.click()}
              className="p-2.5 rounded-xl text-gray-500 hover:text-[#F97316] hover:bg-orange-50 dark:hover:bg-white/5 transition disabled:opacity-50"
              title="Send Photo"
            >
              <ImageIcon className="w-5 h-5" />
            </button>
            <button
              type="button"
              disabled={isUploading}
              onClick={() => videoInputRef.current?.click()}
              className="p-2.5 rounded-xl text-gray-500 hover:text-[#F97316] hover:bg-orange-50 dark:hover:bg-white/5 transition disabled:opacity-50"
              title="Send Video"
            >
              <VideoIcon className="w-5 h-5" />
            </button>
            <button
              type="button"
              disabled={isUploading}
              onClick={startRecording}
              className="p-2.5 rounded-xl text-gray-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-white/5 transition disabled:opacity-50"
              title="Record Voice Note"
            >
              <Mic className="w-5 h-5" />
            </button>
          </div>

          <input
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Type a message…"
            disabled={isUploading}
            className="flex-1 bg-gray-50 dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-xl px-4 py-2.5 text-sm text-[#0E0F13] dark:text-white placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#F97316]/40"
          />

          <button
            type="submit"
            disabled={!text.trim() || sendMutation.isPending || isUploading}
            className="p-2.5 sm:px-4 sm:py-2.5 bg-[#F97316] text-white rounded-xl disabled:opacity-50 hover:bg-[#ea580c] transition flex items-center justify-center shadow-md shadow-orange-500/20"
          >
            {sendMutation.isPending || isUploading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <Send className="w-5 h-5" />
            )}
          </button>
        </form>
      )}
    </div>
  );
}

// Inline Voice Message Audio Player
function VoiceMessagePlayer({ mediaUrl, duration, mine }: { mediaUrl: string; duration: number; mine: boolean }) {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const togglePlay = () => {
    if (!audioRef.current) return;
    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
  };

  const formatSecs = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m}:${s < 10 ? '0' : ''}${s}`;
  };

  return (
    <div className="flex items-center gap-3 py-1 min-w-[200px]">
      <audio
        ref={audioRef}
        src={mediaUrl}
        preload="metadata"
        onPlay={() => setIsPlaying(true)}
        onPause={() => setIsPlaying(false)}
        onEnded={() => {
          setIsPlaying(false);
          setCurrentTime(0);
        }}
        onTimeUpdate={() => {
          if (audioRef.current) setCurrentTime(audioRef.current.currentTime);
        }}
      />
      <button
        type="button"
        onClick={togglePlay}
        className={`w-9 h-9 rounded-full flex items-center justify-center shrink-0 transition ${
          mine
            ? 'bg-white text-[#F97316] hover:bg-orange-50'
            : 'bg-[#F97316] text-white hover:bg-[#ea580c]'
        }`}
      >
        {isPlaying ? <Pause className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current ml-0.5" />}
      </button>

      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between text-xs font-mono mb-1">
          <span className={mine ? 'text-orange-100' : 'text-gray-500 dark:text-gray-400'}>
            {isPlaying ? formatSecs(currentTime) : formatSecs(duration)}
          </span>
          <span className={`text-[10px] ${mine ? 'text-orange-200' : 'text-gray-400'}`}>Voice Note</span>
        </div>
        <div className={`h-1.5 rounded-full overflow-hidden ${mine ? 'bg-white/30' : 'bg-gray-200 dark:bg-white/10'}`}>
          <div
            className={`h-full transition-all duration-100 ${mine ? 'bg-white' : 'bg-[#F97316]'}`}
            style={{ width: `${duration > 0 ? (currentTime / duration) * 100 : 0}%` }}
          />
        </div>
      </div>
    </div>
  );
}
