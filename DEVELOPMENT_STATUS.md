# QSW Mobile — Development Status

## Last recorded checkpoint
- Branch: main
- Commit: a69cd77
- Commit message: test: verify inbound transaction rollback
- Last recorded Git status: clean; main matched origin/main.

Verify the current Git state before continuing work.

## Recent development
- 400c1e7 — remove Firebase smoke test UI.
- 66f5105 — add inbound transactions and box number allocation.
- cae9af2 — remove legacy inbound movement flow.
- 4db03e3 — save inbound boxes atomically.
- a69cd77 — verify inbound transaction rollback.

## Confirmed implementation from inspected source
- SQLite database migrations through version 6.
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

## Verification
- The latest commit concerns rollback testing.
- The full current test/build status has not been independently verified
  in this checkpoint.
- Run the relevant tests before making further changes.

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
- Recovery of operations left in PROCESSING after app termination has not been established.
- Sync startup and retry behavior across app launches must be inspected.
- Real-device barcode/QR scanning has not been implemented in the inspected UI.
- The Shipping home-page button has no navigation handler.
- The Inventory home-page button currently opens the parts page; a separate inventory workflow is not established.
- Safe multi-user Firestore security rules have not been implemented. Existing rules permit unrestricted reads and writes and are unsafe for production.
- Current full test-suite, analyzer, and APK build status must be verified after subsequent changes.

### Roadmap

#### Phase 1 — Make local-to-Firestore synchronization reliable
Priority: NEXT

1. Inspect main.dart, ServiceLocator, SyncEngine call sites, and app lifecycle handling.
2. Establish when synchronization starts: app launch, inbound save, app resume, or other triggers.
3. Define and implement recovery for stale PROCESSING operations after interruption.
4. Verify retries for FAILED operations and behavior when connectivity or Firestore requests fail.
5. Verify idempotent retries when the Firestore write succeeds but the local operation is not marked SYNCED.
6. Add or update automated tests for recovery and retry scenarios.
7. Run formatting, static analysis, and the full test suite.

Acceptance criteria:
- A process interruption does not permanently strand an operation in PROCESSING.
- Failed operations can be retried without creating duplicate business documents.
- One failed operation does not prevent subsequent operations from being processed.
- Relevant tests pass and the result is documented.

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

The next task is Phase 1, step 1: inspect synchronization startup and lifecycle behavior.

Inspect:
- lib/main.dart
- lib/core/di/service_locator.dart
- lib/features/sync/domain/services/sync_engine.dart
- all Dart call sites of syncPendingOperations and SyncEngine
- any app lifecycle observers

Then determine the smallest safe change needed to recover stale PROCESSING operations. Do not start barcode scanning or shipping until the synchronization recovery plan is understood and the current task is verified.

### Instructions for a new ChatGPT conversation

Start by reading AI_CONTEXT.md and DEVELOPMENT_STATUS.md from the repository.
Use the current Git state as the source of truth for implementation status.
Continue from "Exact continuation point" above.
Do not redesign or rewrite existing features without inspecting their current code and tests first.
