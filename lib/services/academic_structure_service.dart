import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Faculty → section → grade options for student registration (API-driven).
class AcademicStructureService {
  AcademicStructureService._();

  static final AcademicStructureService instance = AcademicStructureService._();

  static List<Map<String, dynamic>> _parseList(Map<String, dynamic> response) {
    if (response['success'] != true) return [];
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => e is Map<String, dynamic>
              ? e
              : Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getFaculties() async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.registrationFaculties,
      requireAuth: false,
    );
    return _parseList(response);
  }

  Future<List<Map<String, dynamic>>> getSectionsForFaculty(String facultyId) async {
    if (facultyId.isEmpty) return [];
    final response = await ApiClient.instance.get(
      ApiEndpoints.registrationSections(facultyId),
      requireAuth: false,
    );
    return _parseList(response);
  }

  Future<List<Map<String, dynamic>>> getGradesForSection(String sectionId) async {
    if (sectionId.isEmpty) return [];
    final response = await ApiClient.instance.get(
      ApiEndpoints.registrationGrades(sectionId),
      requireAuth: false,
    );
    return _parseList(response);
  }
}
