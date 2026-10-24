import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'firestore_service.dart';

/// Broadcasts rider's live GPS coordinates to Firestore for active deliveries.
class RiderLocationService {
  final FirestoreService _firestoreService;

  RiderLocationService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  StreamSubscription<Position>? _positionSub;
  List<String> _activeOrderIds = const [];
  bool _isStarting = false;
  int _currentSession = 0;

  /// Updates active order IDs and starts/stops live GPS stream accordingly.
  Future<void> setActiveOrderIds(List<String> orderIds) async {
    _activeOrderIds = orderIds;
    if (orderIds.isEmpty) {
      stop();
      return;
    }

    // Return if already streaming or actively starting.
    if (_positionSub != null || _isStarting) return;

    _isStarting = true;
    final session = ++_currentSession;

    try {
      bool serviceEnabled = true;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      } catch (_) {
        serviceEnabled = true;
      }
      if (!serviceEnabled || _currentSession != session || _activeOrderIds.isEmpty) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (_currentSession != session || _activeOrderIds.isEmpty) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (_currentSession != session || _activeOrderIds.isEmpty) return;
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      // Check session validity before subscribing.
      if (_currentSession != session || _activeOrderIds.isEmpty) return;

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
      ).listen(
            (position) {
          for (final orderId in _activeOrderIds) {
            _firestoreService
                .updateRiderLocation(orderId: orderId, lat: position.latitude, lng: position.longitude)
                .catchError((_) {});
          }
        },
        onError: (_) => stop(),
        cancelOnError: true,
      );
    } finally {
      if (_currentSession == session) {
        _isStarting = false;
      }
    }
  }

  /// Cancels active stream and invalidates any in-flight start operations.
  void stop() {
    _currentSession++;
    _isStarting = false;
    _positionSub?.cancel();
    _positionSub = null;
    _activeOrderIds = const [];
  }
}