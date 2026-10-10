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
- Current database schema version: 6.

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
