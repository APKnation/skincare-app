-- 001_init.sql — Sura Yangu marketplace schema
CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  phone         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'customer',
  seller_status TEXT NOT NULL DEFAULT 'none',
  shop_name     TEXT,
  shop_location TEXT,
  shop_description TEXT,
  contact_info  TEXT,
  deactivated   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sessions (
  token      TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
  id                 TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name               TEXT NOT NULL,
  brand              TEXT NOT NULL DEFAULT '',
  category           TEXT NOT NULL,
  description        TEXT NOT NULL,
  price_tzs          INTEGER NOT NULL CHECK (price_tzs >= 0),
  image_url          TEXT,
  ingredients        TEXT[] NOT NULL DEFAULT '{}',
  suitable_skin_types TEXT[] NOT NULL DEFAULT '{}',
  targets_concerns   TEXT[] NOT NULL DEFAULT '{}',
  contains_flagged   TEXT[] NOT NULL DEFAULT '{}',
  is_comedogenic     BOOLEAN NOT NULL DEFAULT FALSE,
  usage_instructions TEXT NOT NULL DEFAULT '',
  side_effects       TEXT[] NOT NULL DEFAULT '{}',
  warnings           TEXT[] NOT NULL DEFAULT '{}',
  stock              INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  seller_id          TEXT NOT NULL REFERENCES users(id),
  shop_name          TEXT NOT NULL DEFAULT '',
  shop_location      TEXT NOT NULL DEFAULT '',
  approval           TEXT NOT NULL DEFAULT 'pending',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS products_approval_idx ON products (approval);
CREATE INDEX IF NOT EXISTS products_seller_idx ON products (seller_id);

CREATE TABLE IF NOT EXISTS skin_profiles (
  user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  skin_type     TEXT NOT NULL,
  concerns      TEXT[] NOT NULL DEFAULT '{}',
  sensitivities TEXT[] NOT NULL DEFAULT '{}',
  goals         TEXT[] NOT NULL DEFAULT '{}',
  notes         TEXT NOT NULL DEFAULT '',
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_items (
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  PRIMARY KEY (user_id, product_id)
);

CREATE TABLE IF NOT EXISTS orders (
  id              TEXT PRIMARY KEY,
  user_id         TEXT NOT NULL REFERENCES users(id),
  subtotal_tzs    INTEGER NOT NULL,
  delivery_fee_tzs INTEGER NOT NULL,
  total_tzs       INTEGER NOT NULL,
  recipient_name  TEXT NOT NULL,
  recipient_phone TEXT NOT NULL,
  address         TEXT NOT NULL,
  city            TEXT NOT NULL,
  delivery_notes  TEXT NOT NULL DEFAULT '',
  payment_method  TEXT NOT NULL,
  payment_status  TEXT NOT NULL DEFAULT 'unpaid',
  payment_ref     TEXT,
  status          TEXT NOT NULL DEFAULT 'placed',
  placed_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_lines (
  id            BIGSERIAL PRIMARY KEY,
  order_id      TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id    TEXT NOT NULL,
  name          TEXT NOT NULL,
  unit_price_tzs INTEGER NOT NULL,
  quantity      INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS order_events (
  id       BIGSERIAL PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status   TEXT NOT NULL,
  note     TEXT NOT NULL,
  at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
