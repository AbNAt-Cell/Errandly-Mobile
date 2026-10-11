export default function Loading() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0E0F13]">
      <div className="text-center">
        <div className="w-12 h-12 border-4 border-[#F97316] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
        <p className="text-[#e0c0b1] font-['Bricolage_Grotesque'] font-bold text-lg">Loading Errand…</p>
      </div>
    </div>
  );
}
