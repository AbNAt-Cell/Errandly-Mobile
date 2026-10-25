/**
 * Bachs Payment Gateway Helper & SDK Loader
 * Documentation: https://docs.bachs.io/client-sdks/web
 */

declare global {
  interface Window {
    Bachs?: {
      Initialize: (config: {
        onEvent?: (event: { event: string; data?: any }) => void;
      }) => void;
      Checkout: {
        open: (options: {
          checkoutUrl?: string;
          token?: string;
          onEvent?: (event: { event: string; data?: any }) => void;
        }) => Promise<any> | void;
        close?: () => void;
        isOpen?: () => boolean;
      };
    };
  }
}

let currentLoadedScriptUrl: string | null = null;
let bachsScriptPromise: Promise<boolean> | null = null;

/**
 * Dynamically loads the Bachs Checkout SDK script matching the environment of the checkout session:
 * - Sandbox: https://sandbox-checkout.bachs.io/bachs.js
 * - Production: https://checkout.bachs.io/bachs.js
 */
export function loadBachsScript(targetScriptUrl: string): Promise<boolean> {
  if (typeof window === 'undefined') return Promise.resolve(false);

  // If the matching script is already active and window.Bachs is present
  if (window.Bachs && currentLoadedScriptUrl === targetScriptUrl) {
    return Promise.resolve(true);
  }

  // If a script from the opposite environment was previously loaded, remove it to prevent cross-origin SDK errors
  const existingScript = document.querySelector('script[src*="bachs.js"]') as HTMLScriptElement | null;
  if (existingScript && existingScript.src !== targetScriptUrl) {
    existingScript.remove();
    delete (window as any).Bachs;
    bachsScriptPromise = null;
  }

  if (bachsScriptPromise && currentLoadedScriptUrl === targetScriptUrl) {
    return bachsScriptPromise;
  }

  currentLoadedScriptUrl = targetScriptUrl;
  bachsScriptPromise = new Promise((resolve) => {
    const script = document.createElement('script');
    script.src = targetScriptUrl;
    script.async = true;
    script.onload = () => {
      resolve(true);
    };
    script.onerror = () => {
      console.warn(`[Bachs] Failed to load ${targetScriptUrl}, will fallback to hosted checkout.`);
      resolve(false);
    };
    document.head.appendChild(script);
  });

  return bachsScriptPromise;
}

export interface LaunchBachsCheckoutOptions {
  checkoutUrl: string;
  checkoutId?: string;
  onSuccess?: (data?: any) => void;
  onClose?: () => void;
  preferRedirect?: boolean;
}

/**
 * Launches the Bachs checkout flow.
 * Tries the environment-matching overlay modal first; gracefully falls back to hosted redirect on error.
 */
export async function openBachsCheckout(options: LaunchBachsCheckoutOptions): Promise<void> {
  const { checkoutUrl, onSuccess, onClose, preferRedirect = false } = options;

  if (preferRedirect || typeof window === 'undefined' || !checkoutUrl) {
    if (checkoutUrl && typeof window !== 'undefined') {
      window.location.href = checkoutUrl;
    }
    return;
  }

  // Determine whether this checkout URL is sandbox or production
  const isSandbox = checkoutUrl.includes('sandbox-checkout.bachs.io');
  const targetScriptUrl = isSandbox
    ? 'https://sandbox-checkout.bachs.io/bachs.js'
    : 'https://checkout.bachs.io/bachs.js';

  try {
    const loaded = await loadBachsScript(targetScriptUrl);

    if (loaded && window.Bachs && window.Bachs.Checkout) {
      const handleEvent = (event: { event: string; data?: any }) => {
        if (
          event.event === 'checkout.completed' ||
          event.event === 'collection.succeeded' ||
          event.event === 'payment.succeeded'
        ) {
          onSuccess?.(event.data);
        } else if (event.event === 'checkout.closed') {
          onClose?.();
        }
      };

      if (typeof window.Bachs.Initialize === 'function') {
        window.Bachs.Initialize({ onEvent: handleEvent });
      }

      // Await open() promise and catch any internal rejection so it doesn't leak unhandled
      await Promise.resolve(
        window.Bachs.Checkout.open({
          checkoutUrl,
          onEvent: handleEvent,
        })
      );
      return;
    }
  } catch (e) {
    console.warn('[Bachs] Overlay modal failed, redirecting to hosted checkout:', e);
  }

  // Graceful fallback to hosted checkout redirect
  window.location.href = checkoutUrl;
}
