import '../entities/box.dart';
import '../repositories/box_repository.dart';

class GetBoxByBoxNo {
  final BoxRepository repository;

  const GetBoxByBoxNo(this.repository);

  Future<Box?> call(String boxNo) {
    return repository.getByBoxNo(boxNo);
  }
}
