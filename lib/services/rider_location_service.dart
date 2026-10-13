import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'firestore_service.dart';

// Broadcasts the rider's live GPS position to Firestore for whichever of
// their orders are currently out for delivery, so the customer's (and the
// rider's own) "Live Order Tracking" map can show a real moving marker
// instead of a static placeholder.
//
// Best-effort only, same philosophy as location_service.dart: if the rider
// hasn't granted location permission, or geolocation isn't supported on
// their device/browser, broadcasting simply never starts — this is a nice
// enhancement to the delivery experience, not something that should ever
// block or interrupt a rider's actual work.
class RiderLocationService {
  final FirestoreService _firestoreService;

  RiderLocationService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  StreamSubscription<Position>? _positionSub;
  List<String> _activeOrderIds = const [];

  // Call this whenever the rider's set of out-for-delivery order ids
  // changes (including going from none to some, or some to none). Safe to
  // call repeatedly — it starts the GPS stream on the first non-empty call,
  // keeps it running (just updating which orders get the broadcast) while
  // the list stays non-empty, and stops it once the list goes empty.
  Future<void> setActiveOrderIds(List<String> orderIds) async {
    _activeOrderIds = orderIds;
    if (orderIds.isEmpty) {
      stop();
      return;
    }
    if (_positionSub != null) return; // already streaming — new ids picked up on the next fix

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
    } catch (_) {}

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

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
  }

  void stop() {
    _positionSub?.cancel();
    _positionSub = null;
    _activeOrderIds = const [];
  }
}
