import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';

sealed class LaboratoryDetailState {
  const LaboratoryDetailState();
}

final class LaboratoryDetailLoading extends LaboratoryDetailState {
  const LaboratoryDetailLoading();
}

final class LaboratoryDetailFailure extends LaboratoryDetailState {
  const LaboratoryDetailFailure();
}

final class LaboratoryDetailLoaded extends LaboratoryDetailState {
  const LaboratoryDetailLoaded(this.laboratory);

  final Laboratory laboratory;
}

/// Memuat data awal laboratorium untuk form edit.
class LaboratoryDetailCubit extends Cubit<LaboratoryDetailState> {
  LaboratoryDetailCubit(this._service) : super(const LaboratoryDetailLoading());

  final LaboratoryService _service;

  Future<void> load(String laboratoryId) async {
    emit(const LaboratoryDetailLoading());
    try {
      emit(LaboratoryDetailLoaded(await _service.getLaboratory(laboratoryId)));
    } catch (_) {
      emit(const LaboratoryDetailFailure());
    }
  }
}
