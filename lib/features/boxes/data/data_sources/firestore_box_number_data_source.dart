import 'package:cloud_firestore/cloud_firestore.dart';

import 'box_number_data_source.dart';

class FirestoreBoxNumberDataSource implements BoxNumberDataSource {
  const FirestoreBoxNumberDataSource({required this._firestore});

  final FirebaseFirestore _firestore;

  @override
  Future<BoxNumberRange> reserveRange({
    required String dateKey,
    required int size,
  }) async {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be greater than zero.');
    }

    final document = _firestore.collection('box_sequences').doc(dateKey);

    return _firestore.runTransaction<BoxNumberRange>((transaction) async {
      final snapshot = await transaction.get(document);

      final currentNext = snapshot.exists
          ? ((snapshot.data()?['nextSequence'] as num?)?.toInt() ?? 1)
          : 1;

      final start = currentNext;
      final end = start + size - 1;
      final nextSequence = end + 1;

      transaction.set(document, {
        'nextSequence': nextSequence,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return BoxNumberRange(start: start, end: end);
    });
  }
}
