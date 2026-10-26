import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
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

class _StudentEquipmentView extends StatefulWidget {
  const _StudentEquipmentView();

  @override
  State<_StudentEquipmentView> createState() => _StudentEquipmentViewState();
}

class _StudentEquipmentViewState extends State<_StudentEquipmentView> {
  bool _grid = true;
  String _availability = 'Semua';

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
    final assets = _applyAvailability(state.visibleAssets);

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Row(
            children: [
              const Expanded(child: StudentPageTitle(title: 'Inventory')),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _grid = !_grid),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                    color: studentInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: cubit.setQuery,
            decoration: InputDecoration(
              hintText: 'Cari peralatan...',
              hintStyle: const TextStyle(fontSize: 12, color: studentMuted),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: PopupMenuButton<String>(
                tooltip: 'Laboratorium',
                icon: const Icon(Icons.tune_rounded),
                onSelected: cubit.setLaboratory,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Semua',
                    child: Text('Semua laboratorium'),
                  ),
                  ...state.laboratories.map(
                    (lab) =>
                        PopupMenuItem(value: lab.id, child: Text(lab.name)),
                  ),
                ],
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: studentBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: studentBorder),
              ),
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filter('Semua'),
                const SizedBox(width: 7),
                _filter('Tersedia'),
                const SizedBox(width: 7),
                _filter('Dipinjam'),
                const SizedBox(width: 7),
                _filter('Maintenance'),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${assets.length} peralatan · ${state.labId == 'Semua' ? 'Semua laboratorium' : labMap[state.labId] ?? 'Laboratorium'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: studentMuted),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _grid = false),
                icon: Icon(
                  Icons.view_list_rounded,
                  color: !_grid ? studentInk : studentMuted,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _grid = true),
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: _grid ? studentInk : studentMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          if (assets.isEmpty)
            _empty(context)
          else if (_grid)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .70,
              ),
              itemBuilder: (context, index) {
                final asset = assets[index];
                return StudentAssetCard(
                  asset: asset,
                  labName: labMap[asset.labId] ?? 'Laboratorium',
                  onTap: () => context.push('/student/assets/${asset.id}'),
                );
              },
            )
          else
            ...assets.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: StudentAssetCard(
                  asset: asset,
                  labName: labMap[asset.labId] ?? 'Laboratorium',
                  compact: true,
                  onTap: () => context.push('/student/assets/${asset.id}'),
                ),
              ),
            ),
          if (!_grid && assets.isNotEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _manualCode(context, state.assets),
                style: FilledButton.styleFrom(
                  backgroundColor: studentLime,
                  foregroundColor: studentInk,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text(
                  'Scan QR',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _manualCode(
    BuildContext context,
    List<StudentAsset> assets,
  ) async {
    final controller = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: studentBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Masukkan Kode Aset',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 5),
              const Text(
                'Kode tertera pada label aset, misalnya MKT-R01.',
                style: TextStyle(fontSize: 11, color: studentMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Kode Aset',
                  suffixIcon: const Icon(Icons.qr_code_scanner_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(controller.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: studentInk,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Cari Aset'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (!context.mounted || code == null || code.trim().isEmpty) return;
    final normalized = code.trim().toLowerCase();
    StudentAsset? found;
    for (final asset in assets) {
      if (asset.code.toLowerCase() == normalized) {
        found = asset;
        break;
      }
    }
    if (!context.mounted) return;
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode aset tidak ditemukan.')),
      );
      return;
    }
    context.push('/student/assets/${found.id}');
  }

  Widget _filter(String label) {
    final selected = _availability == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _availability = label),
      selectedColor: studentInk,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? studentInk : studentBorder),
      labelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: selected ? studentLime : studentInk,
      ),
      shape: const StadiumBorder(),
    );
  }

  List<StudentAsset> _applyAvailability(List<StudentAsset> assets) {
    switch (_availability) {
      case 'Tersedia':
        return assets
            .where((asset) => asset.isAvailable)
            .toList(growable: false);
      case 'Dipinjam':
        return assets
            .where((asset) => asset.status == 'borrowed')
            .toList(growable: false);
      case 'Maintenance':
        return assets
            .where((asset) => asset.status == 'maintenance')
            .toList(growable: false);
      default:
        return assets;
    }
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 34, color: studentMuted),
          SizedBox(height: 10),
          Text(
            'Belum ketemu, nih.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5),
          Text(
            'Coba kata kunci atau filter lain.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: studentMuted),
          ),
        ],
      ),
    );
  }
}
