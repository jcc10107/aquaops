// No-op on non-web platforms. On web, the real implementation (in
// web_notification_web.dart) shows a native browser notification for a
// foreground FCM message — otherwise a message that arrives while the tab
// is focused is silently swallowed (the service worker only fires when the
// tab is backgrounded/closed).
void showWebNotification(String title, String body) {}
