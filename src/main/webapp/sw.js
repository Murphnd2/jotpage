/*
 * Jyrnyl service worker
 *
 * Strategy:
 *   - Navigation (HTML) requests: network-first, fall back to cached shell,
 *     then to /offline.html. Keeps users on a fresh page when online,
 *     but functional when offline.
 *   - Static assets (CSS, JS, fonts, images): stale-while-revalidate.
 *     Fast loads, background refresh.
 *   - API / POST / auth routes: never cached. Always network.
 *
 * To ship a new version:
 *   - Bump CACHE_VERSION below and redeploy.
 *   - The browser will download the new sw.js on next visit (because
 *     web.xml serves sw.js with no-cache), activate it, and purge old
 *     caches on activation.
 */

const CACHE_VERSION = 'v9';
const STATIC_CACHE  = `jyrnyl-static-${CACHE_VERSION}`;
const RUNTIME_CACHE = `jyrnyl-runtime-${CACHE_VERSION}`;

// Minimal pre-cache: just the offline fallback and core theme assets.
// Intentionally NOT pre-caching JSPs — those are dynamic and user-scoped.
const PRECACHE_URLS = [
  '/offline.html',
  '/css/theme.css',
  '/manifest.webmanifest',
  '/images/jyrnyl-logo-square.svg',
  '/images/jyrnyl-logo-400.png'
];

// URL patterns that must always hit the network.
const NETWORK_ONLY = [
  /\/login$/,
  /\/logout$/,
  /\/oauth2callback/,
  /\/api\//
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys
        .filter((key) => key !== STATIC_CACHE && key !== RUNTIME_CACHE)
        .map((key) => caches.delete(key))
    )).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;

  // Only handle GET. POSTs (form submits, API writes) must never be cached.
  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);

  // Same-origin only. Don't interfere with Google OAuth, fonts.googleapis, etc.
  if (url.origin !== self.location.origin) {
    return;
  }

  // Network-only routes.
  if (NETWORK_ONLY.some((pattern) => pattern.test(url.pathname))) {
    return;
  }

  // Navigation requests → network first, offline fallback.
  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigate(request));
    return;
  }

  // Static assets → stale-while-revalidate.
  event.respondWith(staleWhileRevalidate(request));
});

async function networkFirstNavigate(request) {
  try {
    const fresh = await fetch(request);
    // Cache a copy for offline fallback next time.
    const cache = await caches.open(RUNTIME_CACHE);
    cache.put(request, fresh.clone());
    return fresh;
  } catch (err) {
    const cached = await caches.match(request);
    if (cached) return cached;
    const offline = await caches.match('/offline.html');
    if (offline) return offline;
    return new Response('Offline', { status: 503, statusText: 'Offline' });
  }
}

async function staleWhileRevalidate(request) {
  const cache = await caches.open(RUNTIME_CACHE);
  const cached = await cache.match(request);

  const networkPromise = fetch(request)
    .then((response) => {
      // Only cache OK responses.
      if (response && response.ok) {
        cache.put(request, response.clone());
      }
      return response;
    })
    .catch(() => null);

  return cached || networkPromise || new Response('', { status: 504 });
}
