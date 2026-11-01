# QSW Mobile — Development Status

## Last recorded checkpoint
- Branch: main
- Commit: b4979da
- Commit message: feat(sync): add Firestore PART synchronization
- Git working tree is not clean.
- Existing tracked modification: `lib/features/movements/presentation/pages/inbound_page.dart`.
- Numerous untracked backups and helper scripts are present.
- These pre-existing local files must be preserved.

The Git state above was checked on 2026-11-01.
Verify the current Git state before continuing work.

## Recent development
- b4979da — add Firestore PART synchronization.
- a5e1678 — add atomic local PART synchronization outbox.
- 0c3b61e — add legacy PART sync ID reconciliation.
- 5624c97 — prepare local PART records for synchronization.
- c7ebbf3 — test Firestore sync recovery after restart.

## Confirmed implementation from inspected source
- SQLite database migrations through version 7.
- Parts, locations, boxes, movements and sync modules.
- Inbound transaction use case validates part number, quantity and location.
- Box number range reservation is handled before the local transaction.
- Saving an inbound transaction, box and pending sync operation is atomic.
- The box sequence advances within the same local transaction.
- Firestore data sources exist for box number allocation, movements
  and inbound transactions.
- SyncEngine processes pending operations and records success or failure.
- Automated tests exist for database migrations, repositories,
  inbound transactions, box numbering, sync logic and UI components.

### Parts catalog synchronization schema
- SQLite schema version 7 adds `sync_id`, `is_deleted`, and `deleted_at`
  to the `parts` table and creates the unique index `idx_parts_sync_id`.
- The targeted migration test for version 6 to version 7 passed:
  existing part data and its local ID were preserved, the new columns
  had the expected initial values, and the unique index was present.
- The complete `sqlite_migrations_test.dart` suite passed with 10 tests.
- Legacy parts are not assigned a `sync_id` during migration; their
  `sync_id` remains `NULL` to avoid assuming cross-device identity.
- PART local changes are persisted through a transactional SQLite outbox.
- Firestore synchronization for PART `CREATE` and `DELETE` operations
  is implemented through `FirestorePartSyncDataSource`.
- `FirestoreRemoteSyncDataSource` routes `PART` operations to this source,
  and `ServiceLocator` registers it.
- The Firestore data source uses `sync_id` as the document ID in the
  `parts` collection and applies timestamp/tombstone conflict protection.
- Eleven automated tests cover the PART Firestore data source and router.
- Tests use `FakeFirebaseFirestore`; the collection/schema assumptions,
  production security rules and live Firestore behavior remain unverified.

## Verification
- Latest Git checkpoint inspected: `b4979da`.
- `flutter test test/features/sync`: 76 tests passed.
- Full-project `flutter test` was not confirmed in this audit.
- Full-project `flutter analyze` and `dart format lib test` were not
  rerun as part of this audit.
- Android APK build and real-device verification remain outstanding.
- Package resolution reported 41 packages with newer versions
  incompatible with the current dependency constraints. No dependency
  upgrades were performed as part of this audit.

## Open work
- The next functional development task has not yet been established.
- Do not infer unfinished requirements from commit messages alone.
- Before selecting the next task, review recent changes, current tests
  and the user's intended next feature.

## Start here
1. Check git status and the current commit.
2. Read AI_CONTEXT.md.
3. Inspect only the files relevant to the requested task.
4. Confirm assumptions where requirements or implementation are unclear.
5. Implement, test and document the result.
6. Update this file after a significant milestone.

---

## Development roadmap and continuation plan

Last updated: 2026-10-10

### Project goal

QSW (Quick Search in the Warehouse) is an Android-first Flutter application
for warehouse workers. The goal is to use smartphones to identify boxes and
parts, record warehouse operations, and quickly find where parts are stored.

Development principles:
- Work in small, testable increments.
- Inspect existing implementation before changing it.
- Preserve the feature-oriented architecture and SQLite abstractions.
- Keep warehouse operations available locally when the network is unavailable.
- Synchronize local operations with Firestore.
- Add automated tests for business logic and database changes.
- Do not claim a feature is complete until its tests and relevant manual checks pass.
- Keep Git history clean and create checkpoints after verified milestones.

