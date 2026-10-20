import { NextResponse } from 'next/server';
import { revalidatePath } from 'next/cache';
import { getContent, updateContent, updatePageContent } from '@/lib/cms';

export async function GET() {
  try {
    const content = await getContent();
    return NextResponse.json(content);
  } catch (error) {
    console.error('Failed to get CMS content:', error);
    return NextResponse.json({ error: 'Failed to read content' }, { status: 500 });
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

    return NextResponse.json(updated);
  } catch (error) {
    console.error('Failed to update CMS content:', error);
    return NextResponse.json({ error: 'Failed to update content' }, { status: 500 });
  }
}
