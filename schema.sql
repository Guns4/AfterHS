-- Nightlife Ecosystem Indonesia - Core Schema (PostgreSQL)

-- 1) Users and Roles
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  password_hash TEXT,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE roles (
  id SMALLSERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE, -- user, venue, marketing, brand, influencer
  name TEXT NOT NULL
);

CREATE TABLE user_roles (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id SMALLINT NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id)
);

-- 2) Venues and Inventory
CREATE TABLE venues (
  id BIGSERIAL PRIMARY KEY,
  owner_user_id BIGINT REFERENCES users(id),
  name TEXT NOT NULL,
  category TEXT NOT NULL, -- club, bar, ktv, live_music, adult_wellness
  address TEXT,
  city TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE venue_floors (
  id BIGSERIAL PRIMARY KEY,
  venue_id BIGINT NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE venue_sections (
  id BIGSERIAL PRIMARY KEY,
  floor_id BIGINT NOT NULL REFERENCES venue_floors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE inventory_tables (
  id BIGSERIAL PRIMARY KEY,
  section_id BIGINT NOT NULL REFERENCES venue_sections(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  capacity INT NOT NULL,
  min_spend_cents BIGINT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 3) Booking Holds and Bookings
CREATE TABLE booking_holds (
  id BIGSERIAL PRIMARY KEY,
  table_id BIGINT NOT NULL REFERENCES inventory_tables(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', -- active, cancelled, expired, converted
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX booking_holds_active_idx
  ON booking_holds (table_id, start_time, end_time)
  WHERE status = 'active';

CREATE TABLE bookings (
  id BIGSERIAL PRIMARY KEY,
  table_id BIGINT NOT NULL REFERENCES inventory_tables(id) ON DELETE RESTRICT,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  hold_id BIGINT REFERENCES booking_holds(id) ON DELETE SET NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'confirmed', -- confirmed, cancelled, completed, no_show
  deposit_amount_cents BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX bookings_time_idx
  ON bookings (table_id, start_time, end_time);

-- 4) Payments and Transactions (Ledger Style)
CREATE TABLE payment_intents (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  provider TEXT NOT NULL, -- midtrans, xendit, etc
  provider_ref TEXT,
  amount_cents BIGINT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'IDR',
  purpose TEXT NOT NULL, -- booking_deposit, coin_topup
  status TEXT NOT NULL DEFAULT 'pending', -- pending, succeeded, failed, cancelled
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE wallets (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  balance_coins BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  type TEXT NOT NULL, -- gift_purchase, booking_deposit, coin_topup, refund
  payment_intent_id BIGINT REFERENCES payment_intents(id),
  total_cents BIGINT NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'IDR',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE transaction_items (
  id BIGSERIAL PRIMARY KEY,
  transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL, -- gift, deposit, fee, commission
  amount_cents BIGINT NOT NULL,
  direction TEXT NOT NULL, -- debit, credit
  counterparty_user_id BIGINT REFERENCES users(id),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE wallet_entries (
  id BIGSERIAL PRIMARY KEY,
  wallet_id BIGINT NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  transaction_id BIGINT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  amount_coins BIGINT NOT NULL,
  direction TEXT NOT NULL, -- debit, credit
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5) Live Sessions and Gifts
CREATE TABLE live_sessions (
  id BIGSERIAL PRIMARY KEY,
  host_user_id BIGINT NOT NULL REFERENCES users(id),
  venue_id BIGINT REFERENCES venues(id),
  status TEXT NOT NULL DEFAULT 'live', -- live, ended
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE TABLE live_gifts (
  id BIGSERIAL PRIMARY KEY,
  live_session_id BIGINT NOT NULL REFERENCES live_sessions(id) ON DELETE CASCADE,
  sender_user_id BIGINT NOT NULL REFERENCES users(id),
  recipient_user_id BIGINT NOT NULL REFERENCES users(id),
  gift_code TEXT NOT NULL,
  coins BIGINT NOT NULL,
  transaction_id BIGINT REFERENCES transactions(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6) Visits and Privacy Mode
CREATE TABLE visits (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  venue_id BIGINT NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  booking_id BIGINT REFERENCES bookings(id),
  visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  visibility TEXT NOT NULL DEFAULT 'public' -- public, private
);

CREATE INDEX visits_visibility_idx
  ON visits (user_id, visibility, visited_at);

