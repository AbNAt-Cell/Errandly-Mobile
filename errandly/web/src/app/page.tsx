import Link from 'next/link';
import { Shield, Zap, MapPin, Star, Users, Package, ArrowRight, CheckCircle, Phone } from 'lucide-react';

const features = [
  { icon: Shield, title: 'Verified Runners', desc: 'Every runner passes full KYC verification and background checks before joining.' },
  { icon: Zap, title: 'Fast Matching', desc: 'Our smart system finds the nearest verified runner for your errand in minutes.' },
  { icon: MapPin, title: 'Live Tracking', desc: 'Track your runner in real-time from pickup to delivery on an interactive map.' },
  { icon: Star, title: 'Trust Score System', desc: 'Runners are ranked by trust score, ratings, and completion history.' },
];

const categories = [
  { emoji: '📦', label: 'Package Pickup' },
  { emoji: '🛒', label: 'Grocery Purchase' },
  { emoji: '📄', label: 'Document Submission' },
  { emoji: '💊', label: 'Prescription Pickup' },
  { emoji: '🏃', label: 'Queue Standing' },
  { emoji: '🛍️', label: 'Shopping Assistance' },
  { emoji: '🚗', label: 'Item Delivery' },
  { emoji: '✨', label: 'Custom Errand' },
];

const steps = [
  { step: '1', title: 'Post Your Errand', desc: 'Describe your task, set a budget, and choose pickup/destination locations.' },
  { step: '2', title: 'Runner Accepts', desc: 'A verified nearby runner accepts your errand and heads to pickup.' },
  { step: '3', title: 'Track Live', desc: 'Monitor progress in real-time with live GPS tracking and in-app chat.' },
  { step: '4', title: 'Confirm & Pay', desc: 'Verify delivery with OTP, confirm completion, and payment releases automatically.' },
];

