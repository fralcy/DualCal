'use strict';

// Hand-rolled offline service worker for DualCal — Flutter's own generated
// one (disabled via --pwa-strategy=none in CI, see deploy-pages.yml) only
// self-unregisters and force-reloads clients; it never actually caches
// anything, so offline use never worked. This one does.
//
// Strategy:
//  - App-shell files (this list) are precached on install.
//  - The entrypoint (navigations, main.dart.js, flutter_bootstrap.js) is
//    network-first with cache: 'no-store', so an online user always gets
//    the latest build; offline falls back to whatever was last cached.
//  - Everything else (fonts, images, the CanvasKit CDN script/wasm, any
//    other asset) is cache-first, filled in at runtime the first time it's
//    actually requested — simpler and more robust than trying to
//    enumerate every asset up front (Flutter's asset manifest is now a
//    binary format, not something worth parsing here just to precache
//    eagerly), and still gives full offline use after one normal online
//    visit touches those files.

const CACHE_NAME = 'dualcal-cache-v1';

const APP_SHELL = [
  '.',
  'index.html',
  'main.dart.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

// CanvasKit (Flutter's renderer, ~5-7MB of wasm) is fetched from Google's
// CDN at a URL keyed by the engine's build revision — not something we can
// hardcode without it going stale on every Flutter SDK upgrade. Without
// this, CanvasKit only gets cached by the fetch handler's normal runtime
// caching below, which only kicks in from the *second* page load onward
// (a fresh install doesn't yet control the very page that's fetching it,
// per the service worker spec) — meaning a user who goes offline right
// after their very first visit would get a blank screen. Precaching it
// here, parsing the revision out of the app's own flutter_bootstrap.js
// instead of hardcoding it, closes that gap.
async function precacheCanvasKit(cache) {
  try {
    const bootstrapUrl = new URL('flutter_bootstrap.js', self.registration.scope);
    const res = await fetch(bootstrapUrl, { cache: 'no-store' });
    if (!res.ok) return;
    const text = await res.text();
    const match = text.match(/"engineRevision"\s*:\s*"([0-9a-f]+)"/);
    if (!match) return;

    // The "chromium" variant is what Chrome/Edge/other Chromium-based
    // browsers actually request (see flutter_bootstrap.js's own variant
    // selection) — precaching just this one covers the common case without
    // doubling the download for every visitor. A browser that ends up
    // requesting the plain "full" variant instead still gets it cached via
    // the fetch handler below, just starting from its second visit.
    const base = 'https://www.gstatic.com/flutter-canvaskit/' + match[1] + '/chromium/';
    // Plain fetch, not { mode: 'no-cors' }: Flutter loads canvaskit.js via
    // a dynamic import(), which *requires* a proper CORS-readable
    // response — an opaque (no-cors) one can't be used as a module source
    // and makes the import fail outright. Google's CDN already sends
    // proper CORS headers here (this import already had to work before
    // any service worker existed), so a normal fetch gets a normal,
    // cacheable response — forcing no-cors was actively harmful, not just
    // unnecessary.
    await Promise.allSettled(
      ['canvaskit.js', 'canvaskit.wasm'].map((name) =>
        fetch(base + name).then((response) => cache.put(base + name, response)),
      ),
    );
  } catch (err) {
    // Offline during install, or flutter_bootstrap.js's format changed —
    // the fetch handler's runtime caching is still a safety net.
  }
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      // allSettled, not addAll: addAll fails atomically if even one URL
      // 404s, which would silently skip caching everything else.
      await Promise.allSettled(
        APP_SHELL.map((url) => cache.add(new URL(url, self.registration.scope))),
      );
      await precacheCanvasKit(cache);
    }),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((names) =>
        Promise.all(
          names.filter((name) => name !== CACHE_NAME).map((name) => caches.delete(name)),
        ),
      )
      .then(() => self.clients.claim()),
  );
});

function isEntrypointRequest(request, url) {
  return (
    request.mode === 'navigate' ||
    url.pathname.endsWith('/main.dart.js') ||
    url.pathname.endsWith('/flutter_bootstrap.js')
  );
}

async function networkFirst(request) {
  try {
    // Fetching request.url (a string) rather than `request` itself: a
    // navigation's Request has mode 'navigate', and passing ANY second
    // argument to fetch() alongside an existing Request forces the browser
    // to reconstruct it via `new Request(request, init)` — which throws
    // for mode 'navigate' ("Cannot construct a Request with a RequestInit
    // whose mode member is set as 'navigate'"). That was breaking every
    // single page load, network or not, since this exact path runs for
    // every navigation. Using the URL string sidesteps the restriction
    // entirely.
    const response = await fetch(request.url, { cache: 'no-store' });
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, response.clone());
    return response;
  } catch (err) {
    const cached = await caches.match(request);
    if (cached) return cached;
    throw err;
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;

  // Plain fetch (no forced no-cors) — see precacheCanvasKit's comment on
  // why forcing an opaque response is actively harmful for anything that
  // ends up loaded as a script/module, not just pointless for anything
  // that already supports CORS. request.url (a string), not `request`
  // itself, avoids a class of bug where the original request's mode
  // (e.g. 'navigate') can't be carried into a reconstructed Request —
  // this function shouldn't see navigate requests (isEntrypointRequest
  // routes those to networkFirst first), but staying consistent avoids
  // re-introducing that bug later.
  const response = await fetch(request.url);
  const cache = await caches.open(CACHE_NAME);
  cache.put(request, response.clone());
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);

  if (isEntrypointRequest(request, url)) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(
    cacheFirst(request).catch(() => caches.match(request)),
  );
});
