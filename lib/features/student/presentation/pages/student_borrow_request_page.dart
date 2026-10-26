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

  Widget _form(BuildContext context, StudentBorrowFormState state) {
    final cubit = context.read<StudentBorrowFormCubit>();
    final asset = state.asset!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        StudentBackHeader(
          title: 'Ajukan Peminjaman',
          onBack: () => context.pop(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: studentLime,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.router_outlined, color: studentInk),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 3),
                    Text(
                      '${asset.code} · ${state.laboratory?.name ?? 'Laboratorium'}',
                      style: const TextStyle(fontSize: 10, color: studentInk),
                    ),
                    const SizedBox(height: 7),
                    const StudentStatusPill(status: 'available', small: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _cardField(
          label: 'Jumlah',
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
        const SizedBox(height: 10),
        _dateField(
          context,
          label: 'Tanggal Pinjam',
          value: state.borrowDate!,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onSelected: cubit.setBorrowDate,
        ),
        const SizedBox(height: 10),
        _dateField(
          context,
          label: 'Tanggal Kembali',
          value: state.expectedReturnDate!,
          firstDate: state.borrowDate!,
          lastDate: state.borrowDate!.add(const Duration(days: 90)),
          onSelected: cubit.setExpectedReturnDate,
        ),
        const SizedBox(height: 10),
        TextField(
          minLines: 3,
          maxLines: 4,
          maxLength: 300,
          onChanged: cubit.setPurpose,
          decoration: _decoration(
            'Tujuan Peminjaman',
            'Contoh: Praktikum Jaringan',
          ),
        ),
        TextField(
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          onChanged: cubit.setStudentNote,
          decoration: _decoration(
            'Catatan (opsional)',
            'Informasi tambahan untuk Lab Admin.',
          ),
        ),
        if (state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            state.errorMessage,
            style: const TextStyle(
              color: studentPinkText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Permintaan akan ditinjau Lab Admin. Ambil aset hanya setelah disetujui.',
          style: TextStyle(fontSize: 10, height: 1.4, color: studentMuted),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: state.canReview ? cubit.review : null,
            style: FilledButton.styleFrom(
              backgroundColor: studentInk,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Tinjau Pengajuan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _review(BuildContext context, StudentBorrowFormState state) {
    final cubit = context.read<StudentBorrowFormCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        StudentBackHeader(title: 'Tinjau Pengajuan', onBack: cubit.edit),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: studentInk,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.asset!.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${state.asset!.code} · ${state.laboratory?.name ?? 'Laboratorium'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _reviewRow('Jumlah', '${state.quantity} unit'),
        _reviewRow('Tanggal Pinjam', studentFormatDate(state.borrowDate!)),
        _reviewRow(
          'Tanggal Kembali',
          studentFormatDate(state.expectedReturnDate!),
        ),
        _reviewRow('Tujuan', state.purpose.trim()),
        if (state.studentNote.trim().isNotEmpty)
          _reviewRow('Catatan', state.studentNote.trim()),
        if (state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            state.errorMessage,
            style: const TextStyle(color: studentPinkText),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: state.isSubmitting ? null : cubit.edit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: studentInk,
                  side: const BorderSide(color: studentBorder),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: state.isSubmitting ? null : cubit.submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: studentInk,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  state.isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _success(BuildContext context, StudentBorrowFormState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: studentLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 44),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pengajuan Terkirim',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              state.result?.requestNumber ?? 'Permintaan peminjaman',
              style: const TextStyle(color: studentMuted),
            ),
            const SizedBox(height: 22),
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

  Widget _cardField({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: studentMuted),
          ),
          child,
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
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (selected != null) onSelected(selected);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: studentBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: studentMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentFormatDate(value),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_outlined, size: 18),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: studentBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: studentBorder),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