const testimonials = [
  { name: 'Adaeze O.', role: 'Business Owner, Uyo', rating: 5, text: 'Errandly saved my business. I can now send documents across Uyo without leaving my office. The runners are professional and trustworthy.' },
  { name: 'Chidi M.', role: 'Student, Ewet Housing', rating: 5, text: 'I use Errandly weekly for grocery runs. The live tracking gives me peace of mind and the prices are fair.' },
  { name: 'Emem A.', role: 'Runner, Ikot Ekpene Road', rating: 5, text: 'I earn ₦80,000+ monthly as a runner. The app is easy to use and payments are always on time.' },
];

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white">
      {/* Nav */}
      <nav className="sticky top-0 z-50 bg-white/95 backdrop-blur border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-[#FF6B00] rounded-lg flex items-center justify-center">
                <Package className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold text-[#0A1628]">Errandly</span>
            </div>
            <div className="hidden md:flex items-center gap-8">
              <Link href="#how-it-works" className="text-gray-600 hover:text-[#FF6B00] transition-colors">How it works</Link>
              <Link href="#categories" className="text-gray-600 hover:text-[#FF6B00] transition-colors">Services</Link>
              <Link href="/become-a-runner" className="text-gray-600 hover:text-[#FF6B00] transition-colors">Become a Runner</Link>
              <Link href="/auth/login" className="text-gray-600 hover:text-[#FF6B00] transition-colors">Login</Link>
              <Link href="/auth/register" className="errandly-btn-primary text-sm px-5 py-2">Get Started</Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="errandly-hero-gradient text-white pt-20 pb-32 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-10 left-10 w-72 h-72 bg-[#FF6B00] rounded-full blur-3xl" />
          <div className="absolute bottom-10 right-10 w-96 h-96 bg-[#FF8C3A] rounded-full blur-3xl" />
        </div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
          <div className="max-w-3xl">
            <div className="inline-flex items-center gap-2 bg-[#FF6B00]/20 border border-[#FF6B00]/30 rounded-full px-4 py-2 text-sm text-[#FF8C3A] mb-6">
              <Shield className="w-4 h-4" />
              <span>Fully verified runners — your safety is our priority</span>
            </div>
            <h1 className="text-5xl md:text-6xl font-bold leading-tight mb-6">
              Get Any Errand Done,{' '}
              <span className="text-[#FF6B00]">Safely & Fast</span>
            </h1>
            <p className="text-xl text-gray-300 mb-10 leading-relaxed">
              Connect with verified local runners in your neighborhood. From grocery runs to document submissions — Errandly handles it all with real-time tracking and escrow-secured payments.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Link href="/auth/register" className="errandly-btn-primary text-center text-lg px-8 py-4">
                Post an Errand
              </Link>
              <Link href="/become-a-runner" className="errandly-btn-secondary text-center text-lg px-8 py-4 bg-transparent border-white text-white hover:bg-white/10">
                Become a Runner
              </Link>
            </div>
            <div className="flex items-center gap-8 mt-12 text-sm text-gray-400">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-[#FF6B00]" />
                <span>KYC Verified Runners</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-[#FF6B00]" />
                <span>Escrow-Secured Payments</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-[#FF6B00]" />
                <span>Live GPS Tracking</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="bg-[#FF6B00] py-10">
        <div className="max-w-7xl mx-auto px-4 grid grid-cols-2 md:grid-cols-4 gap-6 text-center text-white">
          {[
            { value: '10,000+', label: 'Errands Completed' },
            { value: '2,500+', label: 'Verified Runners' },
            { value: '4.8/5', label: 'Average Rating' },
            { value: '5 Areas', label: 'Uyo, Akwa Ibom' },
          ].map((stat) => (
            <div key={stat.label}>
              <div className="text-3xl font-bold">{stat.value}</div>
              <div className="text-orange-200 text-sm mt-1">{stat.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Categories */}
      <section id="categories" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-[#0A1628] mb-4">What Can We Help With?</h2>
            <p className="text-gray-500 text-lg max-w-2xl mx-auto">From simple pickups to complex errands, our runners handle it all.</p>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {categories.map((cat) => (
              <div key={cat.label} className="errandly-card hover:border-[#FF6B00] hover:shadow-md transition-all cursor-pointer text-center">
                <div className="text-4xl mb-3">{cat.emoji}</div>
                <div className="font-medium text-[#0A1628]">{cat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section id="how-it-works" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-[#0A1628] mb-4">How Errandly Works</h2>
            <p className="text-gray-500 text-lg">Simple, safe, and fast — in 4 steps.</p>
          </div>
          <div className="grid md:grid-cols-4 gap-8">
            {steps.map((step, idx) => (
              <div key={step.step} className="relative text-center">
                {idx < steps.length - 1 && (
                  <div className="hidden md:block absolute top-6 left-1/2 w-full h-0.5 bg-orange-100 z-0" />
                )}
                <div className="relative z-10 w-12 h-12 bg-[#FF6B00] text-white rounded-full flex items-center justify-center text-xl font-bold mx-auto mb-4">
                  {step.step}
                </div>
                <h3 className="font-bold text-[#0A1628] mb-2">{step.title}</h3>
                <p className="text-gray-500 text-sm">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-[#0A1628] text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold mb-4">Built for <span className="text-[#FF6B00]">Safety First</span></h2>
            <p className="text-gray-400 text-lg">Every feature designed to protect you and earn your trust.</p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((f) => (
              <div key={f.title} className="bg-[#1A2E4A] rounded-2xl p-6 hover:bg-[#223550] transition-colors">
                <div className="w-12 h-12 bg-[#FF6B00]/20 rounded-xl flex items-center justify-center mb-4">
                  <f.icon className="w-6 h-6 text-[#FF6B00]" />
                </div>
                <h3 className="font-bold text-lg mb-2">{f.title}</h3>
                <p className="text-gray-400 text-sm leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-[#0A1628] mb-4">What People Say</h2>
          </div>
          <div className="grid md:grid-cols-3 gap-6">
            {testimonials.map((t) => (
              <div key={t.name} className="errandly-card">
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: t.rating }).map((_, i) => (
                    <Star key={i} className="w-4 h-4 fill-[#FF6B00] text-[#FF6B00]" />
                  ))}
                </div>
                <p className="text-gray-600 mb-4 italic">"{t.text}"</p>
                <div>
                  <div className="font-semibold text-[#0A1628]">{t.name}</div>
                  <div className="text-sm text-gray-500">{t.role}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="errandly-gradient py-20 text-white text-center">
        <div className="max-w-3xl mx-auto px-4">
          <h2 className="text-4xl font-bold mb-4">Ready to Get Started?</h2>
          <p className="text-orange-100 text-lg mb-10">Join thousands of people who trust Errandly for their everyday tasks.</p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/auth/register" className="bg-white text-[#FF6B00] font-bold px-8 py-4 rounded-xl hover:bg-orange-50 transition-colors">
              Post Your First Errand
            </Link>
            <Link href="/become-a-runner" className="border-2 border-white text-white font-bold px-8 py-4 rounded-xl hover:bg-white/10 transition-colors">
              Become a Runner
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-[#0A1628] text-gray-400 py-12">
        <div className="max-w-7xl mx-auto px-4 grid md:grid-cols-4 gap-8">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-[#FF6B00] rounded-lg flex items-center justify-center">
                <Package className="w-5 h-5 text-white" />
              </div>
              <span className="text-white font-bold text-lg">Errandly</span>
            </div>
            <p className="text-sm">Nigeria's most trusted hyperlocal errand marketplace.</p>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-4">Company</h4>
            <div className="space-y-2 text-sm">
              <Link href="/about" className="block hover:text-[#FF6B00] transition-colors">About Us</Link>
              <Link href="/contact" className="block hover:text-[#FF6B00] transition-colors">Contact</Link>
              <Link href="/careers" className="block hover:text-[#FF6B00] transition-colors">Careers</Link>
            </div>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-4">Services</h4>
            <div className="space-y-2 text-sm">
              <Link href="/become-a-runner" className="block hover:text-[#FF6B00] transition-colors">Become a Runner</Link>
              <Link href="/auth/register" className="block hover:text-[#FF6B00] transition-colors">Post an Errand</Link>
              <Link href="/admin" className="block hover:text-[#FF6B00] transition-colors">Admin Portal</Link>
            </div>
          </div>
          <div>
            <h4 className="text-white font-semibold mb-4">Support</h4>
            <div className="space-y-2 text-sm">
              <div className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-[#FF6B00]" />
                <span>+234 900 000 0000</span>
              </div>
              <a href="mailto:support@errandly.com" className="block hover:text-[#FF6B00] transition-colors">support@errandly.com</a>
            </div>
          </div>
        </div>
        <div className="max-w-7xl mx-auto px-4 mt-8 pt-8 border-t border-gray-800 text-sm text-center">
          © {new Date().getFullYear()} Errandly. All rights reserved.
        </div>
      </footer>
    </div>
  );
}
