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
    'network': 'Masalah Jaringan',
    'computer': 'Komputer',
    'software': 'Software',
    'facility': 'Fasilitas',
    'electricity': 'Kelistrikan',
    'other': 'Lainnya',
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentReportCreateCubit, StudentReportCreateState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == StudentReportCreateStatus.success &&
            state.reportId != null) {
          context.go('/student/reports/${state.reportId}');
        }
      },
      child: Scaffold(
        backgroundColor: studentPaper,
        body: SafeArea(
          child:
              BlocBuilder<StudentReportCreateCubit, StudentReportCreateState>(
                builder: (context, state) {
                  if (state.status == StudentReportCreateStatus.loading &&
                      state.laboratories.isEmpty) {
                    return const StudentLoading(
                      message: 'Memuat laboratorium.',
                    );
                  }
                  if (state.status == StudentReportCreateStatus.failure &&
                      state.laboratories.isEmpty) {
                    return StudentErrorState(
                      message: state.errorMessage,
                      onRetry: context.read<StudentReportCreateCubit>().load,
                    );
                  }
                  return _form(context, state);
                },
              ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, StudentReportCreateState state) {
    final cubit = context.read<StudentReportCreateCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        StudentBackHeader(title: 'Buat Laporan', onBack: () => context.pop()),
        const SizedBox(height: 16),
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        TextField(
          maxLength: 120,
          onChanged: cubit.setTitle,
          decoration: _decoration('Judul')
              .copyWith(hintText: 'Jaringan Tidak Tersambung', counterText: ''),
        ),
        const SizedBox(height: 10),
        TextField(
          minLines: 4,
          maxLines: 7,
          maxLength: 2000,
          onChanged: cubit.setDescription,
          decoration: _decoration('Deskripsi').copyWith(
            hintText: 'Jelaskan masalah dan kapan terjadi',
            counterText: '',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          maxLength: 160,
          onChanged: cubit.setLocation,
          decoration: _decoration('Lokasi')
              .copyWith(hintText: 'Contoh: Lab IoT, meja 3', counterText: ''),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: studentBorder, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lampiran (opsional)\nTambah foto · JPG, PNG · maks. 5 MB',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: studentMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            state.errorMessage,
            style: const TextStyle(
              color: studentPinkText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: state.status == StudentReportCreateStatus.saving
                ? null
                : cubit.submit,
            style: FilledButton.styleFrom(
              backgroundColor: studentInk,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            icon: state.status == StudentReportCreateStatus.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: const Text(
              'Kirim Laporan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
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
}
