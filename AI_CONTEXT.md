# QSW Mobile — AI Context

## Project
- Name: Quick Search in the Warehouse (QSW).
- Repository: https://github.com/decked82/qsw-mobile
- Platform: Flutter mobile application, Android first.
- Language: Dart.
- Architecture: feature-oriented modular monolith with domain, data
  and presentation layers.
- Local database: SQLite via sqflite.
- Remote services: Firebase Firestore.
- Dependency initialization: ServiceLocator.
- Current database schema version: 7.

## Features
- parts: part catalogue, search and CRUD operations.
- locations: storage locations.
- boxes: boxes, box repositories and box number allocation.
- movements: movement history and inbound transactions.
- sync: pending operations, synchronization metadata and SyncEngine.
- home: application home page.
- core: database, dependency injection, navigation, localization and theme.

## Data and synchronization
- SQLite is the local persistence layer.
- Inbound transactions create an inbound transaction record, a box
  record and a pending synchronization operation.
- These local changes and consumption of the next box number are
  performed in one SQLite transaction.
- Box number ranges are obtained through BoxNumberDataSource.
- Firestore integration includes box number allocation and remote
  synchronization of movements and inbound transactions.
- SyncEngine processes pending operations in batches, with a default
  limit of 50.
- Failed synchronization operations retain error information and
  increment their retry count.
- Startup synchronization starts asynchronously after `runApp()`.
- A sync attempt is also triggered after a successful inbound save.
- A sync attempt is triggered asynchronously after a successful local
  part creation in AddPartPage. A synchronization error does not undo
  the local save; the pending operation remains in the SQLite outbox.
- An integration test verifies recovery of a PROCESSING inbound
  operation from SQLite and its subsequent write through the Firestore
  adapter using FakeFirebaseFirestore.
- Before reading the pending queue, SyncEngine recovers stale operations
  left in PROCESSING by resetting them to PENDING.
- Successful recovery is cached per SyncEngine instance. If recovery itself
  fails, a later sync call retries it. If a status write fails and may leave
  an operation PROCESSING, the cache is invalidated so the next sync cycle
  can recover that operation without requiring an app restart.
- SyncEngine prevents concurrent calls from processing the queue
  simultaneously within the same instance.
- Synchronization is also triggered when the app returns to the resumed
  lifecycle state.
- The app's SyncEngine retries failed or locally retryable operations
  automatically with exponential delay, starting at 30 seconds and capped
  at 15 minutes. Retries are also scheduled when reading the pending queue
  fails; the current sync call still propagates the original error.
- When a local status write fails in a way that can leave an operation
  PROCESSING, the next sync cycle retries stale-operation recovery.
- Retries run in-process; they do not guarantee execution after the OS
  terminates the app or while its process is not running.

## Parts catalog synchronization schema
- SQLite schema version 7 adds `sync_id`, `is_deleted`, and `deleted_at`
  to the local `parts` table.
- A unique index named `idx_parts_sync_id` is created for `sync_id`.
- Existing parts are preserved during migration from schema version 6
  to version 7. Their local IDs remain unchanged.
- Existing rows retain `NULL` for `sync_id` and `deleted_at`, and `0`
  for `is_deleted`. Migration does not assign cross-device identities.
- This change prepares the local schema only. Bidirectional parts
  synchronization and propagation of part deletions are not implemented
  by this migration.

## Development environment
- Ubuntu Linux.
- Flutter 3.44.7 / Dart 3.12.2 (previously recorded; verify if changed).
- Android Studio.
- Main branch: main.
- Validation commands:
  - dart format lib test
  - flutter analyze
  - flutter test
  - flutter build apk

## Working rules for AI
1. Respond in Russian unless another language is requested.
2. Keep answers concise by default.
3. Before modifying code, inspect the current implementation and related tests.
4. Use the actual repository state rather than assuming old chat history
   describes the current code.
5. Make minimal changes; avoid unrelated refactoring.
6. When replacing a file, provide its full path and complete contents.
7. Provide copy-ready terminal commands and specify the working directory.
8. Never claim a test or build passed without evidence.
9. Do not repeat completed steps unnecessarily.
10. Preserve database migrations and existing tests.
11. Update DEVELOPMENT_STATUS.md after significant completed milestones.
12. Never expose secrets, credentials or private Firebase configuration.
13. Check Firestore security rules before production deployment. Do not
    assume development rules are safe for production.

## Source of truth
1. Current source code and Git history.
2. DEVELOPMENT_STATUS.md for the last recorded checkpoint.
3. This file for stable project architecture and working conventions.

If documentation conflicts with the code, investigate and update the
documentation rather than blindly following it.

- New local parts receive a UUID `sync_id` and creation/update timestamps when those values are not supplied.
- Part deletion is logical: rows are retained with `is_deleted = 1`, `deleted_at`, and `updated_at`; normal catalog queries exclude deleted rows.
- Existing legacy rows with `sync_id = NULL` are not assigned IDs automatically. The explicit `SqlitePartDataSource.reconcileLegacySyncIds()` method assigns UUIDs transactionally to eligible legacy rows, including soft-deleted rows. It refuses all assignments if a legacy row has a blank `part_code` or its code is duplicated across rows. It is not called automatically at app startup.

