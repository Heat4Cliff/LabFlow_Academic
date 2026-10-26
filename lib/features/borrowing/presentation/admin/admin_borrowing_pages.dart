import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../lab_admin/presentation/widgets/lab_admin_bottom_navigation.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/borrow_request_service.dart';
import '../../domain/borrow_request.dart';

class AdminBorrowRequestsPage extends StatefulWidget {
  const AdminBorrowRequestsPage({super.key});

  @override
  State<AdminBorrowRequestsPage> createState() =>
      _AdminBorrowRequestsPageState();
}

class _AdminBorrowRequestsPageState extends State<AdminBorrowRequestsPage> {
  final LabMembershipService _membershipService = LabMembershipService();
  final BorrowRequestService _borrowRequestService = BorrowRequestService();
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'pending';
  String? _selectedLabId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<LabMembership>>(
        stream: _membershipService.watchCurrentLabAdminMemberships(),
        builder: (context, membershipSnapshot) {
          if (membershipSnapshot.connectionState == ConnectionState.waiting &&
              !membershipSnapshot.hasData) {
            return const LabFlowLoadingState(
              title: 'Memuat akses laboratorium',
              message:
                  'Memeriksa laboratorium yang menjadi tanggung jawab Anda.',
            );
          }

          if (membershipSnapshot.hasError) {
            return const LabFlowConnectionErrorState(
              title: 'Akses laboratorium tidak dapat dimuat',
              message: 'Periksa koneksi Anda lalu coba lagi.',
            );
          }

          final memberships =
              membershipSnapshot.data ?? const <LabMembership>[];
          if (memberships.isEmpty) {
            return _emptyState(
              icon: Icons.science_outlined,
              title: 'Belum ada assignment laboratorium',
              message:
                  'Hubungi Superadmin untuk mendapatkan akses laboratorium.',
            );
          }

          return StreamBuilder<List<Laboratory>>(
            stream: _membershipService.watchActiveLaboratories(),
            builder: (context, laboratorySnapshot) {
              if (laboratorySnapshot.connectionState ==
                      ConnectionState.waiting &&
                  !laboratorySnapshot.hasData) {
                return const LabFlowLoadingState(
                  title: 'Memuat laboratorium',
                  message: 'Menyiapkan laboratorium yang Anda kelola.',
                );
              }

              if (laboratorySnapshot.hasError) {
                return const LabFlowConnectionErrorState(
                  title: 'Laboratorium tidak dapat dimuat',
                  message: 'Data laboratorium tidak dapat diambil saat ini.',
                );
              }

              final membershipLabIds = memberships.map((e) => e.labId).toSet();
              final laboratories =
                  (laboratorySnapshot.data ?? const <Laboratory>[])
                      .where((lab) => membershipLabIds.contains(lab.id))
                      .toList()
                    ..sort(
                      (a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                    );

              if (laboratories.isEmpty) {
                return _emptyState(
                  icon: Icons.science_outlined,
                  title: 'Laboratorium aktif tidak ditemukan',
                  message:
                      'Assignment Anda belum terhubung ke laboratorium aktif.',
                );
              }

              final selectedLab = _resolveSelectedLaboratory(laboratories);
              return _buildRequests(laboratories, selectedLab);
            },
          );
        },
      ),
      bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 2),
    );
  }

  Laboratory _resolveSelectedLaboratory(List<Laboratory> laboratories) {
    final selected = _selectedLabId;
    if (selected != null) {
      for (final laboratory in laboratories) {
        if (laboratory.id == selected) {
          return laboratory;
        }
      }
    }
    return laboratories.first;
  }

  Widget _buildRequests(List<Laboratory> laboratories, Laboratory selectedLab) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _laboratorySelector(laboratories, selectedLab),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari nomor, mahasiswa, atau tujuan...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
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
              _filterChip('Menunggu', 'pending'),
              const SizedBox(width: 8),
              _filterChip('Disetujui', 'approved'),
              const SizedBox(width: 8),
              _filterChip('Ditolak', 'rejected'),
              const SizedBox(width: 8),
              _filterChip('Semua', 'all'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<BorrowRequest>>(
            stream: _borrowRequestService.watchRequestsByLaboratory(
              selectedLab.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LabFlowLoadingState(
                  title: 'Memuat permintaan',
                  message: 'Mengambil antrean peminjaman terbaru.',
                );
              }

              if (snapshot.hasError) {
                return const LabFlowConnectionErrorState(
                  title: 'Permintaan tidak dapat dimuat',
                  message: 'Periksa koneksi atau izin akses laboratorium Anda.',
                );
              }

              final requests = _filterRequests(
                snapshot.data ?? const <BorrowRequest>[],
              );
              if (requests.isEmpty) {
                return _emptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: _statusFilter == 'pending'
                      ? 'Tidak ada permintaan menunggu'
                      : 'Permintaan tidak ditemukan',
                  message: _statusFilter == 'pending'
                      ? 'Permintaan baru dari mahasiswa akan muncul di sini.'
                      : 'Coba ubah filter atau kata pencarian.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _requestCard(requests[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _laboratorySelector(
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
                      (lab) => DropdownMenuItem<String>(
                        value: lab.id,
                        child: Text(lab.code),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedLabId = value;
                    _searchController.clear();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
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
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  List<BorrowRequest> _filterRequests(List<BorrowRequest> requests) {
    final query = _searchController.text.trim().toLowerCase();
    return requests.where((request) {
      final statusMatches =
          _statusFilter == 'all' || request.status == _statusFilter;
      final searchMatches =
          query.isEmpty ||
          request.requestNumber.toLowerCase().contains(query) ||
          request.studentId.toLowerCase().contains(query) ||
          request.purpose.toLowerCase().contains(query);
      return statusMatches && searchMatches;
    }).toList();
  }

  Widget _requestCard(BorrowRequest request) {
    final palette = _statusPalette(request.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/lab-admin/borrowing/${request.id}'),
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
        const SizedBox(height: 2),
        Text(
          _formatDate(date),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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

class AdminBorrowRequestDetailPage extends StatefulWidget {
  const AdminBorrowRequestDetailPage({required this.requestId, super.key});

  final String requestId;

  @override
  State<AdminBorrowRequestDetailPage> createState() =>
      _AdminBorrowRequestDetailPageState();
}

class _AdminBorrowRequestDetailPageState
    extends State<AdminBorrowRequestDetailPage> {
  final BorrowRequestService _service = BorrowRequestService();
  late Future<BorrowRequest> _requestFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestFuture = _service.getRequest(widget.requestId);
  }

  void _reload() {
    setState(() {
      _requestFuture = _service.getRequest(widget.requestId);
    });
  }

  Future<void> _approve() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _service.approveRequest(widget.requestId);
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'Permintaan disetujui',
        message: 'Permintaan siap dilanjutkan ke penugasan aset.',
        type: LabFlowNotificationType.success,
      );
      _reload();
    } on BorrowRequestException catch (error) {
      if (!mounted) return;
      _notify(error.message, LabFlowNotificationType.warning);
    } catch (_) {
      if (!mounted) return;
      _notify(
        'Permintaan tidak dapat disetujui saat ini.',
        LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    if (_isProcessing) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F9EF),
          title: const Text(
            'Tolak permintaan?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Alasan penolakan',
              hintText: 'Contoh: jadwal penggunaan bentrok...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBD3232),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (reason == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      await _service.rejectRequest(requestId: widget.requestId, reason: reason);
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'Permintaan ditolak',
        message: 'Alasan penolakan telah disimpan.',
        type: LabFlowNotificationType.success,
      );
      _reload();
    } on BorrowRequestException catch (error) {
      if (!mounted) return;
      _notify(error.message, LabFlowNotificationType.warning);
    } catch (_) {
      if (!mounted) return;
      _notify(
        'Permintaan tidak dapat ditolak saat ini.',
        LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _notify(String message, LabFlowNotificationType type) {
    showLabFlowNotification(
      context: context,
      title: type == LabFlowNotificationType.error
          ? 'Proses gagal'
          : 'Permintaan tidak dapat diproses',
      message: message,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tinjau Permintaan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<BorrowRequest>(
        future: _requestFuture,
        builder: (context, requestSnapshot) {
          if (requestSnapshot.connectionState == ConnectionState.waiting) {
            return const LabFlowLoadingState(
              title: 'Memuat permintaan',
              message: 'Menyiapkan detail pengajuan peminjaman.',
            );
          }

          if (requestSnapshot.hasError || requestSnapshot.data == null) {
            return const LabFlowConnectionErrorState(
              title: 'Permintaan tidak dapat dimuat',
              message: 'Data permintaan tidak tersedia atau akses Anda telah berubah.',
            );
          }

          final request = requestSnapshot.data!;
          return StreamBuilder<List<BorrowRequestItem>>(
            stream: _service.watchRequestItems(request.id),
            builder: (context, itemSnapshot) {
              final items = itemSnapshot.data ?? const <BorrowRequestItem>[];
              return _detailContent(request, items);
            },
          );
        },
      ),
    );
  }

  Widget _detailContent(BorrowRequest request, List<BorrowRequestItem> items) {
    final palette = _statusPalette(request.status);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: palette.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _identityCard(request),
            const SizedBox(height: 16),
            _itemsCard(items),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dateCard(
                    'Tanggal Pinjam',
                    request.borrowDate,
                    Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateCard(
                    'Tanggal Kembali',
                    request.expectedReturnDate,
                    Icons.event_available_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _textCard(
              'Tujuan Peminjaman',
              request.purpose.isEmpty ? 'Tidak dicantumkan.' : request.purpose,
              Icons.notes_rounded,
            ),
            if ((request.studentNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _textCard(
                'Catatan Mahasiswa',
                request.studentNote!.trim(),
                Icons.chat_bubble_outline_rounded,
              ),
            ],
            if (request.isRejected &&
                (request.rejectionReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _textCard(
                'Alasan Penolakan',
                request.rejectionReason!.trim(),
                Icons.block_outlined,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBCB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan tanggal, tujuan, dan item sudah sesuai sebelum memproses permintaan.',
                      style: TextStyle(
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (request.isPending)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _reject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFBD3232),
                          side: const BorderSide(color: Color(0xFFE3A7A7)),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : _approve,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Setujui'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111111),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE2D5)),
                ),
                child: Text(
                  request.isApproved
                      ? 'Permintaan telah disetujui. Tahap berikutnya adalah penugasan aset.'
                      : request.isRejected
                      ? 'Permintaan telah ditolak.'
                      : 'Permintaan ini tidak lagi menunggu persetujuan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _identityCard(BorrowRequest request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEAFBCB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peminjam',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
                ),
                const SizedBox(height: 4),
                Text(
                  request.studentId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  request.requestNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8190),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(List<BorrowRequestItem> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aset yang Diminta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Detail item belum tersedia.',
              style: TextStyle(color: Color(0xFF7A8190)),
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                const Divider(height: 22, color: Color(0xFFE2E6DC)),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBCB),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[index].itemName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jumlah ${items[index].quantity}${items[index].requestedAssetId == null ? '' : ' · Aset ${items[index].requestedAssetId}'}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget _dateCard(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5F6672)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
          ),
          const SizedBox(height: 3),
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _textCard(String title, String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5F6672)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8190),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  if (date.millisecondsSinceEpoch == 0) return '-';
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
