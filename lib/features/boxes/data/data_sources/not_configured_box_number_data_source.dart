import 'box_number_data_source.dart';

class NotConfiguredBoxNumberDataSource implements BoxNumberDataSource {
  const NotConfiguredBoxNumberDataSource();

  @override
  Future<BoxNumberRange> reserveRange({
    required String dateKey,
    required int size,
  }) {
    throw StateError(
      'Box number generation requires Firebase/Firestore to be configured.',
    );
  }
}
