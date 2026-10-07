// Background push notification handler for Flutter web. Firebase requires
// this file at the site root (web/firebase-messaging-sw.js -> served at
// /firebase-messaging-sw.js) to show a notification when the browser tab
// isn't focused or is closed.
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.9.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBIKVc-siDJBmseHauc9h1Bd43vxh2ZaZI',
  appId: '1:344330549483:web:9ceb846ea96304069fa6ae',
  messagingSenderId: '344330549483',
  projectId: 'aquaops-e8dd1',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'AquaOps';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
