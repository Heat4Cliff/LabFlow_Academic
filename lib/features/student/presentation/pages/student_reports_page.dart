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

class _StudentReportsView extends StatefulWidget {
  const _StudentReportsView();

  @override
  State<_StudentReportsView> createState() => _StudentReportsViewState();
}

class _StudentReportsViewState extends State<_StudentReportsView> {
  String _tab = 'Semua';

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
        label: const Text(
          'Buat Laporan',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
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
    final filtered = _filter(reports);
    return RefreshIndicator(
      onRefresh: context.read<StudentReportsCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Laporan',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Lab yang baik,\nkita jaga bersama.',
            style: TextStyle(
              fontSize: 25,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantau laporan dan kabar penanganannya.',
            style: TextStyle(fontSize: 11, color: studentMuted),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _tabChip('Semua'),
              const SizedBox(width: 7),
              _tabChip('Diproses'),
              const SizedBox(width: 7),
              _tabChip('Selesai'),
            ],
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _empty(context)
          else
            ...filtered.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _reportCard(context, report),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabChip(String label) {
    final selected = _tab == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _tab = label),
      selectedColor: selected && label == 'Semua' ? studentInk : Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? studentInk : studentBorder),
      labelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: selected && label == 'Semua' ? studentLime : studentInk,
      ),
      shape: const StadiumBorder(),
    );
  }

  List<LabReport> _filter(List<LabReport> reports) {
    switch (_tab) {
      case 'Diproses':
        return reports
            .where(
              (r) => r.status == 'acknowledged' || r.status == 'in_progress',
            )
            .toList(growable: false);
      case 'Selesai':
        return reports
            .where((r) => r.status == 'resolved' || r.status == 'closed')
            .toList(growable: false);
      default:
        return reports;
    }
  }

  Widget _reportCard(BuildContext context, LabReport report) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push('/student/reports/${report.id}'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                report.location,
                style: const TextStyle(fontSize: 9, color: studentMuted),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (report.priority == 'high' ||
                      report.priority == 'critical')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: studentPinkSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        studentPriorityLabel(report.priority),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: studentPinkText,
                        ),
                      ),
                    ),
                  StudentStatusPill(status: report.status, small: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Diperbarui ${studentFormatDate(report.updatedAt)}',
                style: const TextStyle(fontSize: 9, color: studentMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, size: 38, color: studentMuted),
          const SizedBox(height: 10),
          const Text(
            'Belum ada laporan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Menemukan alat bermasalah? Sampaikan agar laboratorium tetap siap digunakan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.4, color: studentMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/student/reports/create'),
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Buat Laporan'),
            ),
          ),
        ],
      ),
    );
  }
}
