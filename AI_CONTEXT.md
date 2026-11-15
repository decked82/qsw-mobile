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


<!-- QSW_MULTI_TENANT_AUTHORIZATION_MODEL -->
## Multi-tenant architecture and authorization model

**Status: business rules agreed; implementation not started.**
This section describes the approved target model. It does not describe
implemented Dart classes, SQLite tables, Firestore collections or deployed
security rules.

### Identity, organization and membership

- Firebase Authentication identifies a person by Firebase UID. Authentication
  alone does not grant organization, warehouse or operation permissions.
- One Firebase Auth user may belong to multiple QSW organizations.
- A user's role is assigned independently in each organization.
- The target domain concepts are `Organization` and
  `OrganizationMembership`. Membership conceptually links `userId`,
  `organizationId`, role, membership status and accessible warehouse IDs.
  Exact fields, persistence and invitation lifecycle remain technical design
  work.
- Membership can be deactivated and restored. Deactivation does not delete
  the Firebase Auth account or historical operations.
- A user may have different roles and warehouse assignments in different
  organizations.
- The application must maintain an explicit active-organization context.
  Switching organizations must switch data and operation context without
  mixing tenant data or queued writes.
- An organization owns its shared part catalogue, organizational reference
  data and warehouses.

### Target data hierarchy

`Organization -> Warehouses -> Racks -> Cells`

Organization-level data:
- organization profile and settings;
- memberships and roles;
- shared part catalogue;
- external recipient organizations and other shared dictionaries;
- warehouses.

Warehouse-level data:
- warehouse-specific stock for organization-owned parts;
- rack/cell structure and stock placement;
- warehouse operations and warehouse-scoped audit events.

A part belongs to the organization, not to one warehouse. The same part may
be stored in several warehouses. Common part attributes are separate from
warehouse stock and cell allocation. A future multi-cell allocation model
must allow stock to be distributed among cells without making one cell the
sole location of an organization-wide part. The exact schema and migration
from current `locations`/`boxes` require separate inspection and design.

### Roles

- `OWNER`: organization owner; controls organization profile, ownership,
  high-level security, archival and organization-wide stock policy.
- `ADMIN`: manages members (except OWNER), warehouses and shared
  organizational reference data. ADMIN does not gain permission to conduct
  stock-moving operations merely by being an administrator.
- `WAREHOUSE_MANAGER`: manages assigned warehouse structure, warehouse-level
  part data and the warehouse operations explicitly granted below.
- `WORKER`: performs permitted warehouse operations and uses existing
  reference data; does not administer the organization or shared catalog.
- `GUEST`: read-only access within assigned warehouse scope.

OWNER and ADMIN have organization-wide oversight. WAREHOUSE_MANAGER, WORKER
and GUEST are restricted to explicitly assigned warehouses for warehouse
data. Role and warehouse scope must both be checked.

### Organization and membership permission matrix

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View organization | Yes | Yes | Yes | Yes | Yes |
| Edit organization profile | Yes | No | No | No | No |
| Transfer ownership | Yes | No | No | No | No |
| Appoint/remove OWNER | Yes | No | No | No | No |
| Appoint ADMIN | Yes | No | No | No | No |
| Invite members | Yes | Yes | No | No | No |
| Assign/change non-OWNER roles | Yes | Yes | No | No | No |
| Assign warehouse access | Yes | Yes | No | No | No |
| Deactivate/restore membership | Yes | Yes | No | No | No |
| View member list | Yes | Yes | No | No | No |
| Archive/restore organization | Yes | No | No | No | No |

ADMIN cannot appoint, remove or replace OWNER. The organization must retain
an owner. Membership deactivation does not erase the identity or history.

### Warehouse permission matrix

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View all organization warehouses | Yes | Yes | No | No | No |
| View assigned warehouses | Yes | Yes | Yes | Yes | Yes |
| Create/edit warehouse | No | Yes | No | No | No |
| Archive/restore warehouse | No | Yes | No | No | No |
| Change `allow_negative_stock` | Yes | Yes | No | No | No |

ADMIN creates, edits, archives and restores warehouses. OWNER has
organization-wide visibility and can change the stock policy but does not
administer warehouse records.

### Racks, cells and storage zones

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View | Yes | Yes | Assigned warehouses | Assigned warehouses | Assigned warehouses |
| Create/edit | No | Yes | Assigned warehouses | No | No |
| Archive/restore | No | Yes | Assigned warehouses | No | No |
| Use permitted locations in operations | No | No | Assigned warehouses | Assigned warehouses | No |

