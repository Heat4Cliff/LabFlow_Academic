import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_report_service.dart';
import '../../../reporting/domain/lab_report.dart';
import '../cubit/student_data_state.dart';
import '../cubit/student_reports_cubit.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentReportsPage extends StatelessWidget {
  const StudentReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentReportsCubit(StudentReportService())..load(),
      child: const _StudentReportsView(),
    );
  }
}

class _StudentReportsView extends StatelessWidget {
  const _StudentReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      bottomNavigationBar: const StudentBottomNavigation(currentIndex: 3),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/reports/create'),
        backgroundColor: studentLime,
        foregroundColor: studentInk,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Laporan'),
      ),
      body: SafeArea(
        bottom: false,
        child:
            BlocBuilder<StudentReportsCubit, StudentDataState<List<LabReport>>>(
              builder: (context, state) {
                if (state.status == StudentLoadStatus.initial ||
                    state.status == StudentLoadStatus.loading) {
                  return const StudentLoading(message: 'Memuat laporan Anda.');
                }

                if (state.status == StudentLoadStatus.failure) {
                  return StudentErrorState(
                    message: state.errorMessage,
                    onRetry: context.read<StudentReportsCubit>().load,
                  );
                }

                return _content(context, state.data ?? const <LabReport>[]);
              },
            ),
      ),
    );
  }

  Widget _content(BuildContext context, List<LabReport> reports) {
    return RefreshIndicator(
      onRefresh: context.read<StudentReportsCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          const StudentPageTitle(
            title: 'Laporan',
            subtitle: 'Pantau status laporan masalah laboratorium yang pernah Anda kirim.',
          ),
          const SizedBox(height: 18),
          if (reports.isEmpty)
            _empty()
          else
            ...reports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(context, report),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, LabReport report) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/student/reports/${report.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: studentBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    report.reportNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: studentMuted,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: studentSoftLime,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    studentStatusLabel(report.status),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${studentCategoryLabel(report.category)} · ${report.location}',
              style: const TextStyle(fontSize: 11, color: studentMuted),
            ),
            const SizedBox(height: 5),
            Text(
              studentFormatDate(report.createdAt),
              style: const TextStyle(fontSize: 10, color: studentMuted),
            ),
            if ((report.adminResponse ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: studentSoftLime,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Tanggapan: ${report.adminResponse}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Belum ada laporan yang Anda kirim.',
        textAlign: TextAlign.center,
        style: TextStyle(color: studentMuted, fontWeight: FontWeight.w700),
      ),
    );
  }
}
