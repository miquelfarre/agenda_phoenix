# Realtime sync standard (Flutter)

This app uses a consistent pattern for Supabase Realtime across repositories to avoid missed events and historical replays.

## Pattern

- Initial fetch:
  - Fetch from API/view first to populate local cache.
  - Set a server-based sync timestamp using server-provided rows:
    - Choose the most recent `updated_at` (or `inserted_at`) from the fetched rows.
    - Never derive from client time if real server timestamps are available.
- Start Realtime immediately after the fetch to minimize the window where CDC can be missed.
- CDC gating:
  - For INSERT/UPDATE: process only if `commit_timestamp > syncTs + 1s`.
  - For DELETE: always process (ignore the time gate).
- Channel filters:
  - Use filters such as `user_id = currentUser` to reduce noise and ensure privacy.

## Implementation

- Shared helper: `app_flutter/lib/core/realtime_sync.dart`
  - `setServerSyncTs` / `setServerSyncTsFromResponse`
  - `shouldProcessInsertOrUpdate()`
  - `shouldProcessDelete()`
  - `RealtimeUtils.subscribeTable()` wrapper
- Repositories adopting the standard:
  - `EventRepository` (events and event_interactions)
  - `SubscriptionRepository` (event_interactions → refetch subscriptions view)
  - `CalendarRepository`, `GroupRepository`, `EventInteractionRepository`

## UI wiring

- Repositories expose broadcast streams for screens to consume.
- For manual refresh (pull-to-refresh, app resume), call the repository `refresh()` method instead of invalidating stream providers.
- Example: `ref.read(subscriptionRepositoryProvider).refresh()`.

## Edge cases

- Empty initial data: if no rows exist, set `syncTs` to `now()` as a fallback.
- Bulk operations: expect multiple CDCs; consider a small debounce if refetch is expensive.
- Auth: apply the JWT/test token to the Realtime client before subscribing.

## Notes

- DELETE must bypass gating because user actions (e.g., delete/unsubscribe) often happen right after the initial fetch.
- Keep repository logging for: subscribe start, CDC received, gating decisions, and emissions to aid debugging.
