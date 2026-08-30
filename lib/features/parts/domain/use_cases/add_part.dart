import '../entities/part.dart';
import '../repositories/part_repository.dart';

class AddPart {
  const AddPart(this.repository);

  final PartRepository repository;

  Future<Part> call(Part part) {
    return repository.addPart(part);
  }
}