### Current implementation checkpoint

Implemented or present in the codebase:
- Flutter application foundation, navigation, localization, and dependency setup.
- Parts, locations, boxes, and movements modules.
- SQLite database, migrations, and repositories.
- Inbound transaction use case.
- Atomic local saving of an inbound transaction, box, and pending sync operation.
- Box number allocation with date-based ranges.
- SQLite pending-operation queue with PENDING, PROCESSING, SYNCED, and FAILED states.
- Sync engine with error recording, retry counter updates, and per-operation failure handling.
- Firestore data sources for inbound transactions and movements.
- Firestore document IDs based on operation IDs.
- Automated tests for important database, inbound transaction, and synchronization behavior.

Important limitations or unverified behavior:
- Before reading the pending queue, SyncEngine recovers stale PROCESSING
  operations to PENDING. If a local status write can leave an operation in
  PROCESSING, recovery is retried on the next sync cycle in the same engine.
- Startup synchronization runs asynchronously after runApp().
- A sync attempt is triggered after a successful inbound save.
- App-resume synchronization is implemented.
- The app's SyncEngine retries failed or locally retryable operations
  in-process with exponential backoff, starting at 30 seconds and capped
  at 15 minutes. Automatic retries also cover pending-queue read failures;
  the current sync call still propagates the original error. This does not
  provide OS-managed background execution when the app process is terminated.
- Automated tests cover PROCESSING recovery, FAILED-operation retry,
  retry handling after local status-write failures and pending-queue read
  failures, and Firestore document idempotency when the remote write
  succeeds but the local SYNCED update fails.
- The full test suite and static analyzer passed on 2026-10-24:
  165 tests passed and flutter analyze reported no issues. The suite
  includes SQLite PROCESSING recovery followed by a Firestore-adapter
  write verified with FakeFirebaseFirestore.
- Real-device behavior under network loss, forced process termination,
  and subsequent app restart has not been verified in this checkpoint.
- Real-device barcode/QR scanning has not been implemented in the inspected UI.
- The Shipping home-page button has no navigation handler.
- The Inventory home-page button currently opens the parts page; a separate inventory workflow is not established.
- Safe multi-user Firestore security rules have not been implemented. Existing rules permit unrestricted reads and writes and are unsafe for production.
- Last recorded validation on 2026-10-24: formatting, static analysis,
  and the full test suite passed (160 tests). Re-run validation after
  subsequent code changes. Android APK build status is not confirmed.

### Roadmap

#### Phase 1 — Make local-to-Firestore synchronization reliable
Priority: IN PROGRESS

1. [x] Inspect synchronization startup, dependency registration,
   call sites, and app lifecycle handling.
2. [x] Establish synchronization triggers: app launch, successful
   inbound save, and app resume.
3. [x] Implement recovery of stale PROCESSING operations and test
   the SQLite repository and SyncEngine behavior.
4. [x] Verify FAILED-operation retry behavior and error handling
   using automated tests.
5. [x] Verify idempotent Firestore retries when a remote write
   succeeds but the local operation is not marked SYNCED.
6. [x] Add automated tests for recovery scenarios.
7. [x] Run formatting, static analysis, and the full test suite.

Acceptance criteria:
- Automated tests verify recovery of stale PROCESSING operations on a later
  sync cycle, including recoverable local status-write failures.
- Automated tests verify retries for failed operations and Firestore
  idempotency when the remote write succeeds but the local SYNCED update fails.
- One failed operation does not prevent subsequent operations from being
  processed, as verified by the relevant automated tests.
- Relevant tests pass and the results are documented.
- Real-device behavior under network loss and process termination is tracked
  separately and must be verified before declaring synchronization fully
  reliable in production.

#### Phase 2 — Complete inbound workflow and barcode/QR scanning

1. Review the existing inbound workflow and its validation.
2. Identify which barcode formats are actually used on warehouse labels.
3. Add camera scanning with a suitable Flutter package.
4. Prioritize QR scanning for existing box numbers, including the known BOX NO format.
5. Connect scanned identifiers to local lookup and provide understandable feedback for unknown codes.
6. Preserve manual entry as a fallback.
7. Test successful scans, invalid values, unknown parts, and network-unavailable behavior.

