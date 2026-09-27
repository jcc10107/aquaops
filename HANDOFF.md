# AquaOps — Backend Handoff Document

App: water refilling station management (Flutter/Dart client + Firebase).

**Important context up front:** most screens (`customer_order_screen.dart`, `delivery_queue_screen.dart`, `owner_dashboard_screen.dart`, `pos_screen.dart`, etc.) currently run on **local/mock data** (`_mockOrderHistory`, `_riders`, `_supplies`, etc.). They are not yet wired to `FirestoreService` or `AuthService`. Those two service files define the *intended* data layer, but no screen calls them yet. This isn't "a working app that needs a backend swapped in." It's a UI built against a data model that was never connected. That's normal for this stage, but it means step 5 below (screen-to-data map) shows *intent*, not current behavior.

---

## 1. Fix the auth fallback bug

`lib/services/auth_service.dart` currently does this:

```dart
Future<UserModel?> signIn(String email, String password) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      return await _firestore.getUser(credential.user!.uid);
    }
  } catch (e) {
    // Demo fallback
    return UserModel(
      id: 'usr_staff_1',
      name: 'Maria Santos',
      email: email,
      role: UserRole.staff,
      phone: '+63 920 555 6789',
    );
  }
  return null;
}
```

Any failed sign-in (wrong password, no network, anything) currently logs the user in as staff. Replace the catch block so a failure returns `null` (or rethrows) instead of a fake user:

```dart
Future<UserModel?> signIn(String email, String password) async {
  final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
  if (credential.user != null) {
    return await _firestore.getUser(credential.user!.uid);
  }
  return null;
}
```

Let the caller (`login_screen.dart`) catch the exception and show an error message. Do this before anyone else builds on top of the code.

---

## 2. Firestore schema (from your model files)

### `users` collection

| Field                | Type             | Notes                                         |
|----------------------|------------------|-----------------------------------------------|
| id (doc id)          | string           | Firebase Auth uid                             |
| name                 | string           | —                                             |
| email                | string           | —                                             |
| role                 | string enum      | owner, staff, rider, or customer              |
| phone                | string           | —                                             |
| address              | string, nullable | —                                             |
| assignedArea         | string, nullable | Used for riders. Matches `areaZone` on orders |
| unreturnedContainers | int              | Default 0                                     |
| activeDepositAmount  | double           | Default 0.0                                   |

### `orders` collection

| Field                | Type             | Notes                                                       |
|----------------------|------------------|-------------------------------------------------------------|
| id (doc id)          | string           | —                                                           |
| orderNumber          | string           | —                                                           |
| customerName         | string           | —                                                           |
| customerPhone        | string           | —                                                           |
| deliveryAddress      | string, nullable | —                                                           |
| areaZone             | string           | Used to route to riders                                     |
| items                | array of maps    | Each item: name, quantity, unitPrice, requiresPackaging     |
| totalAmount          | double           | —                                                           |
| status               | string enum      | pending, refilling, outForDelivery, delivered, or cancelled |
| paymentMethod        | string enum      | cash or gcash                                               |
| isPaid               | bool             | —                                                           |
| assignedRiderId      | string, nullable | —                                                           |
| assignedRiderName    | string, nullable | —                                                           |
| gallonsDelivered     | int              | Default 0                                                   |
| emptyGallonsReturned | int              | Default 0                                                   |
| unreturnedDiff       | int              | gallonsDelivered minus emptyGallonsReturned                 |
| proofOfDeliveryUrl   | string, nullable | —                                                           |
| createdAt            | timestamp        | —                                                           |
| deliveredAt          | timestamp        | Set server-side on fulfillment                              |

### `inventory` collection

| Field            | Type   | Notes                                                           |
|------------------|--------|-----------------------------------------------------------------|
| id (doc id)      | string | e.g. inv_pkg_caps, inv_pkg_seals — hardcoded in fulfillDelivery |
| sku              | string | —                                                               |
| name             | string | —                                                               |
| category         | string | water or packaging                                              |
| currentStock     | int    | —                                                               |
| unit             | string | —                                                               |
| minimumThreshold | int    | Used for isLowStock                                             |
| costPerUnit      | double | —                                                               |

### Maintenance alerts (model exists, no collection wired yet)

`MaintenanceAlertModel`: `id`, `equipmentName`, `taskType`, `urgency` (critical, warning, or routine), `dueDate`, `isCompleted`. No Firestore collection or service method exists for this yet. Flag it as "designed but not implemented."

---

## 3. Logic that must move server-side

`FirestoreService.fulfillDelivery()` currently runs this **as a client-side batch write**:

1. Sets the order to `delivered`, `isPaid: true`, records gallons delivered/returned.
2. Decrements `inv_pkg_caps` and `inv_pkg_seals` stock by `gallonsDelivered`.
3. Increments the customer's `unreturnedContainers` by `unreturnedDiff`.

