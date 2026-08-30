import '../entities/part.dart';
import '../repositories/part_repository.dart';

class GetParts {
  const GetParts(this.repository);

  final PartRepository repository;

  Future<List<Part>> call() {
    return repository.getParts();
  }
}
