import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reporting/presentation/widgets/report_conversation_panel.dart';
import '../../data/student_report_service.dart';
import '../cubit/student_report_detail_cubit.dart';
import '../cubit/student_report_detail_state.dart';
import '../widgets/student_ui.dart';

class StudentReportDetailPage extends StatelessWidget {
  const StudentReportDetailPage({required this.reportId, super.key});
  final String reportId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentReportDetailCubit(StudentReportService())..watch(reportId),
    child: _StudentReportDetailView(reportId: reportId),
  );
}

class _StudentReportDetailView extends StatelessWidget {
  const _StudentReportDetailView({required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: studentPaper,
    appBar: AppBar(
      title: const Text('Detail Laporan'),
      backgroundColor: studentPaper,
    ),
    body: BlocBuilder<StudentReportDetailCubit, StudentReportDetailState>(
      builder: (context, state) {
        if (state.status == StudentReportDetailStatus.initial ||
            state.status == StudentReportDetailStatus.loading) {
          return const StudentLoading(message: 'Memuat laporan.');
        }
        if (state.status == StudentReportDetailStatus.failure ||
            state.report == null) {
          return StudentErrorState(
            message: state.errorMessage,
            onRetry: () =>
                context.read<StudentReportDetailCubit>().watch(reportId),
          );
        }
        final report = state.report!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              report.reportNumber,
              style: const TextStyle(
                color: studentMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _info('Status', studentStatusLabel(report.status)),
            _info('Laboratorium', state.laboratoryName),
            _info('Kategori', studentCategoryLabel(report.category)),
            _info(
              'Urgensi',
              report.severity == 'urgent' ? 'Mendesak' : 'Normal',
            ),
            _info('Lokasi', report.location),
            _info('Deskripsi', report.description),
            if (report.adminResponse?.isNotEmpty == true)
              _info('Tanggapan Admin', report.adminResponse!),
            const SizedBox(height: 18),
            ReportConversationPanel(reportId: report.id),
          ],
        );
      },
    ),
  );

  Widget _info(String title, String value) => Container(
    margin: const EdgeInsets.only(top: 9),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: studentBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: studentMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35),
        ),
      ],
    ),
  );
}
