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
- Still too loose: `orders` can be read by any signed-in user (customers can
  see each other's orders), and `inventory` is writable by any rider. The app
  currently subscribes to the whole `orders` collection in several places
  (`firestore_service.dart`), so tightening reads means changing those queries
  to filter by customer / rider area first.

## Remaining work

1. Deploy the rules and test every role (owner, staff, rider, customer
   signup) against them.
2. Tighten `orders` / `inventory` rules and the queries that depend on them.
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

`maintenance_alerts`, `shifts` and `rider_cashouts` are used by the owner,
POS and rider screens; see `lib/models/` for their fields.
