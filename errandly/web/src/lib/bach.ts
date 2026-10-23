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
        open: (options: { checkoutUrl: string }) => void;
        close?: () => void;
      };
    };
  }
}

let bachsScriptPromise: Promise<boolean> | null = null;

/**
 * Dynamically loads the Bachs Checkout SDK script if not already present.
 */
export function loadBachsScript(): Promise<boolean> {
  if (typeof window === 'undefined') return Promise.resolve(false);
  if (window.Bachs) return Promise.resolve(true);
  if (bachsScriptPromise) return bachsScriptPromise;

  bachsScriptPromise = new Promise((resolve) => {
    // Check if script tag is already in DOM
    const existingScript = document.querySelector('script[src*="checkout.bachs.io/bachs.js"]');
    if (existingScript) {
      if (window.Bachs) return resolve(true);
      existingScript.addEventListener('load', () => resolve(true));
      existingScript.addEventListener('error', () => resolve(false));
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://checkout.bachs.io/bachs.js';
    script.async = true;
    script.onload = () => {
      resolve(true);
    };
    script.onerror = () => {
      console.warn('[Bachs] Failed to load bachs.js SDK, will fallback to hosted checkout redirect.');
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
 * Tries the overlay modal first; gracefully falls back to hosted redirect.
 */
export async function openBachsCheckout(options: LaunchBachsCheckoutOptions): Promise<void> {
  const { checkoutUrl, onSuccess, onClose, preferRedirect = false } = options;

  if (preferRedirect || typeof window === 'undefined') {
    window.location.href = checkoutUrl;
    return;
  }

  const loaded = await loadBachsScript();

  if (loaded && window.Bachs && window.Bachs.Checkout) {
    try {
      window.Bachs.Initialize({
        onEvent: (event) => {
          if (
            event.event === 'checkout.completed' ||
            event.event === 'collection.succeeded' ||
            event.event === 'payment.succeeded'
          ) {
            onSuccess?.(event.data);
          } else if (event.event === 'checkout.closed') {
            onClose?.();
          }
        },
      });

      window.Bachs.Checkout.open({ checkoutUrl });
      return;
    } catch (e) {
      console.warn('[Bachs] Error opening inline modal, redirecting to hosted checkout:', e);
    }
  }

  // Fallback to hosted redirect
  window.location.href = checkoutUrl;
}
