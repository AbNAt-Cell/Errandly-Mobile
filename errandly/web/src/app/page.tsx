'use client';

import { LandingDesktop } from '@/components/landing/LandingDesktop';
import { LandingMobile } from '@/components/landing/LandingMobile';

export default function LandingPage() {
  return (
    <>
      <LandingMobile />
      <LandingDesktop />
    </>
  );
}
