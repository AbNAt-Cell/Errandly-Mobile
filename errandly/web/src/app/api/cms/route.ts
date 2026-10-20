import { revalidatePath } from 'next/cache';
import { getContent, updateContent, updatePageContent } from '@/lib/cms';
import { DEFAULT_CONTENT } from '@/lib/defaultContent';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function GET() {
  try {
    const content = await getContent();
    return new Response(JSON.stringify(content), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    });
  } catch (error) {
    console.error('Failed to get CMS content, returning fallback:', error);
    return new Response(JSON.stringify(DEFAULT_CONTENT), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      },
    });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    let updated;
    // If updating a specific page
    if (body.page && body.data) {
      updated = await updatePageContent(body.page, body.data);
    } else {
      // Otherwise update top level
      updated = await updateContent(body);
    }

    // Trigger instant cache revalidation for all public pages
    try {
      revalidatePath('/', 'layout');
      revalidatePath('/');
      revalidatePath('/about');
      revalidatePath('/careers');
      revalidatePath('/contact');
      revalidatePath('/privacy');
    } catch (e) {
      console.warn('Revalidation notice:', e);
    }

    return new Response(JSON.stringify(updated), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    });
  } catch (error: any) {
    console.error('Failed to update CMS content:', error);
    return new Response(JSON.stringify({ error: error?.message || 'Failed to update content' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
