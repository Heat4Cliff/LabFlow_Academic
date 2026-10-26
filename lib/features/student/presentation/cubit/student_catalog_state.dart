import '../../domain/student_models.dart';
import 'student_data_state.dart';

class StudentCatalogState {
  const StudentCatalogState({
    this.status = StudentLoadStatus.initial,
    this.assets = const [],
    this.laboratories = const [],
    this.query = '',
    this.category = 'Semua',
    this.labId = 'Semua',
    this.errorMessage = '',
  });

  final StudentLoadStatus status;
  final List<StudentAsset> assets;
  final List<StudentLaboratory> laboratories;
  final String query;
  final String category;
  final String labId;
  final String errorMessage;

  List<StudentAsset> get visibleAssets {
    final normalizedQuery = query.trim().toLowerCase();

    return assets
        .where((asset) {
          final matchQuery =
              normalizedQuery.isEmpty ||
              asset.name.toLowerCase().contains(normalizedQuery) ||
              asset.code.toLowerCase().contains(normalizedQuery) ||
              asset.category.toLowerCase().contains(normalizedQuery);

          final matchCategory =
              category == 'Semua' || asset.category == category;
          final matchLab = labId == 'Semua' || asset.labId == labId;

          return matchQuery && matchCategory && matchLab;
        })
        .toList(growable: false);
  }

  List<String> get categories {
    final values =
        assets
            .map((asset) => asset.category)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['Semua', ...values];
  }

  StudentCatalogState copyWith({
    StudentLoadStatus? status,
    List<StudentAsset>? assets,
    List<StudentLaboratory>? laboratories,
    String? query,
    String? category,
    String? labId,
    String? errorMessage,
  }) {
    return StudentCatalogState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      laboratories: laboratories ?? this.laboratories,
      query: query ?? this.query,
      category: category ?? this.category,
      labId: labId ?? this.labId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