All three of these directly affect money, inventory, and customer balances. Right now, whatever the app tells Firestore, Firestore does. Nothing on the server verifies that a delivery actually happened, that the rider is who they say they are, or that the gallon counts are plausible.

**What the backend builder needs to build:** a server-side function (a Cloud Function, or an API endpoint if you go the custom-backend route). It should take `orderId`, `gallonsDelivered`, `emptyReturned`, `paymentMethod`, and `proofOfDeliveryUrl` from an authenticated rider or staff request. It should validate the request — for example, checking that the rider is assigned to that order, the order isn't already delivered, and the gallon counts aren't negative or absurd. Only then should it perform the same three writes atomically. The client should call that function, not touch `orders`, `inventory`, or `users` directly for this operation.

The same principle applies to anything else that touches money or stock once it's wired up: POS checkout, rider cash-out, emergency transfers. Those screens are currently mock-only. So for them, this is a "build it right the first time" note rather than a retrofit.

---

## 4. Roles → permissions matrix

| Role     | Can see                                                                            | Can do                                                          |
|----------|------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| owner    | All orders, all inventory, all riders, dashboard metrics                           | Everything staff can, plus view business-wide reports           |
| staff    | Orders in all zones, inventory, POS                                                | Create orders, take POS payments, edit inventory, assign riders |
| rider    | Only orders where areaZone matches their assignedArea, and status is not delivered | Fulfill deliveries, request emergency transfers, cash out       |
| customer | Only their own order history and transactions (customerId match)                   | Place orders, view own container and deposit balance            |

This matrix is inferred from the screens (`owner_dashboard_screen.dart`, `pos_screen.dart`, `delivery_queue_screen.dart`, `customer_order_screen.dart`) and from `getOrdersStreamByArea`, which already filters by `areaZone` for riders. Use it as the basis for Firestore security rules or API auth middleware. It's a reasonable read of the code, not a written spec, so confirm it with whoever defined the business rules.

---

## 5. Screen → data mapping (current state: mostly mock)

~~| Screen                                 | Intended collection(s)                                         | Current state                                                    |
|----------------------------------------|----------------------------------------------------------------|------------------------------------------------------------------|
| login_screen.dart / signup_screen.dart | users, via AuthService                                         | Not wired — no Firebase import                                   |
| pos_screen.dart                        | orders, inventory                                              | Mock only                                                        |
| delivery_queue_screen.dart             | orders, filtered by areaZone                                   | Mock only (_allDeliveries) — matches getOrdersStreamByArea shape |
| rider_cash_out_modal.dart              | Likely a new cashouts or ledger collection (doesn't exist yet) | Mock only (_denominations)                                       |
| emergency_transfer_modal.dart          | Likely orders reassignment                                     | Mock only                                                        |
| inventory_screen.dart                  | inventory                                                      | Mock only                                                        |
| owner_dashboard_screen.dart            | Aggregates across orders, inventory, users (riders)            | Mock only (_riders, _supplies)                                   |
| customer_order_screen.dart             | orders, plus a transactions collection (doesn't exist yet)     | Mock only (_mockOrderHistory, _mockTransactions)                 |
| profile_screen.dart                    | users                                                          | Not wired                                                        |

Two collections are implied by the UI but don't exist in the models yet: cash-out/ledger records, and customer transactions. Your backend builder will need specs for these, not just the three existing models.

---

## 6. Decide: patch Firebase, or replace it with a real backend

Two real options. Pick one before work starts — it changes everything below it:

- **Option A — keep Firebase.** The backend builder adds Cloud Functions for the logic in step 3, and writes Firestore security rules matching step 4's matrix. The app keeps talking to Firestore and Auth directly for reads.
- **Option B — custom backend.** The backend builder stands up a REST or GraphQL API, with its own database or Firestore as storage behind the API. The app is changed to call that API instead of Firestore directly. Firebase Auth is either kept as an identity provider or replaced.

Option A is less work and keeps your current code mostly intact. Option B gives more control: it's easier to add non-Firebase integrations, easier to unit test business logic, and you're not locked into Firestore's data-modeling constraints. But it means rewriting both service files, and eventually wiring every screen to a different client.

---

## 7. Environment & config details to hand over

- **Firebase project ID** — from your Firebase console (not in the zip; grab it yourself).
- **`pubspec.yaml`** — wasn't included in this zip. Get it from your project root; it will list exact versions of `firebase_core`, `firebase_auth`, `cloud_firestore`.
- Confirmed packages in use (from imports): `firebase_auth`, `cloud_firestore` (Firestore package itself, via `FirebaseFirestore.instance`).
- **Android application ID is still the template default**: `com.example.aquaops` (in `android/app/build.gradle.kts`). Flag this — it needs to change before any real release, and your backend builder may need the real package name for push notification setup, Firebase config, etc.
- Any third-party services you're planning (GCash payment integration, SMS/notifications for delivery updates) — none are in the code yet, so if they're planned, say so now rather than after the backend is built.

---
