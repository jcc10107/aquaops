import 'dart:convert';
import 'package:http/http.dart' as http;

// Calls the Cloudflare Worker (worker.js) directly from the client right
// after a write that should notify someone — real-time delivery instead
// of waiting on scripts/notify_check.mjs's ~15-min GitHub Actions poll.
// Both paths can run side by side: each tracks its own "already notified"
// state on the document it's about, so neither one duplicates the other's
// work — this is just the fast path.
//
// Every call is fire-and-forget and swallows its own errors: a failed
// push must never block or fail the action that triggered it (placing an
// order, sending a message, etc.), and notify_check.mjs remains the
// safety net if this one misses.
class PushNotificationService {
  static const String _workerUrl = 'https://aquaops.jamesdevilla08.workers.dev';
  // Not a secret in the security sense — it only gates who may ask this
  // worker to send a push, not access to Firebase itself. The real
  // credential (the service account key) stays server-side in the
  // Worker's own secrets, never shipped to the client.
  // Supplied at build/run time only (--dart-define=WORKER_SECRET=...) —
  // never committed to source, since this repo is public. Empty when
  // unset, which the worker simply rejects with 401 (handled silently by
  // _post's own catch), so a missing define never crashes anything, it
  // just means pushes fall back to the notify_check.mjs poller.
  static const String _workerSecret = String.fromEnvironment('WORKER_SECRET');

  Future<void> _post(Map<String, dynamic> body) async {
    try {
      await http
          .post(
            Uri.parse(_workerUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_workerSecret',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort — see class doc.
    }
  }

  /// Notify one specific user.
  Future<void> notifyUser({
    required String uid,
    required String title,
    required String body,
    String? conversationId,
    Map<String, String>? data,
  }) {
    return _post({
      'recipientId': uid,
      'title': title,
      'messageText': body,
      if (conversationId != null) 'conversationId': conversationId,
      if (data != null) 'data': data,
    });
  }

  /// Notify every user with any of the given roles (e.g. the whole
  /// staff/owner dispatch queue).
  Future<void> notifyRoles({
    required List<String> roles,
    required String title,
    required String body,
    String? conversationId,
    Map<String, String>? data,
  }) {
    return _post({
      'broadcastRoles': roles,
      'title': title,
      'messageText': body,
      if (conversationId != null) 'conversationId': conversationId,
      if (data != null) 'data': data,
    });
  }

  /// Shorthand for the common "tell the counter" case.
  Future<void> notifyDispatchQueue({
    required String title,
    required String body,
    String? conversationId,
    Map<String, String>? data,
  }) {
    return notifyRoles(roles: const ['staff', 'owner'], title: title, body: body, conversationId: conversationId, data: data);
  }
}