WAREHOUSE_MANAGER may create, edit, archive and restore racks/cells only in
assigned warehouses. A cell cannot be archived while stock remains allocated
to it. A rack cannot be archived while it contains non-empty cells. Stock
must first be moved to valid locations. Historical placement must be retained.
The exact emptiness check must account for active allocations and, if later
introduced, reservations/in-flight operations.

### Shared part catalogue

The organization-wide part master contains common attributes such as part
code, name, description, unit of measure, category and technical attributes.

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View/search | Yes | Yes | Yes | Yes | Yes |
| Create | Yes | Yes | No | No | No |
| Edit common attributes | Yes | Yes | No | No | No |
| Archive | Yes | Yes | No | No | No |
| Request new part | No | No | Yes | No | No |

WAREHOUSE_MANAGER cannot edit the shared part master. The manager may request
a missing part; OWNER/ADMIN reviews and creates it. Request statuses,
notifications, duplicate detection and workflow are not implemented or fully
specified. Parts used by operations must not be physically deleted. Archiving
must preserve historical references and must not silently erase stock.

### Warehouse-specific part data

Warehouse-specific data includes whether a catalogue part is held at a
warehouse, its storage placement, cell allocations and warehouse parameters.

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View | All warehouses | All warehouses | Assigned warehouses | Assigned warehouses | Assigned warehouses |
| Add existing catalogue part to warehouse | No | Yes | Assigned warehouses | No | No |
| Manage cell placement | No | Yes | Assigned warehouses | No | No |
| Edit warehouse parameters | No | Yes | Assigned warehouses | No | No |
| Directly edit stock quantity | No | No | No | No | No |

Stock quantity changes only through explicit warehouse operations. Direct
quantity editing is prohibited for every role.

### Organizational reference dictionaries

Examples: external recipient organizations, suppliers, units of measure and
shared classifications.

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View | Yes | Yes | Yes | Yes | Yes |
| Use in permitted operations | No | No | Yes | Yes | No |
| Create/edit/archive | Yes | Yes | No | No | No |
| Request new record | No | No | Yes | No | No |

External recipient organizations are counterparties, not QSW tenant
organizations. They do not become QSW members and receive no QSW access.
WAREHOUSE_MANAGER may request a missing counterparty; OWNER/ADMIN controls
creation and maintenance. Archived dictionary records cannot be selected for
new operations but remain resolvable in historical operations. Records used
by history are not physically deleted.

### Warehouse operations

Saved operations are immutable business-history records. Local save is the
business capture point; Firestore synchronization is a separate delivery
process. The agreed model has no separate DRAFT/POSTED stage.

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View operations/history | All warehouses | All warehouses | Assigned warehouses | Assigned warehouses | Assigned warehouses |
| Create inbound | No | No | Yes | Yes | No |
| Reverse inbound | No | No | Yes | No | No |
| Create internal transfer | No | No | Yes | Yes | No |
| Cancel internal transfer | No | No | Yes | Yes | No |
| Create external issue | No | No | Yes | Yes | No |
| Reverse external issue | No | No | Yes | No | No |

Inbound:
- WAREHOUSE_MANAGER and WORKER may create inbound operations at an
  accessible warehouse.
- Only WAREHOUSE_MANAGER may reverse inbound.
- Reversal is a separate linked corrective operation.

Internal transfer:
- Decreases source warehouse stock and increases destination warehouse stock.
- One logical operation/history record identifies both warehouses.
- WAREHOUSE_MANAGER and WORKER may create and cancel it, subject to access
  to the required warehouses.
- Cancellation is a reverse transfer, not editing/deleting the original.
- Incoming quantity may offset a negative destination balance subject to the
  organization stock policy.

External issue:
- WAREHOUSE_MANAGER and WORKER may create it; only WAREHOUSE_MANAGER may
  reverse it.
- Source warehouse, external recipient and document number are required.
- One document may contain multiple part lines and quantities.
- Recipient warehouse is not specified.
- Only the QSW source warehouse stock decreases.
- The recipient is a third-party counterparty, not a QSW tenant.

Immutability and correction:
- Editing and physical deletion of saved operations are prohibited.
- A correction is a separate reverse/cancellation operation with mandatory
  reason, unique operation ID and reference to the original operation.
- Reversal/cancellation must be idempotent and atomically update stock.
- The same original operation cannot be reversed/cancelled twice.
- Partial reversal has not been agreed and must not be implemented without
  a new business decision.
