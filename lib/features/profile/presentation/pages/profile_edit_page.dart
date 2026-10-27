import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/profile_edit_service.dart';
import '../cubit/profile_edit_cubit.dart';

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({required this.returnPath, super.key});

  final String returnPath;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ProfileEditCubit(ProfileEditService())..load(),
    child: _ProfileEditView(returnPath: returnPath),
  );
}

class _ProfileEditView extends StatefulWidget {
  const _ProfileEditView({required this.returnPath});

  final String returnPath;

  @override
  State<_ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<_ProfileEditView> {
  final TextEditingController _nameController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.returnPath);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !context.canPop()) context.go(widget.returnPath);
    },
    child: BlocConsumer<ProfileEditCubit, ProfileEditState>(
      listener: (context, state) {
        if (state.profile != null && !_initialized) {
          _initialized = true;
          _nameController.text = state.profile!.fullName;
        }
        if (state.status == ProfileEditStatus.success) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go(widget.returnPath);
          }
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFFF6F9EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F9EF),
          title: const Text(
            'Edit Profil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: switch (state.status) {
            ProfileEditStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            ProfileEditStatus.failure when state.profile == null => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage),
                  TextButton(
                    onPressed: context.read<ProfileEditCubit>().load,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
            _ => ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                const Text(
                  'Nama lengkap',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 17),
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  enabled: state.status != ProfileEditStatus.saving,
                  onChanged: context.read<ProfileEditCubit>().setFullName,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: const TextStyle(fontSize: 16),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (state.errorMessage.isNotEmpty)
                  Text(
                    state.errorMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB42318),
                    ),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: state.status == ProfileEditStatus.saving
                      ? null
                      : context.read<ProfileEditCubit>().save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF111111),
                  ),
                  child: state.status == ProfileEditStatus.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Email, role, status, UID, dan assignment laboratorium '
                  'dikelola administrator.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    ),
  );
}
