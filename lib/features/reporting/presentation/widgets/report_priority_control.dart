import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/report_detail_cubit.dart';
import '../cubit/report_detail_state.dart';
import '../../domain/lab_report.dart';

class ReportPriorityControl extends StatelessWidget {
  const ReportPriorityControl({
    required this.state,
    required this.report,
    super.key,
  });
  final ReportDetailState state;
  final LabReport report;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Priority Penanganan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['low', 'medium', 'high', 'critical']
              .map(
                (priority) => ChoiceChip(
                  label: Text(reportPriorityLabel(priority)),
                  selected: report.priority == priority,
                  onSelected: state.isProcessing
                      ? null
                      : (_) => context.read<ReportDetailCubit>().setPriority(
                          priority,
                        ),
                  selectedColor: const Color(0xFFB9F33D),
                  backgroundColor: const Color(0xFFF6F9EF),
                  showCheckmark: false,
                  side: const BorderSide(color: Color(0xFFDDE2D5)),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );
}

String reportPriorityLabel(String priority) => switch (priority) {
  'critical' => 'Critical',
  'high' => 'High',
  'low' => 'Low',
  _ => 'Medium',
};
