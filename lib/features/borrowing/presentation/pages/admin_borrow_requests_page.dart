import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../lab_admin/presentation/widgets/lab_admin_bottom_navigation.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/borrow_request_service.dart';
import '../../domain/borrow_request.dart';
import '../cubit/admin_borrow_requests_cubit.dart';
import '../cubit/admin_borrow_requests_state.dart';

class AdminBorrowRequestsPage extends StatelessWidget {
  const AdminBorrowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBorrowRequestsCubit(
        LabMembershipService(),
        BorrowRequestService(),
      )..start(),
      child: const _AdminBorrowRequestsView(),
    );
  }
}

class _AdminBorrowRequestsView extends StatefulWidget {
  const _AdminBorrowRequestsView();

  @override
  State<_AdminBorrowRequestsView> createState() =>
      _AdminBorrowRequestsViewState();
}

class _AdminBorrowRequestsViewState extends State<_AdminBorrowRequestsView> {
  // Controller tetap berada pada UI karena lifecycle input field merupakan
  // tanggung jawab widget, sedangkan nilai query diteruskan ke Cubit.
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBorrowRequestsCubit, AdminBorrowRequestsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Peminjaman',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
          ),
          body: _buildBody(context, state),
          bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 2),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminBorrowRequestsState state) {
    if (state.status == AdminBorrowRequestsStatus.initial ||
        state.status == AdminBorrowRequestsStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat akses laboratorium',
        message: 'Menyiapkan antrean peminjaman yang Anda kelola.',
      );
    }

    if (state.status == AdminBorrowRequestsStatus.failure) {
      return LabFlowConnectionErrorState(
        title: 'Peminjaman tidak dapat dimuat',
        message: state.errorMessage.isEmpty
            ? 'Periksa koneksi Anda lalu coba lagi.'
            : state.errorMessage,
      );
    }

    final selectedLab = state.selectedLaboratory;
    if (selectedLab == null) {
      return _emptyState(
        icon: Icons.science_outlined,
        title: 'Belum ada assignment laboratorium',
        message:
            'Hubungi Superadmin untuk mendapatkan akses laboratorium aktif.',
      );
    }

    return _buildRequests(context, state, selectedLab);
  }

  Widget _buildRequests(
    BuildContext context,
    AdminBorrowRequestsState state,
    Laboratory selectedLab,
  ) {
    final requests = state.filteredRequests;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _laboratorySelector(context, state.laboratories, selectedLab),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: context.read<AdminBorrowRequestsCubit>().setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Cari nomor, mahasiswa, atau tujuan...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        context.read<AdminBorrowRequestsCubit>().setSearchQuery(
                          '',
                        );
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(
                  color: Color(0xFF111111),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: [
              _filterChip(context, state, 'Menunggu', 'pending'),
              const SizedBox(width: 8),
              _filterChip(context, state, 'Disetujui', 'approved'),
              const SizedBox(width: 8),
              _filterChip(context, state, 'Ditolak', 'rejected'),
              const SizedBox(width: 8),
              _filterChip(context, state, 'Semua', 'all'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.requestsLoading
              ? const LabFlowLoadingState(
                  title: 'Memuat permintaan',
                  message: 'Mengambil antrean peminjaman terbaru.',
                )
              : requests.isEmpty
              ? _emptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: state.statusFilter == 'pending'
                      ? 'Tidak ada permintaan menunggu'
                      : 'Permintaan tidak ditemukan',
                  message: state.statusFilter == 'pending'
                      ? 'Permintaan baru dari mahasiswa akan muncul di sini.'
                      : 'Coba ubah filter atau kata pencarian.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _requestCard(context, requests[index]),
                ),
        ),
      ],
    );
  }

  Widget _laboratorySelector(
    BuildContext context,
    List<Laboratory> laboratories,
    Laboratory selected,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFB9F33D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_outlined, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laboratorium aktif',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 4),
                Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${selected.code} · ${selected.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
              ],
            ),
          ),
          if (laboratories.length > 1)
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected.id,
                dropdownColor: Colors.white,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                ),
                items: laboratories
                    .map(
                      (laboratory) => DropdownMenuItem<String>(
                        value: laboratory.id,
                        child: Text(laboratory.code),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  _searchController.clear();
                  context.read<AdminBorrowRequestsCubit>().selectLaboratory(
                    value,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    AdminBorrowRequestsState state,
    String label,
    String value,
  ) {
    final selected = state.statusFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF111111) : const Color(0xFFDDE2D5),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? const Color(0xFFB9F33D) : const Color(0xFF111111),
      ),
      shape: const StadiumBorder(),
      onSelected: (_) {
        context.read<AdminBorrowRequestsCubit>().setStatusFilter(value);
      },
    );
  }

  Widget _requestCard(BuildContext context, BorrowRequest request) {
    final palette = _statusPalette(request.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.push('/lab-admin/borrowing/${request.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE2D5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.requestNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(request.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: Color(0xFF7A8190),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.studentId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.purpose.isEmpty
                    ? 'Tujuan tidak dicantumkan.'
                    : request.purpose,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF5F6672),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _compactDate('Pinjam', request.borrowDate)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _compactDate('Kembali', request.expectedReturnDate),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7A8190),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactDate(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7A8190)),
        ),
        const SizedBox(height: 3),
        Text(
          _formatDate(date),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBCB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF111111), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

_StatusPalette _statusPalette(String status) {
  switch (status) {
    case 'pending':
      return const _StatusPalette(Color(0xFFFFE7B3), Color(0xFF8A5700));
    case 'approved':
      return const _StatusPalette(Color(0xFFDFF5E8), Color(0xFF188A55));
    case 'rejected':
      return const _StatusPalette(Color(0xFFFBE1E1), Color(0xFFBD3232));
    case 'cancelled':
      return const _StatusPalette(Color(0xFFE9ECE7), Color(0xFF5F6672));
    default:
      return const _StatusPalette(Color(0xFFE9ECE7), Color(0xFF5F6672));
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu Persetujuan';
    case 'approved':
      return 'Disetujui';
    case 'rejected':
      return 'Ditolak';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  if (date.millisecondsSinceEpoch == 0) {
    return '-';
  }

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
