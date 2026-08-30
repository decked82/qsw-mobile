import '../entities/part.dart';
import '../repositories/part_repository.dart';

class SearchParts {
  SearchParts(this._repository);

  final PartRepository _repository;

  Future<List<Part>> call(String query) {
    return _repository.searchParts(query);
  }
}