Acceptance criteria:
- A worker can record an inbound transaction with minimal manual typing.
- Scanning does not bypass quantity, part, or location validation.
- Existing manual-entry behavior remains usable.

#### Phase 3 — Box and part lookup

1. Define lookup behavior for BOX NO and part numbers.
2. Search local SQLite data first so lookup can work offline.
3. Show the part, quantity, box number, and recorded storage location where available.
4. Define how local data is refreshed or synchronized.
5. Test missing identifiers and multiple boxes/locations for the same part.

Acceptance criteria:
- A worker can scan or enter an identifier and find the corresponding local warehouse record.
- Results distinguish boxes and storage locations rather than assuming one part has only one location.

#### Phase 4 — Shipping/outbound workflow

1. Define outbound business rules before implementation.
2. Connect the Shipping menu item to its page.
3. Support box/part identification and quantity validation.
4. Prevent invalid quantities and shipping more stock than is available.
5. Save outbound records and pending sync operations atomically.
6. Add automated tests for stock changes, rollback, and repeated operations.

Acceptance criteria:
- Outbound transactions update local stock consistently.
- Invalid operations do not partially modify the database.
- Offline transactions can be synchronized later.

#### Phase 5 — Inventory and stock reconciliation

1. Define what an inventory count means in the application.
2. Distinguish recorded stock from physically counted stock.
3. Record discrepancies and require an explicit adjustment operation where appropriate.
4. Add history and tests for inventory adjustments.
5. Give the Inventory menu its own workflow rather than routing to the parts-management page.

Acceptance criteria:
- Physical counts can be recorded and compared with expected quantities.
- Stock adjustments are explicit, traceable, and synchronized.

#### Phase 6 — Production readiness and multi-user Firebase

1. Define user identity and authentication requirements.
2. Replace unrestricted Firestore rules with rules appropriate to the chosen access model.
3. Protect box sequence allocation from collisions across devices.
4. Review concurrent operations and consistency of stock updates.
5. Review security, error handling, logging, backup, and recovery.
6. Test with multiple devices and users before production use.

Acceptance criteria:
- Unauthenticated or unauthorized clients cannot freely read or modify warehouse data.
- Concurrent operations do not silently allocate duplicate identifiers or corrupt stock.
- Multi-device behavior has been tested against the chosen business rules.

### Working procedure for every development task

1. Read AI_CONTEXT.md and this section of DEVELOPMENT_STATUS.md.
2. Inspect the relevant implementation and tests before editing.
3. State the specific task and its acceptance criteria.
4. Make the smallest appropriate change.
5. Run:
   - dart format lib test
   - flutter analyze
   - flutter test
6. Run an Android build or device smoke test when relevant.
7. Report actual results; do not describe unexecuted checks as passing.
8. Update this file when the checkpoint, roadmap, or next task changes.
9. Commit verified changes with a descriptive Git commit message.

### Exact continuation point

The SyncEngine startup, lifecycle triggers, retry behavior, Firestore
idempotency and recovery of operations left in `PROCESSING` have been
inspected.

#### Synchronization triggers and lifecycle

- `main.dart` initializes Firebase and `ServiceLocator`, then calls
  `runApp`. Initial synchronization is started asynchronously afterward
  and does not block the initial UI.
- `app.dart` observes application lifecycle changes and requests
  synchronization when the app enters `AppLifecycleState.resumed`.
- The inbound flow requests synchronization after a successful local
  inbound transaction save.
- `ServiceLocator` provides a singleton SyncEngine with automatic retry
  enabled.
- Concurrent synchronization requests share the same in-progress Future.

#### PROCESSING recovery and retry behavior

- Before reading the pending queue, SyncEngine recovers operations left
  in `PROCESSING` by returning them to `PENDING`.
- Successful recovery is cached for the lifetime of the SyncEngine
  instance. Failed recovery is retried rather than permanently cached.
- Status-write failures that may leave an operation in `PROCESSING`
  invalidate the recovery cache.
- Automatic retry uses exponential backoff from 30 seconds up to
  15 minutes.
