# AquaOps — Handoff

App: water refilling station management (Flutter client + Firebase project
`aquaops-e8dd1`). See [README.md](README.md) for setup and demo accounts.

## Current state

The earlier version of this document described a UI running on mock data. That
is no longer true: every screen in `lib/screens` now reads and writes through
`FirestoreService` / `AuthService`, and the sign-in fallback that logged any
failed login in as a fake staff user has been removed. `flutter analyze`
reports no errors (only lints such as unused fields and missing `const`).

Collections in use (`lib/services/firestore_service.dart`): `users`
(with an `addresses` subcollection), `orders`, `inventory`,
`maintenance_alerts`, `shifts`, `rider_cashouts`.

## Security rules

`firestore.rules` and `storage.rules` are in the repo.

- Done in code: self-signup can only create a `customer` profile, and users
  cannot change their own `role`. Only an owner can create staff/rider/owner
  profiles. Before this fix anyone with the public API key could make
  themselves an owner.
- **Not yet deployed** unless `firebase deploy --only firestore:rules` has been
  run since the change; the rules live in Firebase, not in git.
- `orders`: customers can only read their own orders, create their own
  pending/unpaid order, and cancel it (nothing else). Staff/owner have full
  access; the assigned rider can update their own orders.
- `inventory`: only staff/owner/rider can read; riders can only lower
  `currentStock`.
- Still loose: riders can read every order, because the delivery queue
  subscribes to all active orders (`getActiveOrdersStream`). Limiting riders
  to their own area/assigned orders means changing that query first. These
  order/inventory rules are committed but not deployed until you run
  `firebase deploy --only firestore:rules`.

## Remaining work

1. Deploy the rules and test every role (owner, staff, rider, customer
   signup) against them.
2. Limit rider reads of `orders` to their own area/assigned orders (needs a
   query change in `getActiveOrdersStream`).
3. Move `fulfillDelivery()` server-side (Cloud Function or API). It currently
   runs as a client batch write that sets the order delivered, decrements
   `inv_pkg_caps` / `inv_pkg_seals`, and adjusts the customer's
   `unreturnedContainers`. Nothing verifies the rider is assigned to the
   order or that the counts are plausible. The same applies to POS checkout,
   rider cash-out and emergency transfers.
4. Photo uploads: `image_picker` and `firebase_storage` are dependencies and
   `storage.rules` has paths for `receipts/` and `delivery_proofs/`, but no
   code calls `FirebaseStorage` or `ImagePicker` yet.
5. Restrict the Firebase API keys in Google Cloud Console (Android app
   restriction + SHA-1 for the Android key; HTTP referrers for the web key),
   then dismiss the GitHub secret-scanning alerts.
6. Change the Android application ID from the template
   `com.example.aquaops` (`android/app/build.gradle.kts`) before any release;
   this also requires regenerating the Firebase config.
7. Tests: only a smoke test exists (`test/widget_test.dart`) and it has not
   been verified to pass with Firebase initialisation.
8. Planned but not present: GCash payment integration, SMS/push notifications.

## Roles → permissions (inferred from the screens and rules)

| Role     | Can see                                                  | Can do                                                           |
|----------|----------------------------------------------------------|------------------------------------------------------------------|
| owner    | Everything, dashboard metrics                            | All staff actions, manage team accounts, delete users            |
| staff    | Orders in all zones, inventory, POS                      | Create orders, take POS payments, edit inventory, assign riders  |
| rider    | Orders assigned to them (by area), inventory             | Fulfil deliveries, emergency transfer, cash-out                  |
| customer | Own orders, own container and deposit balance            | Place and cancel own orders, manage saved addresses              |

This is a reading of the code, not a written spec; confirm with whoever owns
the business rules.

## Firestore schema

### `users`

| Field                | Type             | Notes                                          |
|----------------------|------------------|------------------------------------------------|
| id (doc id)          | string           | Firebase Auth uid                              |
| name, email, phone   | string           |                                                |
| role                 | string enum      | owner, staff, rider, customer                  |
| address              | string, nullable |                                                |
| assignedArea         | string, nullable | Riders; matches `areaZone` on orders           |
| unreturnedContainers | int              | Default 0                                      |
| activeDepositAmount  | double           | Default 0.0                                    |

### `orders`

| Field                              | Type             | Notes                                                     |
|------------------------------------|------------------|-----------------------------------------------------------|
| id (doc id), orderNumber           | string           |                                                           |
| customerId, customerName, customerPhone | string      | `customerId` is used by the rules                         |
| deliveryAddress                    | string, nullable |                                                           |
| areaZone                           | string           | Routes to riders                                          |
| items                              | array of maps    | name, quantity, unitPrice, requiresPackaging              |
| totalAmount                        | double           |                                                           |
| status                             | string enum      | pending, refilling, outForDelivery, delivered, cancelled  |
| paymentMethod                      | string enum      | cash, gcash                                               |
| isPaid                             | bool             |                                                           |
| assignedRiderId, assignedRiderName | string, nullable |                                                           |
| gallonsDelivered, emptyGallonsReturned, unreturnedDiff | int | unreturnedDiff = delivered − returned                |
| proofOfDeliveryUrl                 | string, nullable |                                                           |
| createdAt, deliveredAt             | timestamp        |                                                           |

### `inventory`

Doc ids such as `inv_water_round`, `inv_water_slim`, `inv_pkg_caps`,
`inv_pkg_seals` are referenced directly from `FirestoreService`.
Fields: `sku`, `name`, `category` (water | packaging), `currentStock`, `unit`,
`minimumThreshold`, `costPerUnit`.

### Other collections

<<<<<<< HEAD
`maintenance_alerts`, `shifts` and `rider_cashouts` are used by the owner,
POS and rider screens; see `lib/models/` for their fields.
=======
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

| Screen                                 | Intended collection(s)                                         | Current state                                                    |
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
>>>>>>> f52fd6b2a0ad66e1f66f030ebbb45f1c58f52d1e
