import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/report_conversation_service.dart';
import '../../domain/report_message.dart';
import 'report_conversation_state.dart';

class ReportConversationCubit extends Cubit<ReportConversationState> {
  ReportConversationCubit(this._service, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance,
      super(const ReportConversationState());

  final ReportConversationService _service;
  final FirebaseAuth _auth;
  StreamSubscription<List<ReportMessage>>? _subscription;
  String? _reportId;

  String get currentUid => _auth.currentUser?.uid ?? '';

  void watch(String reportId) {
    if (_reportId == reportId && _subscription != null) return;
    _reportId = reportId;
    emit(
      state.copyWith(
        status: ReportConversationStatus.loading,
        errorMessage: '',
      ),
    );
    _subscription?.cancel();
    _subscription = _service
        .watchMessages(reportId)
        .listen(
          (messages) => emit(
            state.copyWith(
              status: ReportConversationStatus.loaded,
              messages: messages,
              errorMessage: '',
            ),
          ),
          onError: (_) => emit(
            state.copyWith(
              status: ReportConversationStatus.failure,
              errorMessage:
                  'Percakapan tidak dapat dimuat. Periksa akses dan koneksi.',
            ),
          ),
        );
  }

  Future<void> retry() async {
    final id = _reportId;
    if (id == null) return;
    await _subscription?.cancel();
    _subscription = null;
    _reportId = null;
    watch(id);
  }

  Future<void> send(String text, {XFile? image}) async {
    final id = _reportId;
    if (id == null || state.sending) return;
    final validation = ReportConversationService.validateMessage(
      text,
      hasImage: image != null,
    );
    if (validation != null) {
      emit(state.copyWith(errorMessage: validation));
      return;
    }
    emit(state.copyWith(sending: true, errorMessage: ''));
    try {
      await _service.send(id, text, image: image);
      emit(state.copyWith(sending: false));
    } on ReportConversationException catch (error) {
      emit(state.copyWith(sending: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          errorMessage: image == null
              ? 'Pesan gagal dikirim. Coba lagi.'
              : 'Gambar gagal diunggah atau pesan tidak terkirim. Coba lagi.',
        ),
      );
    }
  }

  Future<void> delete(String messageId) async {
    final id = _reportId;
    if (id == null) return;
    try {
      await _service.softDelete(id, messageId);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Pesan tidak dapat dihapus.'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
