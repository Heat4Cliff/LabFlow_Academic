import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_report_service.dart';
import '../cubit/student_report_create_cubit.dart';
import '../cubit/student_report_create_state.dart';
import '../widgets/student_ui.dart';

class StudentReportCreatePage extends StatelessWidget {
  const StudentReportCreatePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentReportCreateCubit(StudentReportService())..load(),
    child: const _StudentReportCreateView(),
  );
}

class _StudentReportCreateView extends StatelessWidget {
  const _StudentReportCreateView();

  static const categories = <String, String>{
    'asset_damage': 'Kerusakan aset',
    'asset_lost': 'Aset hilang',
    'network': 'Jaringan',
    'computer': 'Komputer',
    'software': 'Software',
    'facility': 'Fasilitas',
    'electricity': 'Kelistrikan',
    'other': 'Lainnya',
  };

  @override
  Widget build(
    BuildContext context,
  ) => BlocListener<StudentReportCreateCubit, StudentReportCreateState>(
    listenWhen: (previous, current) => previous.status != current.status,
    listener: (context, state) {
      if (state.status == StudentReportCreateStatus.success &&
          state.reportId != null) {
        context.go('/student/reports/${state.reportId}');
      }
    },
    child: Scaffold(
      backgroundColor: studentPaper,
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        backgroundColor: studentPaper,
      ),
      body: BlocBuilder<StudentReportCreateCubit, StudentReportCreateState>(
        builder: (context, state) {
          if (state.status == StudentReportCreateStatus.loading &&
              state.laboratories.isEmpty) {
            return const StudentLoading(message: 'Memuat laboratorium.');
          }
          if (state.status == StudentReportCreateStatus.failure &&
              state.laboratories.isEmpty) {
            return StudentErrorState(
              message: state.errorMessage,
              onRetry: context.read<StudentReportCreateCubit>().load,
            );
          }
          final cubit = context.read<StudentReportCreateCubit>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const Text(
                'Ceritakan masalah yang Anda temukan agar Lab Admin dapat menindaklanjutinya.',
                style: TextStyle(color: studentMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: state.labId.isEmpty ? null : state.labId,
                decoration: _decoration('Laboratorium'),
                items: state.laboratories
                    .map(
                      (lab) => DropdownMenuItem(
                        value: lab.id,
                        child: Text(lab.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: state.status == StudentReportCreateStatus.saving
                    ? null
                    : (value) {
                        if (value != null) cubit.selectLaboratory(value);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: state.assetId,
                decoration: _decoration('Aset (opsional)'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tidak terkait aset'),
                  ),
                  ...state.assets.map(
                    (asset) => DropdownMenuItem(
                      value: asset.id,
                      child: Text(
                        '${asset.name} · ${asset.code}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: cubit.setAsset,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: state.category,
                decoration: _decoration('Kategori'),
                items: categories.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) cubit.setCategory(value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                maxLength: 120,
                onChanged: cubit.setTitle,
                decoration: _decoration('Judul')
                    .copyWith(hintText: 'Contoh: Proyektor tidak menyala'),
              ),
              const SizedBox(height: 8),
              TextField(
                minLines: 4,
                maxLines: 7,
                maxLength: 2000,
                onChanged: cubit.setDescription,
                decoration: _decoration('Deskripsi')
                    .copyWith(hintText: 'Jelaskan masalah dan kapan terjadi'),
              ),
              TextField(
                maxLength: 160,
                onChanged: cubit.setLocation,
                decoration: _decoration('Lokasi')
                    .copyWith(hintText: 'Contoh: Lab IoT, meja 3'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: state.severity,
                decoration: _decoration('Urgensi'),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'urgent', child: Text('Mendesak')),
                ],
                onChanged: (value) {
                  if (value != null) cubit.setSeverity(value);
                },
              ),
              if (state.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFB42318),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: state.status == StudentReportCreateStatus.saving
                      ? null
                      : cubit.submit,
                  icon: state.status == StudentReportCreateStatus.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Kirim Laporan'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
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