- Timer-based retries work only while the application process is alive.
  There is no OS-managed background scheduler guaranteeing execution
  after Android terminates the process.
- The pending queue processes `PENDING` and `FAILED` operations, with
  `PENDING` taking priority. The default batch size is 50.
- A failed operation does not prevent the rest of the current batch
  from being processed; processing stops before the next batch and
  a retry is scheduled.
- Firestore idempotency is covered for the case where the remote write
  succeeds but the local transition to `SYNCED` fails.

#### Latest synchronization validation

Validated on 2026-11-01:
- `flutter test test/features/sync`: 76 tests passed.
- These tests include SyncEngine, pending-operation recovery and
  Firestore synchronization behavior.
- Automated tests use local SQLite test databases and
  `FakeFirebaseFirestore`; they do not replace live Firestore or
  physical-device verification.

Still outstanding:
- Verify network loss and restoration on an Android device or emulator.
- Force-stop or terminate the app while an operation is processing,
  then relaunch and verify recovery and eventual synchronization.
- Verify behavior with the actual Firebase project, Firestore schema
  and production security rules.
- Run full-project validation and an Android APK build when appropriate.

Next:
1. Review the documentation diff.
2. Verify the synchronization scenarios on an Android device or emulator.
3. Record only the checks that were actually executed.
4. Create a Git checkpoint after reviewing the final diff.

### Instructions for a new ChatGPT conversation

Start by reading AI_CONTEXT.md and DEVELOPMENT_STATUS.md from the repository.
Use the current Git state as the source of truth for implementation status.
Continue from "Exact continuation point" above.
Do not redesign or rewrite existing features without inspecting their current code and tests first.

### Local parts synchronization preparation — validated
- New parts receive a UUID `sync_id` and creation/update timestamps when these values are not supplied.
- Part deletion is logical: rows are retained with `is_deleted = 1`, `deleted_at`, and `updated_at`; normal catalog queries exclude deleted rows.
- Existing legacy rows with `sync_id = NULL` are preserved. Explicit transactional reconciliation assigns UUIDs to eligible rows, including soft-deleted rows, and refuses assignments when legacy rows have blank or conflicting `part_code` values. Reconciliation is not automatic at app startup.
- Regression coverage includes supplied metadata, distinct IDs for new parts, search exclusion of deleted parts, and repeated soft deletion.
- Latest validation passed: `dart format lib test`, `flutter analyze`, `flutter test` (173 tests), and `git diff --check`.

## Parts local CREATE/DELETE outbox — verified

- Added `SqlitePartSaveRepository` to persist part changes and their
  pending synchronization operations atomically.
- Part creation enqueues `CREATE` / `PART`; soft deletion enqueues
  `DELETE` / `PART`. Both operations use the part's `sync_id` as
  `entityId`.
- Both outbox payloads are serialized with `PartModel.toSyncMap()`.
  This remote representation excludes the local SQLite `id` and
  stores `is_deleted` as a boolean; the SQLite `toMap()` format
  remains unchanged.
- Tests verify the CREATE and DELETE payload contracts, including
  `deleted_at` on DELETE.
- The data source accepts a transaction executor so the part row
  and pending operation are written through the same SQLite transaction.
- A failed pending-operation insert rolls back the corresponding
  part write or soft deletion.
- Repeated deletion does not enqueue a duplicate `DELETE`.
- Deletion of a legacy part without `sync_id` is rejected without
  changing the row or adding a pending operation.
- `SqlitePartRepository` delegates writes to `SqlitePartSaveRepository`;
  dependency registration is updated in `ServiceLocator`.
- Focused Parts repository tests passed: 13 tests.
- Full test suite passed: 176 tests.
- `flutter analyze` completed with no issues.
- The touched Dart files were formatted. A full-project
  `dart format lib test` run has not been confirmed for this checkpoint.
- Firestore `PART` CREATE and DELETE handling is implemented through
  `FirestorePartSyncDataSource` and routed by
  `FirestoreRemoteSyncDataSource`.
- The remote data source and router have 11 automated tests using
  `FakeFirebaseFirestore`. Live Firestore behavior and production
  security rules remain unverified.
