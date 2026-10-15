# Sura Yangu (ngozi_yangu)

A certified skincare and beauty marketplace for Tanzanian sellers and shoppers —
an Android-only Flutter client backed by a Dart HTTP API and PostgreSQL.

Shoppers complete a skin assessment and get explainable product matches; sellers
run a shop (products, stock, orders, profit); admins moderate everything.

## Stack

| Layer | Tech |
| --- | --- |
| Client | Flutter 3.50 (Dart 3.14), Material 3, Android only |
| State | Single `ChangeNotifier` (`Store`) + `ListenableBuilder`, no codegen |
| API | Dart `shelf` + `shelf_router`, hand-written JSON |
| Database | PostgreSQL via `package:postgres`, forward-only SQL migrations |
| Images | Raw-binary upload to `backend/uploads/`, served from `/uploads/<name>` |
| Persistence | `shared_preferences` for the session token |
| Other deps | `image_picker`, `url_launcher` |

## Project layout

```
lib/
  main.dart            entry point
  app.dart             MaterialApp, splash, role-scoped RootShell + bottom nav
  core/                theme, TZS/date formatters, page transitions
  models/              User, Product, Order, CartItem, SkinProfile, enums
  data/                ApiClient, Store, RecommendationEngine, seed_data
  features/            auth, catalog, product, cart, orders, skin, seller, admin, customer
  widgets/             reusable UI (bottom nav, cards, product card, buttons)
backend/
  bin/server.dart      boot: migrations -> seed -> routes -> listen
  lib/                 api_core, api_orders, api_uploads, auth, db, pg, seed, env
  migrations/          001_init.sql
  uploads/             stored product images
  .env.example         copy to .env and edit
test/                  recommendation engine + widget tests
run.sh                 backend + adb tunnel + flutter run
```

## Roles and isolation

`UserRole` is `customer | seller | admin`. The root shell builds a different
five-tab navigation per role, so a user never sees another role's screens:

- **Customer** — Home dashboard, Shop, Cart, Orders, Profile.
- **Seller** — Overview, Products, Orders, Finance, Shop Profile. No cart or checkout.
- **Admin** — Console, Sellers, Moderation, Operations, Profile.

Approved sellers and admins can toggle **Preview Shop** to see the customer
experience; a blue banner marks the mode and one tap exits it.

Sellers start as `customer` with `sellerStatus: none`. `POST /api/me/seller-application`
moves them to `pending`; only after an admin sets them `approved` can they create
products. Products likewise start `pending` and only appear in the buyer catalog
once approved.

## Feature tour

**Skin profile & recommendations.** A four-step assessment (skin type, concerns,
sensitivities, goals) is saved per user. `RecommendationEngine.rank()` scores the
approved catalog against it and the "For You" screen shows each match's score,
reasons and precautions.

**Catalog & product.** Filter by category, skin type, concern, shop location and
price; compare up to three products side by side; product detail shows full
ingredient data, usage, side effects and warnings, with stock-aware quantity.

**Cart & checkout.** Server-side cart, validated against live stock. Checkout
captures recipient, address, city and delivery notes; delivery fee is TZS 3,000
for Dar es Salaam and TZS 5,000 elsewhere.

**Payments.** M-Pesa, Tigo Pesa, Airtel Money, Wowza and cash on delivery. The
mobile-money flow is a simulation of a provider handshake: `pay/start` issues an
`SY…` reference and sets `verifying`, `pay/confirm` verifies server-side and sets
`paid` + `confirmed`. Entering PIN `0000` (or anything non-4-digit) simulates a
declined push and sets `failed`. The client can never mark an order paid.

**Orders.** `placed -> confirmed -> onTheWay -> delivered`, with `cancelled` as a
terminal branch. Every transition writes an `order_events` row, so both buyer and
seller see a timeline. Buyers can cancel until delivery; sellers and admins
advance status.

**Seller tools.** Product CRUD with image upload, stock levels, per-order
fulfilment, and a finance screen with revenue, cost summary and estimated net
profit.

**Admin console.** Seller KYC queue, product moderation queue, user management
(create/edit, activate/block, delete), platform-wide order list and order
deletion, plus headline metrics.

## Data model

`backend/migrations/001_init.sql` creates eight tables:

| Table | Purpose |
| --- | --- |
| `users` | credentials, role, seller status, shop fields, `deactivated` flag |
| `sessions` | bearer token -> user, `ON DELETE CASCADE` |
| `products` | price in integer TZS, PostgreSQL text arrays for ingredients/skin types/concerns/flags, stock check constraint, `approval` |
| `skin_profiles` | one row per user, arrays for concerns/sensitivities/goals |
| `cart_items` | composite `(user_id, product_id)` key, quantity > 0 |
| `orders` | totals, delivery details, payment method/status/reference, status |
| `order_lines` | immutable product snapshot per line |
| `order_events` | append-only status history |

Migrations run automatically at startup and are recorded in `schema_migrations`
so each file applies exactly once, in filename order.

## API

All endpoints are JSON under `/api`, authenticated with `Authorization: Bearer <token>`
issued by `/api/auth/login`. Errors return `{"error": "..."}` with a 4xx status.

