const CACHE_NAME = 'gyansetu-cache-v5'; // update this version number whenever you make changes to the cache
const urlsToCache = [
  '/',
  '/index.html',
  '/assets/styles/main.css',
  '/assets/scripts/contact.js',
  '/components/navbar.js',
  // '/krishi/index.html',
  // '/profile.html',
  // '/assets/styles/profile.css',
  // '/e_library/index.html',
  // '/materials_page/materials.html',
  // '/assets/styles/materials.css',
  // '/materials_page/student_materials.html',
  // '/materials_page/teacher_materials.html'
  // Add other assets you want to cache
];

// Install event
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(urlsToCache);
    })
  );
});

// Fetch event
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});

// Activate event
self.addEventListener('activate', (event) => {
  const cacheWhitelist = [CACHE_NAME];
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (!cacheWhitelist.includes(cacheName)) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
}); 