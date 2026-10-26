import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/borrow_request_service.dart';
import '../../domain/borrow_request.dart';
import 'admin_borrow_requests_state.dart';

/// Mengelola state halaman antrean peminjaman Lab Admin.
///
/// Alur dependency:
///
/// AdminBorrowRequestsPage
///   ↓
/// AdminBorrowRequestsCubit
///   ↓
/// LabMembershipService + BorrowRequestService
///   ↓
/// Cloud Firestore
///
/// Cubit tidak berkomunikasi langsung dengan Firestore. Seluruh akses data
/// tetap didelegasikan ke service agar presentation state dan data access
/// memiliki tanggung jawab yang terpisah.
class AdminBorrowRequestsCubit extends Cubit<AdminBorrowRequestsState> {
  AdminBorrowRequestsCubit(this._membershipService, this._borrowRequestService)
    : super(const AdminBorrowRequestsState());

  final LabMembershipService _membershipService;
  final BorrowRequestService _borrowRequestService;

  StreamSubscription<List<LabMembership>>? _membershipSubscription;
  StreamSubscription<List<Laboratory>>? _laboratorySubscription;
  StreamSubscription<List<BorrowRequest>>? _requestSubscription;

  List<LabMembership> _memberships = const <LabMembership>[];
  List<Laboratory> _allLaboratories = const <Laboratory>[];

  bool _membershipsReady = false;
  bool _laboratoriesReady = false;
  String? _requestLabId;

  /// Memulai listener membership dan laboratorium aktif.
  ///
  /// Dua sumber data tersebut digabungkan di Cubit agar halaman tidak perlu
  /// memiliki nested StreamBuilder seperti implementasi sebelumnya.
  void start() {
    if (_membershipSubscription != null || _laboratorySubscription != null) {
      return;
    }

    emit(
      state.copyWith(
        status: AdminBorrowRequestsStatus.loading,
        errorMessage: '',
      ),
    );

    _membershipSubscription = _membershipService
        .watchCurrentLabAdminMemberships()
        .listen(
          (memberships) {
            _memberships = memberships;
            _membershipsReady = true;
            _refreshAccessibleLaboratories();
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: AdminBorrowRequestsStatus.failure,
                errorMessage: 'Akses laboratorium tidak dapat dimuat. Periksa koneksi lalu coba lagi.',
                requestsLoading: false,
              ),
            );
          },
        );

    _laboratorySubscription = _membershipService
        .watchActiveLaboratories()
        .listen(
          (laboratories) {
            _allLaboratories = laboratories;
            _laboratoriesReady = true;
            _refreshAccessibleLaboratories();
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: AdminBorrowRequestsStatus.failure,
                errorMessage:
                    'Data laboratorium aktif tidak dapat dimuat saat ini.',
                requestsLoading: false,
              ),
            );
          },
        );
  }

  void _refreshAccessibleLaboratories() {
    if (!_membershipsReady || !_laboratoriesReady) {
      return;
    }

    final membershipLabIds = _memberships.map((item) => item.labId).toSet();

    final laboratories =
        _allLaboratories
            .where((laboratory) => membershipLabIds.contains(laboratory.id))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (laboratories.isEmpty) {
      _requestLabId = null;
      _requestSubscription?.cancel();
      _requestSubscription = null;

      emit(
        AdminBorrowRequestsState(
          status: AdminBorrowRequestsStatus.loaded,
          laboratories: laboratories,
          statusFilter: state.statusFilter,
          searchQuery: state.searchQuery,
        ),
      );
      return;
    }

    final previousSelectedLabId = state.selectedLabId;
    final selectedLabId =
        laboratories.any((laboratory) => laboratory.id == previousSelectedLabId)
        ? previousSelectedLabId!
        : laboratories.first.id;

    final sameRequestSource = _requestLabId == selectedLabId;

    emit(
      state.copyWith(
        status: AdminBorrowRequestsStatus.loaded,
        laboratories: laboratories,
        selectedLabId: selectedLabId,
        requests: sameRequestSource ? state.requests : const <BorrowRequest>[],
        requestsLoading: !sameRequestSource,
        errorMessage: '',
      ),
    );

    if (!sameRequestSource) {
      _subscribeRequests(selectedLabId);
    }
  }

  /// Mengganti laboratorium aktif yang sedang ditinjau.
  ///
  /// Pencarian dikosongkan agar query dari laboratorium sebelumnya tidak ikut
  /// memengaruhi daftar laboratorium yang baru dipilih.
  void selectLaboratory(String laboratoryId) {
    if (laboratoryId == state.selectedLabId) {
      return;
    }

    final exists = state.laboratories.any(
      (laboratory) => laboratory.id == laboratoryId,
    );

    if (!exists) {
      return;
    }

    emit(
      state.copyWith(
        selectedLabId: laboratoryId,
        requests: const <BorrowRequest>[],
        searchQuery: '',
        requestsLoading: true,
        errorMessage: '',
      ),
    );

    _subscribeRequests(laboratoryId);
  }

  /// Mengubah filter status antrean.
  void setStatusFilter(String value) {
    if (value == state.statusFilter) {
      return;
    }

    emit(state.copyWith(statusFilter: value));
  }

  /// Memperbarui query pencarian pada daftar peminjaman.
  void setSearchQuery(String value) {
    if (value == state.searchQuery) {
      return;
    }

    emit(state.copyWith(searchQuery: value));
  }

  void _subscribeRequests(String laboratoryId) {
    _requestLabId = laboratoryId;
    _requestSubscription?.cancel();

    _requestSubscription = _borrowRequestService
        .watchRequestsByLaboratory(laboratoryId)
        .listen(
          (requests) {
            if (_requestLabId != laboratoryId) {
              return;
            }

            emit(
              state.copyWith(
                status: AdminBorrowRequestsStatus.loaded,
                requests: requests,
                requestsLoading: false,
                errorMessage: '',
              ),
            );
          },
          onError: (_) {
            if (_requestLabId != laboratoryId) {
              return;
            }

            emit(
              state.copyWith(
                status: AdminBorrowRequestsStatus.failure,
                errorMessage: 'Permintaan peminjaman tidak dapat dimuat. Periksa koneksi atau izin akses laboratorium.',
                requestsLoading: false,
              ),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    await _membershipSubscription?.cancel();
    await _laboratorySubscription?.cancel();
    await _requestSubscription?.cancel();
    return super.close();
  }
}
