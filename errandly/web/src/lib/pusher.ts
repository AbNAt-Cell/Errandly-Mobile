import Pusher from 'pusher-js';

let client: Pusher | null = null;

export function getPusherClient(): Pusher | null {
  const key = process.env.NEXT_PUBLIC_PUSHER_APP_KEY || process.env.NEXT_PUBLIC_PUSHER_KEY;
  if (!key || typeof window === 'undefined') return null;

  if (!client) {
    if (typeof window !== 'undefined') {
      Pusher.logToConsole = true;
    }
    client = new Pusher(key, {
      cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER || 'us3',
      forceTLS: (process.env.NEXT_PUBLIC_PUSHER_SCHEME || 'https') === 'https',
    });

    client.connection.bind('state_change', (states: { current: string; previous: string }) => {
      console.log(`[Pusher] State: ${states.previous} -> ${states.current}`);
    });

    client.connection.bind('error', (err: any) => {
      console.error('[Pusher] Connection error:', err);
    });
  }
  return client;
}

type CallEventListener = (eventName: string, data: any) => void;
const callEventListeners = new Set<CallEventListener>();

export function onCallEvent(listener: CallEventListener): () => void {
  callEventListeners.add(listener);
  return () => {
    callEventListeners.delete(listener);
  };
}

export function dispatchCallEvent(eventName: string, data: any): void {
  console.log(`[Pusher] Dispatching call event "${eventName}":`, data);
  callEventListeners.forEach((listener) => {
    try {
      listener(eventName, data);
    } catch (e) {
      console.error('[Pusher] Error in call event listener:', e);
    }
  });
}

function isCallEvent(eventName: string): boolean {
  return (
    eventName === 'CallInitiated' ||
    eventName === '.CallInitiated' ||
    eventName.endsWith('CallInitiated') ||
    eventName === 'call.initiated' ||
    eventName === 'CallAnswered' ||
    eventName === '.CallAnswered' ||
    eventName.endsWith('CallAnswered') ||
    eventName === 'call.answered' ||
    eventName === 'CallSignal' ||
    eventName === '.CallSignal' ||
    eventName.endsWith('CallSignal') ||
    eventName === 'call.signal' ||
    eventName === 'CallEnded' ||
    eventName === '.CallEnded' ||
    eventName.endsWith('CallEnded') ||
    eventName === 'call.ended' ||
    eventName === 'CallRejected' ||
    eventName === '.CallRejected' ||
    eventName.endsWith('CallRejected') ||
    eventName === 'call.rejected'
  );
}

export function subscribeErrandChannel(
  errandId: number | string,
  onEvent: (event: string, data: unknown) => void
): (() => void) | null {
  const pusher = getPusherClient();
  if (!pusher) return null;

  const channelName = `errand.${errandId}`;
  const channel = pusher.subscribe(channelName);

  const globalHandler = (eventName: string, data: any) => {
    onEvent(eventName, data);
    if (isCallEvent(eventName)) {
      dispatchCallEvent(eventName, data);
    }
  };

  channel.bind_global(globalHandler);

  return () => {
    channel.unbind_global(globalHandler);
    pusher.unsubscribe(channelName);
  };
}

export function subscribeUserChannel(
  userId: number | string,
  onEvent: (event: string, data: any) => void
): (() => void) | null {
  const pusher = getPusherClient();
  if (!pusher) return null;

  const channelName = `user.${String(userId).trim()}`;
  console.log(`[Pusher] Subscribing to personal user channel: ${channelName}`);
  const channel = pusher.subscribe(channelName);

  const globalHandler = (eventName: string, data: any) => {
    console.log(`[Pusher] Event on ${channelName}: "${eventName}"`, data);
    onEvent(eventName, data);
  };

  channel.bind_global(globalHandler);

  return () => {
    console.log(`[Pusher] Unsubscribing from user channel: ${channelName}`);
    channel.unbind_global(globalHandler);
    pusher.unsubscribe(channelName);
  };
}

export function subscribeAdminChannel(
  onEvent: (event: string, data: any) => void
): (() => void) | null {
  const pusher = getPusherClient();
  if (!pusher) return null;

  const channel = pusher.subscribe('admin.errands');
  const globalHandler = (eventName: string, data: any) => {
    onEvent(eventName, data);
  };

  channel.bind_global(globalHandler);

  return () => {
    channel.unbind_global(globalHandler);
    pusher.unsubscribe('admin.errands');
  };
}

export function subscribeCustomerChannel(
  customerId: number | string,
  onEvent: (event: string, data: any) => void
): (() => void) | null {
  const pusher = getPusherClient();
  if (!pusher) return null;

  const channel = pusher.subscribe(`customer.${customerId}`);
  const globalHandler = (eventName: string, data: any) => {
    onEvent(eventName, data);
  };

  channel.bind_global(globalHandler);

  return () => {
    channel.unbind_global(globalHandler);
    pusher.unsubscribe(`customer.${customerId}`);
  };
}
