export default function Loading() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-white">
      <div className="text-center">
        <div className="w-10 h-10 border-4 border-[#FF6B00] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
        <p className="text-[#0A1628] font-medium">Loading Errandly…</p>
      </div>
    </div>
  );
}
