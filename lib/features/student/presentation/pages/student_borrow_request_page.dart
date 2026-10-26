import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../cubit/student_borrow_form_cubit.dart';
import '../cubit/student_borrow_form_state.dart';
import '../cubit/student_data_state.dart';
import '../widgets/student_ui.dart';

class StudentBorrowRequestPage extends StatelessWidget {
  const StudentBorrowRequestPage({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          StudentBorrowFormCubit(StudentService(), assetId: assetId)..load(),
      child: const _StudentBorrowRequestView(),
    );
  }
}

class _StudentBorrowRequestView extends StatelessWidget {
  const _StudentBorrowRequestView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      body: SafeArea(
        child: BlocBuilder<StudentBorrowFormCubit, StudentBorrowFormState>(
          builder: (context, state) {
            if (state.status == StudentLoadStatus.initial ||
                state.status == StudentLoadStatus.loading) {
              return const StudentLoading(
                message: 'Menyiapkan form peminjaman.',
              );
            }

            if (state.status == StudentLoadStatus.failure ||
                state.asset == null) {
              return StudentErrorState(
                message: state.errorMessage,
                onRetry: context.read<StudentBorrowFormCubit>().load,
              );
            }

            switch (state.step) {
              case StudentBorrowFormStep.form:
                return _form(context, state);
              case StudentBorrowFormStep.review:
                return _review(context, state);
              case StudentBorrowFormStep.success:
                return _success(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context, {
    required String title,
    String? subtitle,
    VoidCallback? onBack,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          onPressed: onBack ?? () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: studentMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, StudentBorrowFormState state) {
    final cubit = context.read<StudentBorrowFormCubit>();
    final asset = state.asset!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _header(
          context,
          title: 'Ajukan Peminjaman',
          subtitle: 'Lengkapi kebutuhan peminjaman aset.',
        ),
        const SizedBox(height: 18),
        _assetSummary(state),
        const SizedBox(height: 18),
        _fieldLabel('Jumlah'),
        const SizedBox(height: 8),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: studentBorder),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: state.quantity > 1
                    ? () => cubit.setQuantity(state.quantity - 1)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '${state.quantity} unit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: state.quantity < asset.stock
                    ? () => cubit.setQuantity(state.quantity + 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _dateField(
          context,
          label: 'Tanggal Pinjam',
          value: state.borrowDate!,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onSelected: cubit.setBorrowDate,
        ),
        const SizedBox(height: 12),
        _dateField(
          context,
          label: 'Rencana Kembali',
          value: state.expectedReturnDate!,
          firstDate: state.borrowDate!,
          lastDate: state.borrowDate!.add(const Duration(days: 90)),
          onSelected: cubit.setExpectedReturnDate,
        ),
        const SizedBox(height: 16),
        TextField(
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          onChanged: cubit.setPurpose,
          decoration: _inputDecoration(
            'Tujuan Peminjaman',
            'Contoh: praktikum IoT semester 7',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          onChanged: cubit.setStudentNote,
          decoration: _inputDecoration(
            'Catatan (opsional)',
            'Informasi tambahan untuk Lab Admin.',
          ),
        ),
        if (state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          _error(state.errorMessage),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: state.canReview ? cubit.review : null,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text(
              'Tinjau Pengajuan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: studentInk,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB8BCB3),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _review(BuildContext context, StudentBorrowFormState state) {
    final cubit = context.read<StudentBorrowFormCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _header(
          context,
          title: 'Review Pengajuan',
          subtitle: 'Pastikan data sudah benar sebelum dikirim.',
          onBack: cubit.edit,
        ),
        const SizedBox(height: 18),
        _assetSummary(state),
        const SizedBox(height: 14),
        _reviewCard([
          _reviewRow('Jumlah', '${state.quantity} unit'),
          _reviewRow('Tanggal Pinjam', studentFormatDate(state.borrowDate!)),
          _reviewRow(
            'Rencana Kembali',
            studentFormatDate(state.expectedReturnDate!),
          ),
          _reviewRow('Tujuan', state.purpose.trim()),
          if (state.studentNote.trim().isNotEmpty)
            _reviewRow('Catatan', state.studentNote.trim()),
        ]),
        if (state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          _error(state.errorMessage),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isSubmitting ? null : cubit.edit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: studentInk,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: state.isSubmitting ? null : cubit.submit,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: studentInk,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  state.isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: studentLime,
                  foregroundColor: studentInk,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _success(BuildContext context, StudentBorrowFormState state) {
    final result = state.result;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: studentLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 42,
                color: studentInk,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pengajuan Terkirim',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              result?.requestNumber ?? 'Permintaan peminjaman',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: studentMuted,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lab Admin akan meninjau pengajuan Anda. Stok aset belum dikurangi pada tahap ini.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.45, color: studentMuted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => context.go('/student/borrowing'),
                style: FilledButton.styleFrom(
                  backgroundColor: studentInk,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Lihat Status Peminjaman',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetSummary(StudentBorrowFormState state) {
    final asset = state.asset!;
    final laboratory = state.laboratory;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: studentSoftLime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.memory_rounded, color: studentInk),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${asset.code} · Stok ${asset.stock}',
                  style: const TextStyle(fontSize: 11, color: studentMuted),
                ),
                const SizedBox(height: 3),
                Text(
                  laboratory?.name ?? 'Laboratorium',
                  style: const TextStyle(fontSize: 11, color: studentMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (selected != null) {
          onSelected(selected);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: studentBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: studentMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: studentMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentFormatDate(value),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: studentBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: studentBorder),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    );
  }

  Widget _error(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _reviewCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: studentMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
