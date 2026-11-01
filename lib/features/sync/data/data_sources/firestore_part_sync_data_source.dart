import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/pending_operation.dart';
import 'remote_sync_data_source.dart';

class FirestorePartSyncDataSource implements RemoteSyncDataSource {
  const FirestorePartSyncDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Future<void> sync(PendingOperation operation) async {
    if (operation.entityType != 'PART') {
      throw ArgumentError('Unsupported entity type: ${operation.entityType}');
    }

    if (operation.type != 'CREATE' && operation.type != 'DELETE') {
      throw ArgumentError('Unsupported PART operation type: ${operation.type}');
    }

    final Object? decoded;

    try {
      decoded = jsonDecode(operation.payload);
    } on FormatException {
      throw const FormatException('Invalid PART payload JSON.');
    }

    if (decoded is! Map) {
      throw const FormatException('PART payload must be a JSON object.');
    }

    final payload = Map<String, dynamic>.from(decoded);

    final syncId = payload['sync_id'];
    if (syncId is! String ||
        syncId.trim().isEmpty ||
        syncId != operation.entityId) {
      throw const FormatException(
        'PART sync_id must match operation entityId.',
      );
    }

    final isDeleted = payload['is_deleted'];
    if (isDeleted is! bool) {
      throw const FormatException('PART is_deleted must be a boolean.');
    }

    final expectedDeleted = operation.type == 'DELETE';
    if (isDeleted != expectedDeleted) {
      throw const FormatException(
        'PART operation type does not match is_deleted.',
      );
    }

    final incomingUpdatedAt = _parseDateTime(payload['updated_at']);
    if (incomingUpdatedAt == null) {
      throw const FormatException(
        'PART updated_at must be a valid ISO-8601 date.',
      );
    }

    final document = firestore.collection('parts').doc(syncId);

    await firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(document);

      if (snapshot.exists) {
        final remoteData = snapshot.data();

        if (remoteData != null &&
            _shouldIgnoreIncomingOperation(
              incomingUpdatedAt: incomingUpdatedAt,
              incomingIsDeleted: isDeleted,
              remoteData: remoteData,
            )) {
          return;
        }
      }

      transaction.set(document, <String, dynamic>{
        ...payload,
        'synced_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  bool _shouldIgnoreIncomingOperation({
    required DateTime incomingUpdatedAt,
    required bool incomingIsDeleted,
    required Map<String, dynamic> remoteData,
  }) {
    final remoteIsDeleted = remoteData['is_deleted'] == true;
    final remoteUpdatedAt = _parseDateTime(remoteData['updated_at']);

    if (remoteIsDeleted && !incomingIsDeleted && remoteUpdatedAt == null) {
      return true;
    }

    if (remoteUpdatedAt == null) {
      return false;
    }

    if (incomingUpdatedAt.isBefore(remoteUpdatedAt)) {
      return true;
    }

    if (incomingUpdatedAt.isAtSameMomentAs(remoteUpdatedAt) &&
        remoteIsDeleted &&
        !incomingIsDeleted) {
      return true;
    }

    return false;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
