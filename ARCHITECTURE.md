# Nightlife Ecosystem Indonesia - Backend Architecture Overview

## 1. Scope
- Backend architecture only (no UI).
- Focus areas: real-time floor plan booking, live gifting, and privacy mode.

## 2. Core Principles
- Strong consistency for booking inventory.
- Event-driven, low-latency ingestion for likes and gifts.
- Privacy-by-design with query-level visibility controls.

## 3. High-Level Components
- API Gateway: Auth, rate limits, request validation.
- Core Services (Node.js/TypeScript):
  - Booking Service: floor inventory, holds, confirmations.
  - Live Service: live sessions, gifts, likes, streamer analytics.
  - Payments Service: PSP integration (Midtrans), payment intents.
  - Wallet/Ledger Service: Night-Coins, balances, transaction ledger.
  - Social Feed Service: posts, activity feed, privacy filtering.
- Data Stores:
  - PostgreSQL: source of truth for users, inventory, bookings, transactions.
  - Redis: hot counters, short-lived booking holds, caching.
- Realtime/Streaming:
  - ZEGOCLOUD for live audio/video and gift event triggers.

## 4. Floor Plan Booking Synchronization (Anti Double-Booking)
### 4.1 State Model
- Table state is derived from bookings + active holds.
- A hold is a short-lived reservation to prevent race conditions during checkout.

### 4.2 Pessimistic Locking Flow
1. User selects a table and desired time window.
2. Booking Service issues a transaction:
   - Lock the `inventory_table` row with `SELECT ... FOR UPDATE`.
   - Validate no overlapping confirmed booking.
   - Validate no overlapping active hold (expire stale holds).
3. Create a `booking_holds` record with TTL (e.g., 5-10 minutes).
4. Commit transaction.
5. If user confirms and pays within TTL:
   - Lock the same `inventory_table` row again.
   - Validate hold is still active and owned by requester.
   - Convert hold to confirmed booking; release hold.
6. If TTL expires or user cancels, hold is invalidated.

### 4.3 Conflict Handling
- If lock contention occurs, return a fast retry response with jittered backoff.
- If overlap detected, return "not available" and show alternate tables.

### 4.4 Peak Hours Protection
- Short TTL + pessimistic lock avoids double-booking.
- Use Redis to cache table availability but always confirm in PostgreSQL.

## 5. Live Gifting and Likes
### 5.1 Gift Flow
1. Client sends gift event with live session and recipient.
2. Live Service validates and emits gift event.
3. Wallet/Ledger Service writes:
   - Transaction (type = gift).
   - Transaction items (sender debit, recipient credit, platform fee).
4. Aggregate counts and revenue metrics asynchronously.

### 5.2 High-Throughput Likes
- Use Redis as the hot counter (e.g., `INCR` per like).
- Periodic aggregation:
  - Every 1-5 seconds, flush counters to PostgreSQL in batches.
- Optional for sustained spikes:
  - Add Kafka or Redis Streams to buffer like events and parallelize consumers.

## 6. Privacy Mode (Adult/Wellness)
- `venue.category = 'adult_wellness'` or explicit booking privacy flag.
- `visits` table stores `visibility = private` for those categories.
- Social feed queries filter out `visibility = private`.
- User history queries always include private records.

## 7. Data Integrity
- Foreign keys on all relational references.
- Ledger-style transactions with immutable items.
- Booking holds enforce TTL and ownership constraints.

## 8. Stack Confirmation
- Node.js/TypeScript: suitable for event-driven services.
- PostgreSQL: strong ACID guarantees for booking and ledger.
- Redis: low-latency counters and caching.
- ZEGOCLOUD: live SDK supporting virtual gifts.
- Midtrans: primary payments, schema extensible to other PSPs.

