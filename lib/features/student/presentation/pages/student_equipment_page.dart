import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../cubit/student_catalog_cubit.dart';
import '../cubit/student_catalog_state.dart';
import '../cubit/student_data_state.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentEquipmentPage extends StatelessWidget {
  const StudentEquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentCatalogCubit(StudentService())..load(),
      child: const _StudentEquipmentView(),
    );
  }
}

class _StudentEquipmentView extends StatelessWidget {
  const _StudentEquipmentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      bottomNavigationBar: const StudentBottomNavigation(currentIndex: 1),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<StudentCatalogCubit, StudentCatalogState>(
          builder: (context, state) {
            if (state.status == StudentLoadStatus.initial ||
                state.status == StudentLoadStatus.loading) {
              return const StudentLoading(
                message: 'Memuat katalog aset laboratorium.',
              );
            }

            if (state.status == StudentLoadStatus.failure) {
              return StudentErrorState(
                message: state.errorMessage,
                onRetry: context.read<StudentCatalogCubit>().load,
              );
            }

            return _content(context, state);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, StudentCatalogState state) {
    final cubit = context.read<StudentCatalogCubit>();
    final labMap = {for (final lab in state.laboratories) lab.id: lab.name};

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          const StudentPageTitle(
            title: 'Katalog Aset',
            subtitle:
                'Cari alat berdasarkan nama, kategori, atau laboratorium.',
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: cubit.setQuery,
            decoration: InputDecoration(
              hintText: 'Cari aset...',
              prefixIcon: const Icon(Icons.search_rounded),
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
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final selected = category == state.category;

                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => cubit.setCategory(category),
                  selectedColor: studentLime,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: studentBorder),
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: state.labId,
            decoration: InputDecoration(
              labelText: 'Laboratorium',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: studentBorder),
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: 'Semua',
                child: Text('Semua Laboratorium'),
              ),
              ...state.laboratories.map(
                (lab) => DropdownMenuItem(value: lab.id, child: Text(lab.name)),
              ),
            ],
            onChanged: (value) {
              if (value != null) cubit.setLaboratory(value);
            },
          ),
          const SizedBox(height: 18),
          Text(
            '${state.visibleAssets.length} aset ditemukan',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: studentMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (state.visibleAssets.isEmpty)
            _empty()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.visibleAssets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final asset = state.visibleAssets[index];

                return StudentAssetCard(
                  asset: asset,
                  labName: labMap[asset.labId] ?? 'Laboratorium',
                  onTap: () => context.push('/student/assets/${asset.id}'),
                );
              },
            ),
        ],
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
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: studentMuted),
          SizedBox(height: 12),
          Text(
            'Tidak ada aset yang cocok dengan filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