```
POST   /api/auth/register | /api/auth/login | /api/auth/logout
GET    /api/me            PUT /api/me        PUT /api/me/password
DELETE /api/me            POST /api/me/seller-application   PUT /api/me/shop
GET/PUT /api/me/skin-profile
GET    /api/products      GET /api/products/mine
POST   /api/products      PUT /api/products/<id>            DELETE /api/products/<id>
GET/POST /api/me/cart     PUT /api/me/cart/<productId>      DELETE /api/me/cart
POST   /api/orders        GET /api/orders                   GET /api/orders/<id>
GET    /api/orders/sales  PUT /api/orders/<id>/status       PUT /api/orders/<id>/cancel
POST   /api/orders/<id>/pay/start | /pay/confirm
GET    /api/admin/sellers   PUT /api/admin/sellers/<id>/status
GET    /api/admin/products  GET /api/admin/products/all
PUT    /api/admin/products/<id>/approval
GET/POST /api/admin/users   PUT /api/admin/users/<id>
PUT  /api/admin/users/<id>/active   DELETE /api/admin/users/<id>
GET  /api/admin/orders  PUT /api/admin/orders/<id>/status  DELETE /api/admin/orders/<id>
POST /api/upload        GET /uploads/<name>   GET /api/health
```

Role checks are enforced server-side on every route (ownership for product and
order edits, `role == 'admin'` for `/api/admin/*`), not just hidden in the UI.

## Getting started

**Prerequisites:** Flutter on the `master` channel (the project pins
`environment.sdk: ^3.14.0-60.0.dev`), a PostgreSQL server, `adb`, and a physical
Android device or emulator.

1. **Database**

   ```sql
   CREATE DATABASE surayangu;
   CREATE USER surayangu WITH PASSWORD 'your-password';
   GRANT ALL PRIVILEGES ON DATABASE surayangu TO surayangu;
   ```

2. **Config** — `cp backend/.env.example backend/.env`, then set `PGHOST`,
   `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PORT`. Process environment
   variables override the file. `backend/.env` is git-ignored.

3. **Dependencies**

   ```bash
   flutter pub get
   cd backend && dart pub get && cd ..
   ```

4. **Run everything** — from the project root:

   ```bash
   ./run.sh
   ```

   This starts the backend on `:8181` if it isn't already up, waits for
   `/api/health`, applies migrations, seeds the database on first boot, sets up
   `adb reverse tcp:8181 tcp:8181`, and launches the app on the attached Android
   device. It exits with an error if no device is connected — there is no web or
   desktop fallback.

**Pointing the app at another backend.** The base URL is a compile-time define;
precedence is `--dart-define` then the default `http://127.0.0.1:8181` (which the
`adb reverse` tunnel resolves to your machine):

```bash
./run.sh --dart-define=API_BASE_URL=http://192.168.1.10:8181   # same Wi-Fi LAN
./run.sh --dart-define=API_BASE_URL=http://10.0.2.2:8181       # Android emulator
```

**Backend only:** `dart run backend/bin/server.dart`

## Demo accounts

Seeded on an empty database by `backend/lib/seed.dart` (17 products across three
approved shops). Change these passwords before any real use.

| Account | Email | Password | Role |
| --- | --- | --- | --- |
| Sura Yangu Admin | `admin@surayangu.co.tz` | `admin123` | admin |
| Juma Hassan — Pwani Coconut Co-op | `juma@pwanicoins.co.tz` | `seller123` | seller, approved |
| Neema Mareki — Kilimanjaro Natural Skincare | `neema@kilimanjaroskin.tz` | `seller123` | seller, approved |
| Fatuma Ally — Maji Safi Botanicals | `fatuma@majisafi.tz` | `seller123` | seller, approved |
| Baraka Joseph — Msalaba Body Scrubs | `baraka@msalabasinscrub.tz` | `seller123` | seller, pending |
| Zawadi Peter | `zawadi@example.com` | `customer123` | customer |

## Build

```bash
flutter build apk --debug          # development build
flutter build apk --release        # signed release
```

`android/app/build.gradle.kts` uses Flutter's defaults
(`applicationId = com.example.ngozi_yangu`, SDK versions inherited from
`flutter.compileSdkVersion` etc.). Update the application ID before publishing.

## Tests and analysis

```bash
flutter analyze
flutter test
```

`test/recommendation_engine_test.dart` covers the scoring rules — that oily,
acne-prone skin prefers niacinamide over coconut oil, that a fragrance
sensitivity produces precautions, and that every recommendation returns at least
one explanation.

## Design

Material 3 with a botanical palette: seed `#2E7D5B`, brand dark `#1B5E40`. Role
accents are `#1B5E40` (customer), `#0F5132` (seller), `#1E3A8A` (admin). Currency
is formatted as integer TZS via `lib/core/formatters.dart`. Motion lives in
`lib/core/transitions.dart` and the custom widgets (magnetic/interactive buttons,
expandable sections, zoomable images, `AdvancedBottomNav`).

## Notes and limitations

- **Android only.** No `ios/`, `web/`, `linux/` or `macos/` directories exist;
  `run.sh` refuses to start without a connected Android device.
- **Payments are simulated.** No provider is contacted; the PIN handshake stands
  in for a callback. Real integration needs a provider API plus verified
  server-side webhooks.
- **Not a medical product.** The assessment and matches are cosmetic guidance,
  and the UI says so; there is no dermatological review of listings.
- **Auth is HMAC-SHA256 per-user salt**, not a dedicated KDF. Tokens are random
  rows in `sessions`; there is no refresh, expiry or rate limiting yet.
- **Uploads are on local disk** and `backend/uploads/` is not git-ignored —
  clean it before committing. Image type is limited to jpg/jpeg/png/webp/gif and
  filenames are pattern-checked against traversal.
- **CORS is `*`** and there is no HTTPS termination — deploy behind a reverse
  proxy and tighten both before production.
- `backend/.env.example` currently contains a real-looking database password;
  replace it with a placeholder and rotate the credential.
