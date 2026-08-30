import '../entities/part.dart';

abstract interface class PartRepository {
  Future<Part> addPart(Part part);

  Future<List<Part>> getParts();

  Future<List<Part>> searchParts(String query);

  Future<void> deletePart(int id);
}
