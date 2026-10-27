import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reporting/presentation/widgets/report_conversation_panel.dart';
import '../../data/student_report_service.dart';
import '../cubit/student_report_detail_cubit.dart';
import '../cubit/student_report_detail_state.dart';
import '../student_navigation.dart';
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
  Widget build(BuildContext context) {
    return StudentBackFallback(
      fallbackPath: '/student/reports',
      child: Scaffold(
        backgroundColor: studentPaper,
        body: SafeArea(
          child: BlocBuilder<StudentReportDetailCubit, StudentReportDetailState>(
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
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  StudentBackHeader(
                    title: 'Detail Laporan',
                    onBack: () => studentPopOrGo(context, '/student/reports'),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StudentStatusPill(status: report.status),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: studentPriorityBackground(report.priority),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          studentPriorityLabel(report.priority),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: studentPriorityForeground(report.priority),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: studentInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.reportNumber} · Dilaporkan ${studentFormatDateTime(report.createdAt)}',
                    style: const TextStyle(fontSize: 11, color: studentMuted),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _meta('Laboratorium', state.laboratoryName),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _meta(
                          'Kategori',
                          studentCategoryLabel(report.category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Detail kendala',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: studentMuted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Perkembangan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _timeline(
                    report.status,
                    report.createdAt,
                    report.acknowledgedAt,
                    report.resolvedAt,
                  ),
                  const SizedBox(height: 18),
                  ReportConversationPanel(reportId: report.id),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: studentMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: studentInk,
          ),
        ),
      ],
    );
  }

  Widget _timeline(
    String status,
    DateTime createdAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  ) {
    final processing = {
      'acknowledged',
      'in_progress',
      'resolved',
      'closed',
    }.contains(status);
    final done = {'resolved', 'closed'}.contains(status);
    final steps = [
      _ReportTimelineData(
        'Laporan diterima',
        studentFormatDateTime(createdAt),
        true,
      ),
      _ReportTimelineData(
        'Sedang Diproses',
        acknowledgedAt == null
            ? 'Menunggu Lab Admin'
            : studentFormatDateTime(acknowledgedAt),
        processing,
      ),
      _ReportTimelineData(
        'Selesai',
        resolvedAt == null
            ? 'Belum selesai diproses'
            : studentFormatDateTime(resolvedAt),
        done,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final last = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: step.done ? studentInk : Colors.white,
                      border: Border.all(
                        color: step.done ? studentInk : studentBorder,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!last)
                    Container(
                      width: 2,
                      height: 40,
                      color: step.done ? studentInk : studentBorder,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: step.done ? studentInk : studentMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.subtitle,
                      style: const TextStyle(fontSize: 11, color: studentMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ReportTimelineData {
  const _ReportTimelineData(this.title, this.subtitle, this.done);
  final String title;
  final String subtitle;
  final bool done;
}
