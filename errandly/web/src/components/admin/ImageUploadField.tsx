'use client';

import React, { useState, useRef } from 'react';
import { Upload, X, Copy, Check, ExternalLink, Image as ImageIcon, Loader2 } from 'lucide-react';
import { uploadApi } from '@/lib/api';
import toast from 'react-hot-toast';

interface ImageUploadFieldProps {
  label: string;
  value?: string;
  onChange: (url: string) => void;
  description?: string;
  folder?: string;
  aspectHint?: string;
}

export default function ImageUploadField({
  label,
  value,
  onChange,
  description,
  folder = 'cms',
  aspectHint,
}: ImageUploadFieldProps) {
  const [isUploading, setIsUploading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [manualMode, setManualMode] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (file: File) => {
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast.error('Please upload an image file (PNG, JPG, WebP, SVG)');
      return;
    }

    if (file.size > 25 * 1024 * 1024) {
      toast.error('File size must be under 25MB');
      return;
    }

    setIsUploading(true);
    try {
      const res = await uploadApi.upload(file, folder);
      const url = res.data?.url || res.data?.data?.url;
      if (!url) {
        throw new Error('Upload succeeded but no image URL was returned.');
      }
      onChange(url);
      toast.success('Image uploaded successfully!');
    } catch (err: any) {
      console.error('Image upload failed:', err);
      toast.error(err?.response?.data?.message || err?.message || 'Failed to upload image');
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFile(e.dataTransfer.files[0]);
    }
  };

  const handleCopy = () => {
    if (!value) return;
    navigator.clipboard.writeText(value);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
    toast.success('Image URL copied to clipboard');
  };

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300">
          {label}
        </label>
        {aspectHint && (
          <span className="text-[10px] text-gray-400 font-mono bg-gray-100 dark:bg-white/5 px-2 py-0.5 rounded">
            {aspectHint}
          </span>
        )}
      </div>

      {description && (
        <p className="text-[11px] text-gray-500 dark:text-gray-400">{description}</p>
      )}

      {/* Main Image Container */}
      <div className="flex flex-col sm:flex-row items-start gap-4 p-3 bg-gray-50/75 dark:bg-[#1A1B22]/50 border border-gray-200 dark:border-white/10 rounded-xl">
        {/* Thumbnail Preview */}
        {value ? (
          <div className="relative group shrink-0 w-28 h-28 rounded-lg overflow-hidden bg-black/5 dark:bg-white/5 border border-gray-200 dark:border-white/10 flex items-center justify-center">
            <img
              src={value}
              alt={label}
              className="w-full h-full object-contain p-1"
              onError={(e) => {
                (e.currentTarget as HTMLImageElement).src = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 24 24" fill="none" stroke="%23999" stroke-width="2"><rect width="18" height="18" x="3" y="3" rx="2" ry="2"/><circle cx="9" cy="9" r="2"/><path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/></svg>';
              }}
            />
            <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-1.5 p-1">
              <a
                href={value}
                target="_blank"
                rel="noreferrer"
                title="Open original"
                className="p-1.5 rounded-full bg-white/20 hover:bg-white/40 text-white transition"
              >
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
              <button
                type="button"
                onClick={handleCopy}
                title="Copy URL"
                className="p-1.5 rounded-full bg-white/20 hover:bg-white/40 text-white transition"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-green-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
              <button
                type="button"
                onClick={() => onChange('')}
                title="Remove image"
                className="p-1.5 rounded-full bg-red-500/80 hover:bg-red-600 text-white transition"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        ) : (
          <div className="w-28 h-28 rounded-lg border-2 border-dashed border-gray-300 dark:border-white/10 flex flex-col items-center justify-center text-gray-400 dark:text-gray-500 shrink-0">
            <ImageIcon className="w-8 h-8 stroke-[1.5] mb-1 opacity-60" />
            <span className="text-[10px]">No image</span>
          </div>
        )}

        {/* Upload & Controls */}
        <div className="flex-1 min-w-0 w-full space-y-2">
          <input
            ref={fileInputRef}
            type="file"
            accept="image/png,image/jpeg,image/webp,image/svg+xml,image/gif"
            className="hidden"
            onChange={(e) => {
              if (e.target.files && e.target.files[0]) {
                handleFile(e.target.files[0]);
              }
            }}
          />

          {/* Drag & Drop Trigger */}
          <div
            onDragOver={(e) => {
              e.preventDefault();
              e.stopPropagation();
            }}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current?.click()}
            className="cursor-pointer border-2 border-dashed border-orange-500/30 hover:border-[#F97316] hover:bg-orange-500/5 transition-all rounded-xl p-3 text-center"
          >
            {isUploading ? (
              <div className="flex items-center justify-center gap-2 py-1 text-xs text-[#F97316] font-medium">
                <Loader2 className="w-4 h-4 animate-spin" />
                <span>Uploading image to storage...</span>
              </div>
            ) : (
              <div className="flex items-center justify-center gap-2 py-1 text-xs text-gray-600 dark:text-gray-300 font-medium">
                <Upload className="w-4 h-4 text-[#F97316]" />
                <span>Click to browse or drop an image here</span>
              </div>
            )}
          </div>

          {/* Toggle manual URL input */}
          <div className="flex items-center justify-between text-[11px] pt-1">
            <button
              type="button"
              onClick={() => setManualMode(!manualMode)}
              className="text-[#F97316] hover:underline"
            >
              {manualMode ? 'Hide URL field' : 'Edit raw URL / CDN link'}
            </button>
            {value && (
              <span className="truncate max-w-[200px] text-gray-400 font-mono text-[10px]">
                {value.split('/').pop()}
              </span>
            )}
          </div>

          {manualMode && (
            <input
              type="text"
              value={value || ''}
              onChange={(e) => onChange(e.target.value)}
              placeholder="https://... or /image.png"
              className="w-full px-3 py-1.5 text-xs font-mono bg-white dark:bg-[#121317] border border-gray-300 dark:border-white/10 rounded-lg text-gray-800 dark:text-gray-200 focus:outline-none focus:ring-1 focus:ring-[#F97316]"
            />
          )}
        </div>
      </div>
    </div>
  );
}
