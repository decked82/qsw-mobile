import '../../domain/entities/part.dart';
import '../../domain/repositories/part_repository.dart';
import '../data_sources/sqlite_part_data_source.dart';
import 'sqlite_part_save_repository.dart';
import '../models/part_model.dart';

class SqlitePartRepository implements PartRepository {
  SqlitePartRepository(this._dataSource, {required this._saveRepository});

  final SqlitePartDataSource _dataSource;
  final SqlitePartSaveRepository _saveRepository;

  @override
  Future<Part> addPart(Part part) async {
    final model = PartModel.fromEntity(part);
    return _saveRepository.addPart(model);
  }

  @override
  Future<List<Part>> getParts() async {
    return _dataSource.getParts();
  }

  @override
  Future<List<Part>> searchParts(String query) async {
    return _dataSource.searchParts(query);
  }

  @override
  Future<void> deletePart(int id) async {
    await _saveRepository.deletePart(id);
  }
}