- If a corrective operation is itself wrong, create another correction;
  do not mutate historical records.

Negative stock:
- `allow_negative_stock` is organization-level and configurable by OWNER
  and ADMIN.
- Negative stock is allowed by default.
- When disabled, a new operation must not make the relevant balance negative.
- Existing negative balances are not automatically repaired.
- Validation must be atomic with stock mutation and enforced by trusted
  server-side logic for concurrent remote operations.
- Transfer cancellation must apply the same policy if destination stock has
  already been consumed.

### Stock visibility and audit

| Action | OWNER | ADMIN | WAREHOUSE_MANAGER | WORKER | GUEST |
|---|---|---|---|---|---|
| View/search stock | All warehouses | All warehouses | Assigned warehouses | Assigned warehouses | Assigned warehouses |
| View operation history | All warehouses | All warehouses | Assigned warehouses | Assigned warehouses | Assigned warehouses |
| View full organization audit | Yes | Yes | No | No | No |
| View assigned-warehouse audit | Yes | Yes | Yes | No | No |
| Edit/delete audit | No | No | No | No | No |

OWNER/ADMIN see organization-wide audit. WAREHOUSE_MANAGER sees audit only
for assigned warehouses. WORKER/GUEST cannot view the audit log. Audit is
append-only for normal application roles.

### Organization archival

Only OWNER may archive or restore an organization. Archiving preserves users,
warehouses, parts, reference data, stock history and audit history. New
warehouse operations are prohibited while archived. Archival must be audited.

Before archival, pending/in-flight synchronization must be checked and
archival blocked if such work is detected. A local SQLite check only sees
that device's outbox. A server cannot see an operation that has never left an
offline device. Therefore a cross-device synchronization barrier (for
example, a carefully designed device registration/lease or equivalent
protocol) is a required technical design item; do not claim a server-only
check proves every device is synchronized.

### Enforcement, SQLite, Firestore and SyncEngine requirements

- Flutter widget visibility is not an authorization boundary.
- Every protected read/write must be scoped to active organization and,
  where applicable, authorized warehouse.
- Firestore Security Rules must validate authenticated identity, active
  membership, organization scope, role and warehouse scope. Client-supplied
  organization IDs/roles must not be trusted without server validation.
- Sensitive atomic stock workflows may require trusted backend transactions
  or functions; client read/check/write is unsafe under concurrent devices.
- SQLite requires tenant scope on relevant business and outbox data, with
  repository queries that cannot mix organizations. Exact columns, indexes,
  composite keys, migration and backfill remain to be designed.
- Firestore paths/payloads must be tenant-scoped. Existing root collections
  must not be assumed safe for multi-tenant use.
- Each outbox operation must retain immutable organization identity and
  warehouse context where applicable. A retry must never infer its tenant
  from whichever organization is currently active.
- SyncEngine must validate session, membership and authorization before
  sending. Sign-out, organization switching, membership deactivation and
  archival must not redirect or silently discard queued operations.
- Tests must cover cross-tenant and cross-warehouse access, role escalation,
  inactive memberships, archived organizations and concurrent stock changes.

### Technical decisions still open

The business rules above are agreed; the following implementation details
are not yet decided:
- exact Organization/OrganizationMembership fields and identifiers;
- invitations, acceptance, duplicate membership prevention and ownership
  transfer safeguards;
- active-organization persistence and revocation behavior;
- exact warehouse assignment representation;
- mapping current `locations`/`boxes` to Rack/Cell;
- warehouse-part and multi-cell allocation schema;
- tenant-aware SQLite migration and legacy-data ownership/backfill;
- tenant-scoped Firestore schema and production Security Rules;
- trusted backend responsibilities for atomic stock workflows;
- cross-device archive synchronization barrier;
- part/counterparty request workflows;
- audit event schema, retention and scoped queries;
- queued-operation behavior after sign-out, membership revocation or archive.

### Current implementation boundary

At this documentation checkpoint, Firebase email/password authentication
infrastructure and isolated authentication UI exist. `AuthUser` contains
UID/email only. `LoginPage` and `AuthGate` exist but AuthGate is not connected
to QswApp. Organization, membership, roles, warehouse assignment, tenant-aware
SQLite/Firestore, production Security Rules and tenant-aware SyncEngine are
not implemented. This specification does not authorize immediate code
changes; implementation requires a separate staged architecture plan.
