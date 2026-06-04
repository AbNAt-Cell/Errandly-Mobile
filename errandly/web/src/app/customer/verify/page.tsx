import { redirect } from 'next/navigation';

export default function CustomerVerifyRedirect() {
  redirect('/auth/verify-phone?role=customer');
}
