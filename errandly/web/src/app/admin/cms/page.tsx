'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Save,
  RefreshCw,
  Eye,
  Plus,
  Trash2,
  Image as ImageIcon,
  Home,
  Info,
  Briefcase,
  Phone,
  Shield,
  Layers,
  Code,
  CheckCircle2,
  ExternalLink,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import toast from 'react-hot-toast';
import ImageUploadField from '@/components/admin/ImageUploadField';

type TabKey = 'home' | 'about' | 'careers' | 'contact' | 'privacy' | 'media' | 'raw';

export default function AdminCMSPage() {
  const [activeTab, setActiveTab] = useState<TabKey>('home');
  const [content, setContent] = useState<any>(null);
  const [rawJson, setRawJson] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  const fetchContent = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/cms');
      if (!res.ok) throw new Error('Failed to fetch CMS content');
      const data = await res.json();
      setContent(data);
      setRawJson(JSON.stringify(data, null, 2));
      setHasUnsavedChanges(false);
    } catch (error) {
      console.error(error);
      toast.error('Could not load CMS content from server');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchContent();
  }, []);

  const updateContentField = (path: string[], value: any) => {
    setContent((prev: any) => {
      if (!prev) return prev;
      const clone = JSON.parse(JSON.stringify(prev));
      let cur = clone;
      for (let i = 0; i < path.length - 1; i++) {
        if (!cur[path[i]]) cur[path[i]] = {};
        cur = cur[path[i]];
      }
      cur[path[path.length - 1]] = value;
      setRawJson(JSON.stringify(clone, null, 2));
      setHasUnsavedChanges(true);
      return clone;
    });
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      let payload = content;
      if (activeTab === 'raw') {
        payload = JSON.parse(rawJson);
        setContent(payload);
      }

      const res = await fetch('/api/cms', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (!res.ok) throw new Error('Save failed');
      setHasUnsavedChanges(false);
      toast.success('Website content & media saved successfully!');
    } catch (error: any) {
      toast.error('Failed to save content: ' + error.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading || !content) {
    return (
      <div className="p-12 flex flex-col items-center justify-center min-h-[400px]">
        <RefreshCw className="w-8 h-8 text-[#F97316] animate-spin mb-3" />
        <p className="text-sm text-gray-500 font-medium">Loading CMS configuration...</p>
      </div>
    );
  }

  const livePageUrl =
    activeTab === 'home'
      ? '/'
      : activeTab === 'about'
      ? '/about'
      : activeTab === 'careers'
      ? '/careers'
      : activeTab === 'contact'
      ? '/contact'
      : activeTab === 'privacy'
      ? '/privacy'
      : '/';

  return (
    <div className="p-4 sm:p-8 max-w-7xl mx-auto space-y-6">
      {/* Top Header & Global Actions */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-gray-200 dark:border-white/10">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-[#0E0F13] dark:text-white">Content & Media CMS</h1>
            {hasUnsavedChanges && (
              <span className="text-xs bg-amber-500/10 text-amber-600 dark:text-amber-400 font-medium px-2.5 py-1 rounded-full border border-amber-500/20">
                Unsaved changes
              </span>
            )}
          </div>
          <p className="text-gray-500 dark:text-gray-400 text-xs sm:text-sm mt-1">
            Visually manage hero text, mockups, brand assets, services, and team details across public pages.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <Link
            href={livePageUrl}
            target="_blank"
            rel="noreferrer"
            className="px-3.5 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 flex items-center gap-2 transition shadow-xs"
          >
            <Eye className="w-4 h-4 text-[#F97316]" />
            <span>View Live Page</span>
            <ExternalLink className="w-3 h-3 text-gray-400" />
          </Link>

          <button
            type="button"
            onClick={fetchContent}
            className="px-3.5 py-2 text-xs font-semibold text-gray-700 dark:text-gray-300 bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 flex items-center gap-2 transition shadow-xs"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>Reload</span>
          </button>

          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="px-5 py-2 text-xs font-bold text-white bg-[#F97316] hover:bg-[#EA580C] rounded-xl flex items-center gap-2 transition disabled:opacity-50 shadow-md shadow-orange-500/20 cursor-pointer"
          >
            <Save className="w-4 h-4" />
            <span>{saving ? 'Saving...' : 'Save All Changes'}</span>
          </button>
        </div>
      </div>

      {/* Tabs Navigation */}
      <div className="flex overflow-x-auto gap-2 p-1.5 bg-gray-100/80 dark:bg-[#121317] rounded-2xl border border-gray-200/60 dark:border-white/10 scrollbar-none">
        <TabButton
          active={activeTab === 'home'}
          onClick={() => setActiveTab('home')}
          icon={<Home className="w-4 h-4" />}
          label="Home Page"
        />
        <TabButton
          active={activeTab === 'about'}
          onClick={() => setActiveTab('about')}
          icon={<Info className="w-4 h-4" />}
          label="About Us"
        />
        <TabButton
          active={activeTab === 'careers'}
          onClick={() => setActiveTab('careers')}
          icon={<Briefcase className="w-4 h-4" />}
          label="Careers"
        />
        <TabButton
          active={activeTab === 'contact'}
          onClick={() => setActiveTab('contact')}
          icon={<Phone className="w-4 h-4" />}
          label="Contact"
        />
        <TabButton
          active={activeTab === 'privacy'}
          onClick={() => setActiveTab('privacy')}
          icon={<Shield className="w-4 h-4" />}
          label="Privacy Policy"
        />
        <TabButton
          active={activeTab === 'media'}
          onClick={() => setActiveTab('media')}
          icon={<ImageIcon className="w-4 h-4" />}
          label="Media Sandbox"
        />
        <TabButton
          active={activeTab === 'raw'}
          onClick={() => setActiveTab('raw')}
          icon={<Code className="w-4 h-4" />}
          label="Raw JSON"
        />
      </div>

      {/* Tab Content Panels */}
      <div className="space-y-6">
        {activeTab === 'home' && (
          <HomeEditor content={content.home} updateField={(path, val) => updateContentField(['home', ...path], val)} />
        )}

        {activeTab === 'about' && (
          <AboutEditor content={content.about} updateField={(path, val) => updateContentField(['about', ...path], val)} />
        )}

        {activeTab === 'careers' && (
          <CareersEditor
            content={content.careers}
            updateField={(path, val) => updateContentField(['careers', ...path], val)}
          />
        )}

        {activeTab === 'contact' && (
          <ContactEditor
            content={content.contact}
            updateField={(path, val) => updateContentField(['contact', ...path], val)}
          />
        )}

        {activeTab === 'privacy' && (
          <PrivacyEditor
            content={content.privacy}
            updateField={(path, val) => updateContentField(['privacy', ...path], val)}
          />
        )}

        {activeTab === 'media' && <MediaSandbox />}

        {activeTab === 'raw' && (
          <div className="bg-white dark:bg-[#1A1B22] rounded-2xl border border-gray-200 dark:border-white/10 shadow-sm overflow-hidden flex flex-col h-[650px]">
            <div className="bg-gray-50 dark:bg-white/5 border-b border-gray-200 dark:border-white/10 px-4 py-2.5 flex items-center justify-between">
              <span className="text-xs font-mono text-gray-500 dark:text-gray-400">data/content.json (Raw Tree)</span>
              <span className="text-[11px] text-gray-400">Edit raw JSON directly with automatic validation</span>
            </div>
            <textarea
              value={rawJson}
              onChange={(e) => {
                setRawJson(e.target.value);
                setHasUnsavedChanges(true);
              }}
              className="flex-1 w-full p-4 font-mono text-xs sm:text-sm bg-transparent resize-none focus:outline-none focus:ring-2 focus:ring-inset focus:ring-[#F97316] text-gray-900 dark:text-gray-100"
              spellCheck={false}
            />
          </div>
        )}
      </div>
    </div>
  );
}

// Tab Button
function TabButton({
  active,
  onClick,
  icon,
  label,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
        active
          ? 'bg-white dark:bg-[#1A1B22] text-[#F97316] shadow-xs'
          : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-white/50 dark:hover:bg-white/5'
      }`}
    >
      {icon}
      <span>{label}</span>
    </button>
  );
}

// Collapsible Section Wrapper
function SectionCard({
  title,
  subtitle,
  children,
  badge,
}: {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  badge?: string;
}) {
  const [open, setOpen] = useState(true);

  return (
    <div className="bg-white dark:bg-[#1A1B22] rounded-2xl border border-gray-200 dark:border-white/10 shadow-xs overflow-hidden">
      <div
        onClick={() => setOpen(!open)}
        className="p-4 sm:p-5 flex items-center justify-between cursor-pointer bg-gray-50/50 dark:bg-white/[0.02] hover:bg-gray-50 dark:hover:bg-white/5 transition border-b border-gray-100 dark:border-white/5"
      >
        <div>
          <div className="flex items-center gap-2.5">
            <h2 className="font-bold text-[#0E0F13] dark:text-white text-base">{title}</h2>
            {badge && (
              <span className="text-[10px] font-semibold bg-orange-500/10 text-[#F97316] px-2 py-0.5 rounded-full border border-orange-500/20">
                {badge}
              </span>
            )}
          </div>
          {subtitle && <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{subtitle}</p>}
        </div>
        <button type="button" className="p-1 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
          {open ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
        </button>
      </div>

      {open && <div className="p-5 sm:p-6 space-y-5">{children}</div>}
    </div>
  );
}

// ==========================================
// HOME PAGE EDITOR
// ==========================================
function HomeEditor({ content, updateField }: { content: any; updateField: (path: string[], val: any) => void }) {
  if (!content) return null;

  return (
    <div className="space-y-6">
      {/* 1. Hero Section */}
      <SectionCard title="1. Hero Banner & Mockup" subtitle="The primary landing section above the fold" badge="High Impact">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Main Heading</label>
              <input
                type="text"
                value={content.hero?.heading || ''}
                onChange={(e) => updateField(['hero', 'heading'], e.target.value)}
                placeholder="Get Any Errand Done"
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">
                Accent Word (Orange Gradient)
              </label>
              <input
                type="text"
                value={content.hero?.headingAccent || ''}
                onChange={(e) => updateField(['hero', 'headingAccent'], e.target.value)}
                placeholder="Safely & Fast"
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none text-[#F97316] font-bold"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Description Subtitle</label>
              <textarea
                rows={3}
                value={content.hero?.description || ''}
                onChange={(e) => updateField(['hero', 'description'], e.target.value)}
                placeholder="Uyo's most reliable hyperlocal marketplace..."
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Badge Text</label>
                <input
                  type="text"
                  value={content.hero?.badge?.text || ''}
                  onChange={(e) => updateField(['hero', 'badge', 'text'], e.target.value)}
                  placeholder="Live in Uyo"
                  className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Trust Headline</label>
                <input
                  type="text"
                  value={content.hero?.trustText || ''}
                  onChange={(e) => updateField(['hero', 'trustText'], e.target.value)}
                  placeholder="Trusted by 10k+ Residents"
                  className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Primary CTA Label</label>
                <input
                  type="text"
                  value={content.hero?.ctaPrimary?.label || ''}
                  onChange={(e) => updateField(['hero', 'ctaPrimary', 'label'], e.target.value)}
                  placeholder="Post an Errand"
                  className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Secondary CTA Label</label>
                <input
                  type="text"
                  value={content.hero?.ctaSecondary?.label || ''}
                  onChange={(e) => updateField(['hero', 'ctaSecondary', 'label'], e.target.value)}
                  placeholder="Become a Runner"
                  className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl focus:ring-1 focus:ring-[#F97316] focus:outline-none"
                />
              </div>
            </div>
          </div>

          {/* Right Column: Hero Mockup Image */}
          <div className="space-y-4">
            <ImageUploadField
              label="Hero Phone Mockup Image"
              value={content.hero?.phoneImage || ''}
              onChange={(url) => updateField(['hero', 'phoneImage'], url)}
              description="Displayed in the 3D phone mockup container on the right side of the hero."
              aspectHint="Phone Mockup (3:4 or 9:16)"
            />

            {/* Trust Avatars List */}
            <div className="space-y-2 pt-2 border-t border-gray-100 dark:border-white/10">
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300">
                Trust Avatar Images ({content.hero?.trustAvatars?.length || 0})
              </label>
              <div className="space-y-2">
                {(content.hero?.trustAvatars || []).map((avatar: string, idx: number) => (
                  <div key={idx} className="flex items-center gap-2">
                    <img src={avatar} alt="Avatar" className="w-8 h-8 rounded-full object-cover border border-gray-300 shrink-0" />
                    <input
                      type="text"
                      value={avatar}
                      onChange={(e) => {
                        const newAvatars = [...content.hero.trustAvatars];
                        newAvatars[idx] = e.target.value;
                        updateField(['hero', 'trustAvatars'], newAvatars);
                      }}
                      className="flex-1 px-2.5 py-1 text-xs font-mono bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-lg"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        const newAvatars = content.hero.trustAvatars.filter((_: any, i: number) => i !== idx);
                        updateField(['hero', 'trustAvatars'], newAvatars);
                      }}
                      className="p-1 text-gray-400 hover:text-red-500 transition"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                ))}
                <button
                  type="button"
                  onClick={() => {
                    const newAvatars = [
                      ...(content.hero?.trustAvatars || []),
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuABkNl5SrB9YeKto4k8yycV_WnJVU07sTSUe3gCDdupkIew3kJEB5OG--KHFLZfkRIPnk8X6vUuqTH_mJKw8TIwUNPK6PNvgxCXNQsd75PzYG24Ci3oASPjWwMeMwo7NzWyqxsTiJbrZnj_pvjRdpz4WDrRFNt87BBS2xUteTLsbbMhaz_0_saQDL37LajsCZdaDSKuCfZnMeKKscITKElNA4w4p_8Wqw6XwiMwDa3IhwY5LPCPP5siUi45N5pd2YZt3iLKfjO9V8z1',
                    ];
                    updateField(['hero', 'trustAvatars'], newAvatars);
                  }}
                  className="px-3 py-1.5 text-xs text-[#F97316] font-semibold bg-orange-500/10 rounded-lg hover:bg-orange-500/20 flex items-center gap-1.5 transition"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Add Avatar URL</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </SectionCard>

      {/* 2. Platform Numbers / Stats */}
      <SectionCard title="2. Key Statistics Counters" subtitle="4 highlight metric values shown under the hero">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {(content.stats || []).map((stat: any, idx: number) => (
            <div key={idx} className="p-3 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-2">
              <label className="text-xs font-semibold text-gray-500">Stat #{idx + 1}</label>
              <input
                type="text"
                value={stat.value || ''}
                onChange={(e) => {
                  const newStats = [...content.stats];
                  newStats[idx].value = e.target.value;
                  updateField(['stats'], newStats);
                }}
                placeholder="10+"
                className="w-full px-3 py-1.5 text-base font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-[#F97316]"
              />
              <input
                type="text"
                value={stat.label || ''}
                onChange={(e) => {
                  const newStats = [...content.stats];
                  newStats[idx].label = e.target.value;
                  updateField(['stats'], newStats);
                }}
                placeholder="Errands Completed"
                className="w-full px-3 py-1.5 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
              />
            </div>
          ))}
        </div>
      </SectionCard>

      {/* 3. Services Offered */}
      <SectionCard
        title="3. Services Grid"
        subtitle="Offerings displayed on the home page with titles, descriptions, and icons"
      >
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Services Title</label>
              <input
                type="text"
                value={content.services?.heading || ''}
                onChange={(e) => updateField(['services', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Services Subtitle</label>
              <input
                type="text"
                value={content.services?.description || ''}
                onChange={(e) => updateField(['services', 'description'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {(content.services?.items || []).map((item: any, idx: number) => (
              <div
                key={idx}
                className="p-3 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-2 relative group"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      value={item.icon || ''}
                      onChange={(e) => {
                        const newItems = [...content.services.items];
                        newItems[idx].icon = e.target.value;
                        updateField(['services', 'items'], newItems);
                      }}
                      placeholder="Icon (e.g. package_2)"
                      className="w-32 px-2 py-1 text-xs font-mono bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-gray-500"
                    />
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      const newItems = content.services.items.filter((_: any, i: number) => i !== idx);
                      updateField(['services', 'items'], newItems);
                    }}
                    className="p-1 text-gray-400 hover:text-red-500 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <input
                  type="text"
                  value={item.title || ''}
                  onChange={(e) => {
                    const newItems = [...content.services.items];
                    newItems[idx].title = e.target.value;
                    updateField(['services', 'items'], newItems);
                  }}
                  placeholder="Service Title"
                  className="w-full px-2.5 py-1 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                />
                <textarea
                  rows={2}
                  value={item.desc || ''}
                  onChange={(e) => {
                    const newItems = [...content.services.items];
                    newItems[idx].desc = e.target.value;
                    updateField(['services', 'items'], newItems);
                  }}
                  placeholder="Short description of this service..."
                  className="w-full px-2.5 py-1 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                />
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              const newItems = [
                ...(content.services?.items || []),
                { icon: 'shopping_bag', title: 'New Service', desc: 'Description of the new errand service.' },
              ];
              updateField(['services', 'items'], newItems);
            }}
            className="px-4 py-2 text-xs font-semibold text-[#F97316] bg-orange-500/10 hover:bg-orange-500/20 rounded-xl flex items-center gap-1.5 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Service Card</span>
          </button>
        </div>
      </SectionCard>

      {/* 4. Customer Testimonials */}
      <SectionCard title="4. Testimonials & Social Proof" subtitle="Customer reviews featured on the homepage">
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Section Title</label>
            <input
              type="text"
              value={content.testimonials?.heading || ''}
              onChange={(e) => updateField(['testimonials', 'heading'], e.target.value)}
              className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {(content.testimonials?.items || []).map((item: any, idx: number) => (
              <div
                key={idx}
                className="p-4 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-3 relative group"
              >
                <div className="flex justify-between items-center">
                  <span className="text-xs font-bold text-gray-500">Review #{idx + 1}</span>
                  <button
                    type="button"
                    onClick={() => {
                      const newItems = content.testimonials.items.filter((_: any, i: number) => i !== idx);
                      updateField(['testimonials', 'items'], newItems);
                    }}
                    className="p-1 text-gray-400 hover:text-red-500 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <textarea
                  rows={4}
                  value={item.text || ''}
                  onChange={(e) => {
                    const newItems = [...content.testimonials.items];
                    newItems[idx].text = e.target.value;
                    updateField(['testimonials', 'items'], newItems);
                  }}
                  placeholder="Review quotation..."
                  className="w-full p-2 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg italic text-gray-700 dark:text-gray-300"
                />
                <div className="grid grid-cols-2 gap-2">
                  <input
                    type="text"
                    value={item.name || ''}
                    onChange={(e) => {
                      const newItems = [...content.testimonials.items];
                      newItems[idx].name = e.target.value;
                      updateField(['testimonials', 'items'], newItems);
                    }}
                    placeholder="Customer Name"
                    className="w-full px-2 py-1 text-xs font-semibold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                  <input
                    type="text"
                    value={item.role || ''}
                    onChange={(e) => {
                      const newItems = [...content.testimonials.items];
                      newItems[idx].role = e.target.value;
                      updateField(['testimonials', 'items'], newItems);
                    }}
                    placeholder="Role / Location"
                    className="w-full px-2 py-1 text-xs text-gray-500 bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                </div>
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              const newItems = [
                ...(content.testimonials?.items || []),
                {
                  text: 'Errand provided outstanding service and helped me with my daily tasks!',
                  name: 'Happy Customer',
                  role: 'Resident, Uyo',
                },
              ];
              updateField(['testimonials', 'items'], newItems);
            }}
            className="px-4 py-2 text-xs font-semibold text-[#F97316] bg-orange-500/10 hover:bg-orange-500/20 rounded-xl flex items-center gap-1.5 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Testimonial</span>
          </button>
        </div>
      </SectionCard>

      {/* 5. Navigation & Footer Brand */}
      <SectionCard title="5. Global Navigation & Footer Branding" subtitle="Logo, brand name, and copyright notice">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <ImageUploadField
              label="Platform Header & Footer Logo"
              value={content.nav?.logo || '/logo.png'}
              onChange={(url) => {
                updateField(['nav', 'logo'], url);
                updateField(['footer', 'logo'], url);
              }}
              description="PNG or SVG logo displayed across the top navbar and footer."
              aspectHint="Horizontal / Square Logo"
            />
          </div>
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Brand Name</label>
              <input
                type="text"
                value={content.nav?.brandName || 'Errand'}
                onChange={(e) => {
                  updateField(['nav', 'brandName'], e.target.value);
                  updateField(['footer', 'brandName'], e.target.value);
                }}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Footer Tagline</label>
              <input
                type="text"
                value={content.footer?.tagline || ''}
                onChange={(e) => updateField(['footer', 'tagline'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Copyright Template</label>
              <input
                type="text"
                value={content.footer?.copyright || '© {year} Errand. All rights reserved.'}
                onChange={(e) => updateField(['footer', 'copyright'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>
        </div>
      </SectionCard>
    </div>
  );
}

// ==========================================
// ABOUT US PAGE EDITOR
// ==========================================
function AboutEditor({ content, updateField }: { content: any; updateField: (path: string[], val: any) => void }) {
  if (!content) return null;

  return (
    <div className="space-y-6">
      {/* 1. Hero & Mission */}
      <SectionCard title="1. About Hero & Story" subtitle="Headline and story introducing Errand">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Story Badge</label>
              <input
                type="text"
                value={content.hero?.badge?.text || ''}
                onChange={(e) => updateField(['hero', 'badge', 'text'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Hero Heading</label>
              <input
                type="text"
                value={content.hero?.heading || ''}
                onChange={(e) => updateField(['hero', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Story Narrative</label>
              <textarea
                rows={4}
                value={content.hero?.description || ''}
                onChange={(e) => updateField(['hero', 'description'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Mission Heading</label>
              <input
                type="text"
                value={content.mission?.heading || ''}
                onChange={(e) => updateField(['mission', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Mission Statement</label>
              <textarea
                rows={3}
                value={content.mission?.description || ''}
                onChange={(e) => updateField(['mission', 'description'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <ImageUploadField
              label="Mission & Team Photo"
              value={content.mission?.image || ''}
              onChange={(url) => updateField(['mission', 'image'], url)}
              description="High resolution photo representing the Errand team or operations."
              aspectHint="Landscape (16:9)"
            />
          </div>
        </div>
      </SectionCard>

      {/* 2. Core Values */}
      <SectionCard title="2. Core Values" subtitle="The 4 guiding principles of Errand">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {(content.values?.items || []).map((val: any, idx: number) => (
            <div key={idx} className="p-3 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-2">
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={val.icon || ''}
                  onChange={(e) => {
                    const newVals = [...content.values.items];
                    newVals[idx].icon = e.target.value;
                    updateField(['values', 'items'], newVals);
                  }}
                  placeholder="icon"
                  className="w-24 px-2 py-1 text-xs font-mono bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-gray-500"
                />
                <input
                  type="text"
                  value={val.title || ''}
                  onChange={(e) => {
                    const newVals = [...content.values.items];
                    newVals[idx].title = e.target.value;
                    updateField(['values', 'items'], newVals);
                  }}
                  placeholder="Value Title"
                  className="flex-1 px-2.5 py-1 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                />
              </div>
              <textarea
                rows={2}
                value={val.description || ''}
                onChange={(e) => {
                  const newVals = [...content.values.items];
                  newVals[idx].description = e.target.value;
                  updateField(['values', 'items'], newVals);
                }}
                placeholder="Description of this value..."
                className="w-full px-2.5 py-1 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
              />
            </div>
          ))}
        </div>
      </SectionCard>

      {/* 3. Leadership & Team Members */}
      <SectionCard title="3. Leadership & Team Members" subtitle="Profiles shown in the Meet the Team section">
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {(content.team?.members || []).map((m: any, idx: number) => (
              <div
                key={idx}
                className="p-4 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-3 relative group"
              >
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-gray-500">Member #{idx + 1}</span>
                  <button
                    type="button"
                    onClick={() => {
                      const newMembers = content.team.members.filter((_: any, i: number) => i !== idx);
                      updateField(['team', 'members'], newMembers);
                    }}
                    className="p-1 text-gray-400 hover:text-red-500 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <input
                    type="text"
                    value={m.name || ''}
                    onChange={(e) => {
                      const newMembers = [...content.team.members];
                      newMembers[idx].name = e.target.value;
                      updateField(['team', 'members'], newMembers);
                    }}
                    placeholder="Full Name / Title"
                    className="w-full px-3 py-1.5 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                  <input
                    type="text"
                    value={m.icon || 'person'}
                    onChange={(e) => {
                      const newMembers = [...content.team.members];
                      newMembers[idx].icon = e.target.value;
                      updateField(['team', 'members'], newMembers);
                    }}
                    placeholder="Icon (code, person, etc.)"
                    className="w-full px-3 py-1.5 text-xs font-mono bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-gray-500"
                  />
                </div>

                <textarea
                  rows={2}
                  value={m.role || ''}
                  onChange={(e) => {
                    const newMembers = [...content.team.members];
                    newMembers[idx].role = e.target.value;
                    updateField(['team', 'members'], newMembers);
                  }}
                  placeholder="Role description or title..."
                  className="w-full px-3 py-1.5 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                />

                <ImageUploadField
                  label="Member Headshot Photo"
                  value={m.image || ''}
                  onChange={(url) => {
                    const newMembers = [...content.team.members];
                    newMembers[idx].image = url;
                    updateField(['team', 'members'], newMembers);
                  }}
                  aspectHint="Square / Portrait"
                />
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              const newMembers = [
                ...(content.team?.members || []),
                { name: 'Team Member', role: 'Role description', image: '', icon: 'person' },
              ];
              updateField(['team', 'members'], newMembers);
            }}
            className="px-4 py-2 text-xs font-semibold text-[#F97316] bg-orange-500/10 hover:bg-orange-500/20 rounded-xl flex items-center gap-1.5 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Team Member</span>
          </button>
        </div>
      </SectionCard>
    </div>
  );
}

// ==========================================
// CAREERS PAGE EDITOR
// ==========================================
function CareersEditor({ content, updateField }: { content: any; updateField: (path: string[], val: any) => void }) {
  if (!content) return null;

  return (
    <div className="space-y-6">
      <SectionCard title="1. Careers Hero & Culture" subtitle="Headline and culture photo for recruitment">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Badge Text</label>
              <input
                type="text"
                value={content.hero?.badge?.text || ''}
                onChange={(e) => updateField(['hero', 'badge', 'text'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Headline</label>
              <input
                type="text"
                value={content.hero?.heading || ''}
                onChange={(e) => updateField(['hero', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Description</label>
              <textarea
                rows={3}
                value={content.hero?.description || ''}
                onChange={(e) => updateField(['hero', 'description'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>

          <div className="space-y-4">
            <ImageUploadField
              label="Culture & Team Photo"
              value={content.culture?.image || ''}
              onChange={(url) => updateField(['culture', 'image'], url)}
              description="Photo displayed in the culture section showing the team in action."
              aspectHint="Landscape (16:9)"
            />
          </div>
        </div>
      </SectionCard>

      <SectionCard title="2. Open Job Roles" subtitle="List of positions available on the careers page">
        <div className="space-y-4">
          <div className="space-y-3">
            {(content.openRoles?.roles || []).map((r: any, idx: number) => (
              <div
                key={idx}
                className="p-3 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl grid grid-cols-1 sm:grid-cols-4 gap-3 items-center"
              >
                <div className="sm:col-span-2">
                  <input
                    type="text"
                    value={r.title || ''}
                    onChange={(e) => {
                      const newRoles = [...content.openRoles.roles];
                      newRoles[idx].title = e.target.value;
                      updateField(['openRoles', 'roles'], newRoles);
                    }}
                    placeholder="Job Title (e.g. Operations Manager)"
                    className="w-full px-3 py-1.5 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                </div>
                <div>
                  <input
                    type="text"
                    value={r.location || ''}
                    onChange={(e) => {
                      const newRoles = [...content.openRoles.roles];
                      newRoles[idx].location = e.target.value;
                      updateField(['openRoles', 'roles'], newRoles);
                    }}
                    placeholder="Location"
                    className="w-full px-3 py-1.5 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                </div>
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={r.compensation || ''}
                    onChange={(e) => {
                      const newRoles = [...content.openRoles.roles];
                      newRoles[idx].compensation = e.target.value;
                      updateField(['openRoles', 'roles'], newRoles);
                    }}
                    placeholder="Compensation"
                    className="w-full px-3 py-1.5 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const newRoles = content.openRoles.roles.filter((_: any, i: number) => i !== idx);
                      updateField(['openRoles', 'roles'], newRoles);
                    }}
                    className="p-1.5 text-gray-400 hover:text-red-500 transition shrink-0"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              const newRoles = [
                ...(content.openRoles?.roles || []),
                {
                  title: 'New Position',
                  type: 'Full-time',
                  typeColor: 'orange',
                  location: 'Uyo, AK',
                  locationIcon: 'location_on',
                  compensation: 'Competitive',
                  compensationIcon: 'payments',
                },
              ];
              updateField(['openRoles', 'roles'], newRoles);
            }}
            className="px-4 py-2 text-xs font-semibold text-[#F97316] bg-orange-500/10 hover:bg-orange-500/20 rounded-xl flex items-center gap-1.5 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Open Role</span>
          </button>
        </div>
      </SectionCard>
    </div>
  );
}

// ==========================================
// CONTACT US PAGE EDITOR
// ==========================================
function ContactEditor({ content, updateField }: { content: any; updateField: (path: string[], val: any) => void }) {
  if (!content) return null;

  return (
    <div className="space-y-6">
      <SectionCard title="1. Contact Information & Office Details" subtitle="Phone lines, email addresses, and headquarters">
        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Headline</label>
              <input
                type="text"
                value={content.hero?.heading || ''}
                onChange={(e) => updateField(['hero', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Subtitle</label>
              <input
                type="text"
                value={content.hero?.description || ''}
                onChange={(e) => updateField(['hero', 'description'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            {(content.contactInfo?.items || []).map((item: any, idx: number) => (
              <div key={idx} className="p-3 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-2">
                <input
                  type="text"
                  value={item.title || ''}
                  onChange={(e) => {
                    const newItems = [...content.contactInfo.items];
                    newItems[idx].title = e.target.value;
                    updateField(['contactInfo', 'items'], newItems);
                  }}
                  className="w-full px-2.5 py-1 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-[#F97316]"
                />
                <textarea
                  rows={3}
                  value={(item.details || []).join('\n')}
                  onChange={(e) => {
                    const newItems = [...content.contactInfo.items];
                    newItems[idx].details = e.target.value.split('\n');
                    updateField(['contactInfo', 'items'], newItems);
                  }}
                  placeholder="One detail per line..."
                  className="w-full px-2.5 py-1 text-xs font-mono bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                />
              </div>
            ))}
          </div>
        </div>
      </SectionCard>
    </div>
  );
}

// ==========================================
// PRIVACY & TERMS EDITOR
// ==========================================
function PrivacyEditor({ content, updateField }: { content: any; updateField: (path: string[], val: any) => void }) {
  if (!content) return null;

  return (
    <div className="space-y-6">
      <SectionCard title="1. Privacy Policy Document" subtitle="Manage policy sections, legal clauses, and update dates">
        <div className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Policy Title</label>
              <input
                type="text"
                value={content.hero?.heading || ''}
                onChange={(e) => updateField(['hero', 'heading'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-700 dark:text-gray-300 mb-1">Effective Date</label>
              <input
                type="text"
                value={content.hero?.lastUpdated || ''}
                onChange={(e) => updateField(['hero', 'lastUpdated'], e.target.value)}
                className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl"
              />
            </div>
          </div>

          <div className="space-y-4 pt-2">
            {(content.sections || []).map((sec: any, idx: number) => (
              <div key={idx} className="p-4 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-2">
                <div className="flex items-center justify-between">
                  <input
                    type="text"
                    value={sec.title || ''}
                    onChange={(e) => {
                      const newSecs = [...content.sections];
                      newSecs[idx].title = e.target.value;
                      updateField(['sections'], newSecs);
                    }}
                    placeholder="Section Title"
                    className="w-full max-w-md px-3 py-1.5 text-xs font-bold bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg"
                  />
                  <button
                    type="button"
                    onClick={() => {
                      const newSecs = content.sections.filter((_: any, i: number) => i !== idx);
                      updateField(['sections'], newSecs);
                    }}
                    className="p-1 text-gray-400 hover:text-red-500 transition"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
                <textarea
                  rows={4}
                  value={sec.content || ''}
                  onChange={(e) => {
                    const newSecs = [...content.sections];
                    newSecs[idx].content = e.target.value;
                    updateField(['sections'], newSecs);
                  }}
                  placeholder="Section body content..."
                  className="w-full p-3 text-xs bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded-lg text-gray-700 dark:text-gray-300"
                />
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={() => {
              const newSecs = [
                ...(content.sections || []),
                { title: 'New Clause', content: 'Description of the policy terms.' },
              ];
              updateField(['sections'], newSecs);
            }}
            className="px-4 py-2 text-xs font-semibold text-[#F97316] bg-orange-500/10 hover:bg-orange-500/20 rounded-xl flex items-center gap-1.5 transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Policy Clause</span>
          </button>
        </div>
      </SectionCard>
    </div>
  );
}

// ==========================================
// MEDIA SANDBOX & QUICK UPLOADER
// ==========================================
function MediaSandbox() {
  const [uploadedUrls, setUploadedUrls] = useState<string[]>([]);
  const [currentUrl, setCurrentUrl] = useState<string>('');

  return (
    <div className="space-y-6">
      <SectionCard
        title="Media Sandbox & Asset Uploader"
        subtitle="Quickly upload banners, illustrations, or mockups directly to persistent storage"
      >
        <div className="max-w-xl space-y-4">
          <ImageUploadField
            label="Upload Asset to CMS Storage"
            value={currentUrl}
            onChange={(url) => {
              setCurrentUrl(url);
              if (url && !uploadedUrls.includes(url)) {
                setUploadedUrls((prev) => [url, ...prev]);
              }
            }}
            description="Images uploaded here are stored permanently on the storage server with full HTTPS links ready to paste anywhere."
          />
        </div>

        {uploadedUrls.length > 0 && (
          <div className="pt-4 border-t border-gray-100 dark:border-white/10 space-y-3">
            <h3 className="text-xs font-bold text-gray-700 dark:text-gray-300">Recently Uploaded in This Session:</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {uploadedUrls.map((url, i) => (
                <div key={i} className="p-2 bg-gray-50 dark:bg-[#121317] border border-gray-200 dark:border-white/10 rounded-xl space-y-1.5">
                  <img src={url} alt="Uploaded" className="w-full h-24 object-cover rounded-lg" />
                  <input
                    readOnly
                    value={url}
                    onClick={(e) => {
                      (e.target as HTMLInputElement).select();
                      navigator.clipboard.writeText(url);
                      toast.success('Copied URL!');
                    }}
                    className="w-full text-[10px] font-mono px-2 py-1 bg-white dark:bg-[#1A1B22] border border-gray-200 dark:border-white/10 rounded cursor-pointer"
                  />
                </div>
              ))}
            </div>
          </div>
        )}
      </SectionCard>
    </div>
  );
}
