import { promises as fs } from 'fs';
import path from 'path';
import { DEFAULT_CONTENT } from './defaultContent';

export type CMSContent = Record<string, any>;

const DATA_PATH = path.join(process.cwd(), 'data', 'content.json');

// In-memory cache fallback to ensure instant, fail-safe reads
let inMemoryContent: CMSContent | null = null;

/**
 * Read the full CMS content.
 * Guarantees a valid CMSContent object is returned even if the disk file
 * is temporarily busy, missing, or corrupt.
 */
export async function getContent(): Promise<CMSContent> {
  try {
    const raw = await fs.readFile(DATA_PATH, 'utf-8');
    const parsed = JSON.parse(raw);
    inMemoryContent = parsed;
    return parsed;
  } catch (error: any) {
    // If file doesn't exist, seed it with DEFAULT_CONTENT
    if (error?.code === 'ENOENT') {
      try {
        await fs.mkdir(path.dirname(DATA_PATH), { recursive: true });
        await fs.writeFile(DATA_PATH, JSON.stringify(DEFAULT_CONTENT, null, 2), 'utf-8');
      } catch (writeErr) {
        console.warn('Could not auto-seed content.json to disk:', writeErr);
      }
      inMemoryContent = JSON.parse(JSON.stringify(DEFAULT_CONTENT));
      return inMemoryContent!;
    }

    console.warn('CMS read error, falling back to in-memory/default content:', error?.message);
    if (inMemoryContent) {
      return inMemoryContent;
    }
    inMemoryContent = JSON.parse(JSON.stringify(DEFAULT_CONTENT));
    return inMemoryContent!;
  }
}

/**
 * Read content for a specific page safely.
 */
export async function getPageContent<T = any>(page: string): Promise<T> {
  const content = await getContent();
  return (content[page] || (DEFAULT_CONTENT as any)[page]) as T;
}

/**
 * Atomically write CMS content to disk to prevent partial read race conditions.
 */
async function atomicWriteFile(filepath: string, data: string): Promise<void> {
  const dir = path.dirname(filepath);
  await fs.mkdir(dir, { recursive: true });
  const tmpPath = `${filepath}.tmp.${Date.now()}.${Math.random().toString(36).slice(2)}`;
  await fs.writeFile(tmpPath, data, 'utf-8');
  await fs.rename(tmpPath, filepath);
}

/**
 * Update CMS content. Merges at the top level (page key).
 * Pass the full content object to overwrite everything,
 * or a partial with specific page keys to merge.
 */
export async function updateContent(updates: CMSContent): Promise<CMSContent> {
  const current = await getContent();
  const merged = { ...current, ...updates };
  inMemoryContent = merged;

  try {
    await atomicWriteFile(DATA_PATH, JSON.stringify(merged, null, 2));
  } catch (err) {
    console.error('Failed to write CMS content to disk:', err);
  }

  return merged;
}

/**
 * Update a single page's content atomically.
 */
export async function updatePageContent(page: string, data: any): Promise<CMSContent> {
  const current = await getContent();
  const updated = { ...current, [page]: data };
  inMemoryContent = updated;

  try {
    await atomicWriteFile(DATA_PATH, JSON.stringify(updated, null, 2));
  } catch (err) {
    console.error('Failed to write single page content to disk:', err);
  }

  return updated;
}
