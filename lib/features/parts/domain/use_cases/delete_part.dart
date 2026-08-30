import '../repositories/part_repository.dart';

class DeletePart {
  const DeletePart(this.repository);

  final PartRepository repository;

  Future<void> call(int id) {
    return repository.deletePart(id);
  }
}
