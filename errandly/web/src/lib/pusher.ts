import Pusher from 'pusher-js';

let client: Pusher | null = null;

export function getPusherClient(): Pusher | null {
  const key = process.env.NEXT_PUBLIC_PUSHER_APP_KEY || process.env.NEXT_PUBLIC_PUSHER_KEY;
  if (!key || typeof window === 'undefined') return null;

  if (!client) {
    client = new Pusher(key, {
      cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER || 'mt1',
      forceTLS: (process.env.NEXT_PUBLIC_PUSHER_SCHEME || 'https') === 'https',
    });
  }
  return client;
}

export function subscribeErrandChannel(
  errandId: number | string,
  onEvent: (event: string, data: unknown) => void
): (() => void) | null {
  const pusher = getPusherClient();
  if (!pusher) return null;

  const channel = pusher.subscribe(`errand.${errandId}`);
  const handlers: Array<{ name: string; fn: (d: unknown) => void }> = [
    { name: 'ErrandStatusUpdated', fn: (d) => onEvent('ErrandStatusUpdated', d) },
    { name: 'RunnerLocationUpdated', fn: (d) => onEvent('RunnerLocationUpdated', d) },
    { name: 'NewMessage', fn: (d) => onEvent('NewMessage', d) },
    { name: 'PanicTriggered', fn: (d) => onEvent('PanicTriggered', d) },
  ];

  handlers.forEach(({ name, fn }) => channel.bind(name, fn));

  return () => {
    handlers.forEach(({ name, fn }) => channel.unbind(name, fn));
    pusher.unsubscribe(`errand.${errandId}`);
  };
}
