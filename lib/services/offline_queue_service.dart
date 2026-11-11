import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'cloudinary_service.dart';
import 'firestore_service.dart';

/// Local-first queue for rider "Fulfill Delivery" submissions made while
/// offline. Riders routinely lose signal in the field; without this, a
/// delivery they just physically completed would simply fail to save.
///
/// Records are plain Maps (no generated Hive TypeAdapter needed) keyed by
/// orderId, so re-queuing the same order overwrites rather than duplicates.
class OfflineQueueService {
  static const String _boxName = 'pending_deliveries';
  static const String _deadLetterBoxName = 'dead_letter_deliveries';

  /// Must be called once at app startup (see main.dart), before any other
  /// OfflineQueueService instance is used. Hive manages the opened box
  /// globally, so later instances (e.g. created fresh inside a screen) can
  /// reach the same box via Hive.box() without re-opening it themselves.
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_deadLetterBoxName);
  }

  Box get _requireBox {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError('OfflineQueueService.init() must be called before use (see main.dart).');
    }
    return Hive.box(_boxName);
  }

  Future<void> queue({
    required String orderId,
    required String customerId,
    required int gallonsDelivered,
    required int emptyReturned,
    required String paymentMethod,
    String? recipientName,
    Uint8List? photoBytes,
    // Display-only fields — captured at queue time so the pending-sync
    // list can show something meaningful without needing live order data
    // (which may not even be reachable while offline).
    String? orderNumber,
    String? customerName,
    String? deliveryAddress,
  }) async {
    await _requireBox.put(orderId, {
      'orderId': orderId,
      'customerId': customerId,
      'gallonsDelivered': gallonsDelivered,
      'emptyReturned': emptyReturned,
      'paymentMethod': paymentMethod,
      'recipientName': recipientName,
      'photoBytes': photoBytes,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'queuedAt': DateTime.now().toIso8601String(),
      'retryCount': 0, // Initialize retry counter
    });
  }

  List<Map<String, dynamic>> getAllPending() {
    return _requireBox.values
        .map((v) => Map<String, dynamic>.from(v as Map))
        .toList(growable: false);
  }

  Future<void> remove(String orderId) async {
    await _requireBox.delete(orderId);
  }

  /// Reactive handle for the pending box — rebuild UI off this to show a
  /// live "N pending" count without manual polling.
  ValueListenable<Box> listenable() => _requireBox.listenable();

  /// Attempts to push every queued record to Firestore/Cloudinary. Each
  /// record is tried independently — one failure (e.g. still offline)
  /// never aborts the rest of the batch. Returns (synced, stillPending).
  Future<(int synced, int stillPending)> syncAll({
    required FirestoreService firestoreService,
    required CloudinaryService cloudinaryService,
  }) async {
    final pending = getAllPending();
    int synced = 0;

    for (final record in pending) {
      final orderId = record['orderId'] as String;

      try {
        // Retrieve cached URL if we already successfully uploaded the image on a previous retry
        String? proofOfDeliveryUrl = record['proofOfDeliveryUrl'] as String?;

        if (proofOfDeliveryUrl == null) {
          Uint8List? bytesToUpload;
          final photoBytes = record['photoBytes'];

          // Deduplicate the array conversions
          if (photoBytes is Uint8List && photoBytes.isNotEmpty) {
            bytesToUpload = photoBytes;
          } else if (photoBytes is List && photoBytes.isNotEmpty) {
            // Hive may hand back a plain List<int> rather than Uint8List.
            bytesToUpload = Uint8List.fromList(photoBytes.cast<int>());
          }

          if (bytesToUpload != null) {
            proofOfDeliveryUrl = await cloudinaryService.uploadImage(
              bytesToUpload,
              filename: 'proof_of_delivery.jpg',
              folder: 'proof_of_delivery',
            );

            // Cache the URL locally so if Firestore fails, we don't re-upload the photo again
            record['proofOfDeliveryUrl'] = proofOfDeliveryUrl;
            await _requireBox.put(orderId, record);
          }
        }

        // NOTE: if this sync happens after the rider's shift has already
        // been closed out, this delivery's payment total won't retroactively
        // appear in that already-closed shift summary — a known limitation,
        // intentionally out of scope for this pass.
        await firestoreService.fulfillDelivery(
          orderId: orderId,
          gallonsDelivered: record['gallonsDelivered'] as int,
          emptyReturned: record['emptyReturned'] as int,
          paymentMethod: record['paymentMethod'] as String,
          proofOfDeliveryUrl: proofOfDeliveryUrl,
          recipientName: record['recipientName'] as String?,
        );

        await remove(orderId);
        synced++;
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();

        // Handle Permanent Exceptions (Already processed or deleted order)
        if (errorMsg.contains('already processed') || errorMsg.contains('not found')) {
          await remove(orderId);
          synced++; // Count as effectively 'resolved' so it clears gracefully
          continue;
        }

        // Handle Transient Failures with Retry Limits
        int retries = (record['retryCount'] as int?) ?? 0;
        if (retries >= 3) {
          // Max retries reached, move to dead-letter storage
          record['finalError'] = e.toString();
          record['deadLetteredAt'] = DateTime.now().toIso8601String();

          if (Hive.isBoxOpen(_deadLetterBoxName)) {
            await Hive.box(_deadLetterBoxName).put(orderId, record);
          }
          await remove(orderId);
        } else {
          // Increment and save back to queue
          record['retryCount'] = retries + 1;
          await _requireBox.put(orderId, record);
        }
      }
    }

    return (synced, _requireBox.length);
  }
}