import { promises as fs } from 'fs';
import path from 'path';
import { unstable_noStore as noStore } from 'next/cache';

export type CMSContent = Record<string, any>;

const DATA_PATH = path.join(process.cwd(), 'data', 'content.json');

/**
 * Read the full CMS content from the JSON file.
 */
export async function getContent(): Promise<CMSContent> {
  try {
    noStore();
  } catch {
    // outside request context
  }
  const raw = await fs.readFile(DATA_PATH, 'utf-8');
  return JSON.parse(raw);
}

/**
 * Read content for a specific page.
 */
export async function getPageContent<T = any>(page: string): Promise<T> {
  const content = await getContent();
  return content[page] as T;
}

/**
 * Update CMS content. Merges at the top level (page key).
 * Pass the full content object to overwrite everything,
 * or a partial with specific page keys to merge.
 */
export async function updateContent(updates: CMSContent): Promise<CMSContent> {
  const current = await getContent();
  const merged = { ...current, ...updates };
  await fs.mkdir(path.dirname(DATA_PATH), { recursive: true });
  await fs.writeFile(DATA_PATH, JSON.stringify(merged, null, 2), 'utf-8');
  return merged;
}

/**
 * Update a single page's content.
 */
export async function updatePageContent(page: string, data: any): Promise<CMSContent> {
  const current = await getContent();
  current[page] = data;
  await fs.mkdir(path.dirname(DATA_PATH), { recursive: true });
  await fs.writeFile(DATA_PATH, JSON.stringify(current, null, 2), 'utf-8');
  return current;
}
