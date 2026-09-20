import '../entities/box.dart';

abstract interface class BoxRepository {
  Future<Box?> getByBoxNo(String boxNo);

  Future<List<Box>> getAll();

  Future<void> save(Box box);

  Future<void> saveAll(List<Box> boxes);

  Future<void> delete(String boxNo);
}
