# AquaOps

Water refilling station management app: POS, delivery dispatch, inventory and
customer ordering, built with Flutter and Firebase (Auth + Firestore + Storage).

## Roles

| Role     | What they use                                                       |
|----------|---------------------------------------------------------------------|
| owner    | Dashboard, team management, inventory, POS, deliveries              |
| staff    | POS, inventory, delivery assignment                                 |
| rider    | Delivery queue, fulfilment, cash-out, emergency transfer            |
| customer | Place and track orders, saved addresses, container/deposit balance  |

## Screens (`lib/screens`)

- `auth/` login, signup
- `customer/` ordering, order history
- `delivery/` delivery queue, rider cash-out, emergency transfer
- `inventory/` stock levels
- `owner/` dashboard, manage team (create staff/rider accounts)
- `pos/` point of sale
- `profile/` profile and role-specific settings

Data access lives in `lib/services/` (`auth_service.dart`, `firestore_service.dart`).

## Setup

Requirements: Flutter SDK (Dart 3), Node.js 18+ (for the seed scripts), and
access to the Firebase project `aquaops-e8dd1`.

```bash
flutter pub get
flutter run            # pick Chrome, Windows or an Android device
```

`lib/firebase_options.dart` and `android/app/google-services.json` hold the
Firebase client config. These identify the project and ship inside the app;
access is enforced by the Firestore/Storage security rules, not by hiding them.

## Demo accounts

Run once to create the demo accounts (and their Firestore profiles):

```powershell
$env:FIREBASE_API_KEY = "<Web API key from lib/firebase_options.dart>"
node scripts/seed_users.mjs
node scripts/seed_inventory.mjs
node scripts/seed_delivery_orders.mjs
```

Run `seed_users.mjs` first. The accounts are `owner@`, `staff@`, `rider@` and
`customer@aquaops.com`, all with password `password123`. These are for
development only.

The Firestore rules only let a signed-in user create their own profile as a
`customer`. The seed script therefore writes staff/rider profiles using the
owner's session, and the owner profile must already exist (on a brand-new
project, create it once by hand in the Firebase console).

## Security rules

`firestore.rules` and `storage.rules` are not applied automatically. After
changing them:

```bash
firebase deploy --only firestore:rules,storage
```

## Known gaps

See [HANDOFF.md](HANDOFF.md) for the current status and the remaining work.