## Parts local synchronization outbox

- `SqlitePartSaveRepository` persists local part changes and their
  pending synchronization operations in the same SQLite transaction.
- Creating a part stores a `CREATE` / `PART` pending operation.
  The operation's `entityId` is the part's `sync_id`.
- Soft-deleting a part stores a `DELETE` / `PART` pending operation
  in the same transaction as the local deletion.
- Outbox payloads use `PartModel.toSyncMap()`, a dedicated remote
  representation that excludes the device-local SQLite `id` and
  serializes `is_deleted` as a boolean. The SQLite `toMap()` format
  remains separate and unchanged.
- CREATE and DELETE payload tests verify `sync_id`, absence of the
  local `id`, boolean `is_deleted`, and `deleted_at` for DELETE.
- `SqlitePartDataSource.addPart()` and `deletePart()` accept an optional
  `DatabaseExecutor`, allowing repository writes to participate in the
  surrounding SQLite transaction.
- `SqlitePartRepository` delegates add and delete operations to
  `SqlitePartSaveRepository`; reads and searches remain in the data source.
- If writing a pending operation fails, the SQLite transaction rolls
  back the corresponding local part change.
- Repeated deletion of an already deleted part does not enqueue another
  `DELETE` operation.
- Deleting a legacy part without a non-empty `sync_id` is rejected.
  Run `reconcileLegacySyncIds()` explicitly before deleting such a part.
- `FirestorePartSyncDataSource` handles `CREATE` and `DELETE`
  operations from the PART outbox.
- PART documents are written to the Firestore `parts` collection,
  using `sync_id` as the document ID. The remote payload excludes
  the device-local SQLite ID.
- The data source validates the payload JSON, `sync_id`, `entityId`,
  `is_deleted`, operation type and `updated_at`.
- Writes use a Firestore transaction and compare timestamps to avoid
  overwriting newer remote state. A remote tombstone wins over an
  incoming CREATE when timestamps are equal. A tombstone without a
  parseable remote timestamp conservatively blocks an incoming CREATE.
- `FirestoreRemoteSyncDataSource` routes `PART` operations to
  `FirestorePartSyncDataSource`; `ServiceLocator` registers the source.
- Automated tests cover CREATE, DELETE tombstones, stable document IDs,
  stale-operation protection, equal-timestamp deletion precedence,
  payload validation and router dispatch (11 PART Firestore tests).
- These tests use `FakeFirebaseFirestore`. The `parts` collection,
  remote field schema, security rules and compatibility with the
  production Firestore/ERP contract have not been verified against
  a live environment.


## Authentication UI

### Existing authentication architecture

- Authentication is organized as a feature module under
  `lib/features/auth`.
- `AuthRepository` defines the domain contract for authentication:
  observing authentication state, accessing the current user,
  signing in with email and password, and signing out.
- `AuthUser` represents the authenticated user with a Firebase UID
  and optional email address.
- `AuthException` represents authentication errors using error codes.
- `FirebaseAuthRepository` delegates authentication operations
  to the configured authentication data source.
- `FirebaseAuthDataSource` integrates with Firebase Authentication.
- `NotConfiguredAuthDataSource` provides a fallback when Firebase
  Authentication is not configured.

### Authentication presentation

- `LoginPage` is implemented at
  `lib/features/auth/presentation/pages/login_page.dart`.
- The page receives an `AuthRepository` dependency.
- It provides email and password input, form validation,
  asynchronous sign-in, duplicate-submission prevention,
  and user-facing error messages.
- Email input is trimmed before authentication.
- Password input is preserved without trimming.
- Authentication errors are translated into localized messages.
- Successful sign-in does not perform navigation directly.
  Authentication state changes are observed by `AuthGate`.

- `AuthGate` is implemented at
  `lib/features/auth/presentation/widgets/auth_gate.dart`.
- It receives an `AuthRepository` and an authenticated child widget.
- It observes `authStateChanges` and uses `currentUser` as initial data.
- Signed-out users are presented with `LoginPage`.
- Authenticated users are presented with the supplied child.
- Loading and authentication stream error states are handled.
- A retry action allows the authentication stream subscription
  to be recreated after an error.

### Localization

- Authentication UI strings are added to
  `lib/core/localization/app_localizations.dart`.
- English, Korean and Russian translations are provided.
- The existing localization mechanism is retained.

### Current integration boundary

- `LoginPage` and `AuthGate` are implemented and tested independently.
- `AuthGate` is NOT yet connected to `QswApp`.
- Existing application navigation through `AppRouter` remains unchanged
  by this isolated presentation stage.
- A sign-out control has not yet been added to the application UI.
- Authentication UI gating alone does not protect Firestore data
  or authorize synchronization operations.
- Organization membership, roles, warehouse access and Firestore
  security rules require separate implementation and verification.

### Authentication presentation tests

- `test/features/auth/presentation/pages/login_page_test.dart`
  covers form validation, successful repository invocation,
  and authentication error presentation.
- `test/features/auth/presentation/widgets/auth_gate_test.dart`
  covers loading, signed-out, signed-in and stream error states.
