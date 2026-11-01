import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qsw_mobile/features/sync/data/data_sources/firestore_part_sync_data_source.dart';
import 'package:qsw_mobile/features/sync/domain/entities/pending_operation.dart';

const _syncId = 'part-sync-001';

final _createdAt = DateTime.utc(2026, 10, 1, 8);
final _updatedAt = DateTime.utc(2026, 10, 2, 9);

Map<String, dynamic> _payload({
  String syncId = _syncId,
  bool isDeleted = false,
  DateTime? updatedAt,
}) {
  return {
    'sync_id': syncId,
    'part_code': 'PART-001',
    'name': 'Test part',
    'specification': 'Test specification',
    'barcode': '123456789',
    'unit': 'PCS',
    'created_at': _createdAt.toIso8601String(),
    'updated_at': (updatedAt ?? _updatedAt).toIso8601String(),
    'is_deleted': isDeleted,
    'deleted_at': isDeleted ? _updatedAt.toIso8601String() : null,
  };
}

PendingOperation _operation({
  String type = 'CREATE',
  String entityType = 'PART',
  String entityId = _syncId,
  Map<String, dynamic>? payload,
  String? rawPayload,
}) {
  return PendingOperation(
    id: 1,
    operationId: 'operation-001',
    type: type,
    entityType: entityType,
    entityId: entityId,
    payload: rawPayload ?? jsonEncode(payload ?? _payload()),
    status: PendingOperationStatus.pending,
    retryCount: 0,
    createdAt: _createdAt,
  );
}

void main() {
  group('FirestorePartSyncDataSource', () {
    test('CREATE writes PART using sync_id as document ID', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestorePartSyncDataSource(firestore: firestore);

      await source.sync(_operation());

      final snapshot = await firestore.collection('parts').doc(_syncId).get();

      expect(snapshot.exists, isTrue);

      final data = snapshot.data()!;
      expect(data['sync_id'], _syncId);
      expect(data['part_code'], 'PART-001');
      expect(data['name'], 'Test part');
      expect(data['is_deleted'], isFalse);
      expect(data['synced_at'], isNotNull);
    });

    test('DELETE writes a tombstone', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestorePartSyncDataSource(firestore: firestore);

      await source.sync(
        _operation(type: 'DELETE', payload: _payload(isDeleted: true)),
      );

      final snapshot = await firestore.collection('parts').doc(_syncId).get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['is_deleted'], isTrue);
      expect(snapshot.data()!['deleted_at'], isNotNull);
    });

    test('repeated CREATE uses one stable document', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestorePartSyncDataSource(firestore: firestore);

      await source.sync(_operation());
      await source.sync(_operation());

      final snapshot = await firestore.collection('parts').get();

      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.id, _syncId);
    });

    test('older CREATE cannot overwrite newer DELETE', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestorePartSyncDataSource(firestore: firestore);

      await source.sync(
        _operation(
          type: 'DELETE',
          payload: _payload(
            isDeleted: true,
            updatedAt: DateTime.utc(2026, 10, 3, 10),
          ),
        ),
      );

      await source.sync(
        _operation(
          type: 'CREATE',
          payload: _payload(updatedAt: DateTime.utc(2026, 10, 2, 9)),
        ),
      );

      final snapshot = await firestore.collection('parts').doc(_syncId).get();

      expect(snapshot.data()!['is_deleted'], isTrue);
      expect(
        snapshot.data()!['updated_at'],
        DateTime.utc(2026, 10, 3, 10).toIso8601String(),
      );
    });

    test('DELETE wins when timestamps are equal', () async {
      final firestore = FakeFirebaseFirestore();
      final source = FirestorePartSyncDataSource(firestore: firestore);

      await source.sync(
        _operation(type: 'DELETE', payload: _payload(isDeleted: true)),
      );

      await source.sync(_operation());

      final snapshot = await firestore.collection('parts').doc(_syncId).get();

      expect(snapshot.data()!['is_deleted'], isTrue);
    });

    test('rejects payload with mismatched sync_id', () async {
      final source = FirestorePartSyncDataSource(
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(_operation(payload: _payload(syncId: 'another-part'))),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects CREATE with is_deleted true', () async {
      final source = FirestorePartSyncDataSource(
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(
          _operation(type: 'CREATE', payload: _payload(isDeleted: true)),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid JSON payload', () async {
      final source = FirestorePartSyncDataSource(
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(_operation(rawPayload: 'not-json')),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported entity type', () async {
      final source = FirestorePartSyncDataSource(
        firestore: FakeFirebaseFirestore(),
      );

      await expectLater(
        source.sync(_operation(entityType: 'BOX')),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
