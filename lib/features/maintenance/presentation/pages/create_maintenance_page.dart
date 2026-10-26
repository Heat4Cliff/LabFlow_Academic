import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import '../cubit/create_maintenance_cubit.dart';
import '../cubit/create_maintenance_state.dart';

class CreateMaintenancePage extends StatelessWidget {
  const CreateMaintenancePage({
    required this.laboratoryId,
    this.initialAssetId,
    this.sourceType = 'manual',
    this.sourceId,
    this.initialDescription = '',
    super.key,
  });

  final String laboratoryId;
  final String? initialAssetId;
  final String sourceType;
  final String? sourceId;
  final String initialDescription;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateMaintenanceCubit(
        MaintenanceService(),
        laboratoryId,
        initialAssetId: initialAssetId,
        sourceType: sourceType,
        sourceId: sourceId,
        initialDescription: initialDescription,
      )..start(),
      child: const _CreateMaintenanceView(),
    );
  }
}

class _CreateMaintenanceView extends StatelessWidget {
  const _CreateMaintenanceView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateMaintenanceCubit, CreateMaintenanceState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != CreateMaintenanceActionStatus.idle,
      listener: (context, state) {
        if (state.actionStatus == CreateMaintenanceActionStatus.success) {
          context.pop(true);
          return;
        }

        final type = switch (state.actionStatus) {
          CreateMaintenanceActionStatus.warning =>
            LabFlowNotificationType.warning,
          CreateMaintenanceActionStatus.failure =>
            LabFlowNotificationType.error,
          CreateMaintenanceActionStatus.success =>
            LabFlowNotificationType.success,
          CreateMaintenanceActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == CreateMaintenanceActionStatus.warning
              ? 'Maintenance belum dapat dibuat'
              : 'Maintenance gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<CreateMaintenanceCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Tambah Maintenance',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CreateMaintenanceState state) {
    if (state.status == CreateMaintenanceStatus.initial ||
        state.status == CreateMaintenanceStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat aset',
        message: 'Menyiapkan aset yang tersedia untuk maintenance.',
      );
    }

    if (state.status == CreateMaintenanceStatus.failure) {
      return LabFlowConnectionErrorState(
        title: 'Form maintenance tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data aset tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBCB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unit yang masuk maintenance akan dikeluarkan dari stok '
                      'tersedia sampai proses penanganan selesai.',
                      style: TextStyle(
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Pilih Aset',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDE2D5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: state.selectedAssetId,
                  isExpanded: true,
                  hint: const Text('Pilih aset tersedia'),
                  items: state.assets
                      .map(
                        (asset) => DropdownMenuItem<String>(
                          value: asset.id,
                          child: Text(
                            '${asset.code} · ${asset.name} · Stok ${asset.stock}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: state.isProcessing
                      ? null
                      : context.read<CreateMaintenanceCubit>().selectAsset,
                ),
              ),
            ),
            if (state.assets.isEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Tidak ada aset available dengan stok yang dapat diproses.',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
              ),
            ],
            if (state.selectedAsset != null) ...[
              const SizedBox(height: 12),
              _assetSummary(state.selectedAsset!),
            ],
            const SizedBox(height: 22),
            const Text(
              'Jumlah Unit',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _quantityButton(
                  icon: Icons.remove_rounded,
                  enabled: state.quantity > 1 && !state.isProcessing,
                  onTap: () {
                    context.read<CreateMaintenanceCubit>().setQuantity(
                      state.quantity - 1,
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    state.quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _quantityButton(
                  icon: Icons.add_rounded,
                  enabled:
                      !state.isProcessing &&
                      state.selectedAsset != null &&
                      state.quantity < state.selectedAsset!.stock,
                  onTap: () {
                    context.read<CreateMaintenanceCubit>().setQuantity(
                      state.quantity + 1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              'Kondisi Masalah',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: MaintenanceIssueCondition.values
                  .map((condition) {
                    final selected = state.condition == condition;

                    return ChoiceChip(
                      label: Text(condition.label),
                      selected: selected,
                      onSelected: state.isProcessing
                          ? null
                          : (_) {
                              context
                                  .read<CreateMaintenanceCubit>()
                                  .setCondition(condition);
                            },
                      selectedColor: const Color(0xFFB9F33D),
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      side: const BorderSide(color: Color(0xFFDDE2D5)),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 22),
            const Text(
              'Deskripsi Masalah',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: state.description,
              enabled: !state.isProcessing,
              minLines: 4,
              maxLines: 6,
              onChanged: context.read<CreateMaintenanceCubit>().setDescription,
              decoration: InputDecoration(
                hintText:
                    'Jelaskan kerusakan atau pekerjaan yang perlu dilakukan...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
                ),
              ),
            ),
            if (state.validationMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                state.validationMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA86E00),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: state.canSubmit
                    ? context.read<CreateMaintenanceCubit>().submit
                    : null,
                icon: state.isProcessing
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: const Text(
                  'Buat Maintenance',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8BCB3),
                  disabledForegroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assetSummary(MaintenanceAssetOption asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF111111)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${asset.name}\n${asset.location} · Stok ${asset.stock}',
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return IconButton.filled(
      onPressed: enabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFDDE2D5),
      ),
      icon: Icon(icon),
    );
  }
}
