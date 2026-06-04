import { redirect } from 'next/navigation';

export default function RunnerVerifyRedirect() {
  redirect('/auth/verify-phone?role=runner');
}
