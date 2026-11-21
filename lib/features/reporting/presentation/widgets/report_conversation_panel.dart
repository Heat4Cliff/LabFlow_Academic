import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/presentation/dialogs/labflow_confirmation_dialog.dart';
import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../data/report_conversation_service.dart';
import '../../domain/report_message.dart';
import '../cubit/report_conversation_cubit.dart';
import '../cubit/report_conversation_state.dart';

class ReportConversationPanel extends StatelessWidget {
  const ReportConversationPanel({
    required this.reportId,
    this.cubit,
    super.key,
  });

  final String reportId;
  final ReportConversationCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final child = _ConversationView(
      reportId: reportId,
      isPinnedLayout: false,
    );
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: child);
    }
    return BlocProvider(
      create: (_) =>
          ReportConversationCubit(ReportConversationService())..watch(reportId),
      child: child,
    );
  }
}

/// Layout detail laporan dengan riwayat percakapan yang dapat di-scroll dan
/// composer pesan yang selalu terlihat di bagian bawah layar.
class ReportDetailConversationLayout extends StatelessWidget {
  const ReportDetailConversationLayout({
    required this.reportId,
    required this.detailChildren,
    this.detailPadding = const EdgeInsets.fromLTRB(18, 14, 18, 0),
    this.horizontalPadding = 18,
    this.backgroundColor = const Color(0xFFF6F9EF),
    this.cubit,
    super.key,
  });

  final String reportId;
  final List<Widget> detailChildren;
  final EdgeInsets detailPadding;
  final double horizontalPadding;
  final Color backgroundColor;
  final ReportConversationCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final child = _ConversationView(
      reportId: reportId,
      isPinnedLayout: true,
      detailChildren: detailChildren,
      detailPadding: detailPadding,
      horizontalPadding: horizontalPadding,
      backgroundColor: backgroundColor,
    );
    if (cubit != null) {
      return BlocProvider.value(value: cubit!, child: child);
    }
    return BlocProvider(
      create: (_) =>
          ReportConversationCubit(ReportConversationService())..watch(reportId),
      child: child,
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.reportId,
    required this.isPinnedLayout,
    this.detailChildren = const <Widget>[],
    this.detailPadding = const EdgeInsets.fromLTRB(18, 14, 18, 0),
    this.horizontalPadding = 18,
    this.backgroundColor = const Color(0xFFF6F9EF),
  });

  final String reportId;
  final bool isPinnedLayout;
  final List<Widget> detailChildren;
  final EdgeInsets detailPadding;
  final double horizontalPadding;
  final Color backgroundColor;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;
  bool _hasInitializedMessages = false;
  bool _stickToBottom = false;
  String _lastShownError = '';
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialState = context.read<ReportConversationCubit>().state;
    if (initialState.status == ReportConversationStatus.loaded) {
      _hasInitializedMessages = true;
      _lastCount = initialState.messages.length;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!widget.isPinnedLayout || !_stickToBottom || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final viewInsetsBottom = View.of(context).viewInsets.bottom;
      if (viewInsetsBottom > 0) {
        _scrollToBottom(animate: false);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportConversationCubit, ReportConversationState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (!_hasInitializedMessages &&
            state.status == ReportConversationStatus.loaded) {
          _hasInitializedMessages = true;
          _lastCount = state.messages.length;
          if (!widget.isPinnedLayout && state.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        } else if (state.messages.length > _lastCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          _lastCount = state.messages.length;
        } else {
          _lastCount = state.messages.length;
        }
        if (state.errorMessage.isNotEmpty &&
            state.errorMessage != _lastShownError) {
          _lastShownError = state.errorMessage;
          showLabFlowNotification(
            context: context,
            message: state.errorMessage,
            type: LabFlowNotificationType.error,
          );
        } else if (state.errorMessage.isEmpty) {
          _lastShownError = '';
        }
      },
      builder: (context, state) {
        if (!widget.isPinnedLayout) {
          return _buildLegacyInlinePanel(context, state);
        }
        return _buildPinnedLayout(context, state);
      },
    );
  }

  Widget _buildPinnedLayout(
    BuildContext context,
    ReportConversationState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxComposerHeight = math.max(80.0, constraints.maxHeight * 0.65);
        return Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.vertical) {
                    _stickToBottom =
                        notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 48;
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: widget.detailPadding,
                      sliver: SliverList.list(
                        children: [
                          ...widget.detailChildren,
                          const SizedBox(height: 18),
                          const Text(
                            'Percakapan laporan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    _messagesSliver(context, state),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: const Border(
                  top: BorderSide(color: Color(0xFFDDE2D5)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxComposerHeight),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        widget.horizontalPadding,
                        10,
                        widget.horizontalPadding,
                        10,
                      ),
                      child: _composer(context, state),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegacyInlinePanel(
    BuildContext context,
    ReportConversationState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Percakapan laporan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 330),
          child: _messages(context, state),
        ),
        const SizedBox(height: 10),
        _composer(context, state),
      ],
    );
  }

  Widget _composer(BuildContext context, ReportConversationState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: 76,
                        height: 76,
                        cacheWidth: 152,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (state.sending)
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.sending
                        ? 'Mengunggah gambar...'
                        : 'Gambar siap dikirim',
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus gambar',
                  onPressed: state.sending
                      ? null
                      : () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCDD4E0)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(context),
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan...',
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Lampirkan gambar',
              onPressed: state.sending ? null : _chooseImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            SizedBox(
              width: 52,
              height: 52,
              child: IconButton.filled(
                onPressed: state.sending ? null : () => _send(context),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF5868AE),
                  foregroundColor: Colors.white,
                ),
                icon: state.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _messagesSliver(
    BuildContext context,
    ReportConversationState state,
  ) {
    if (state.status == ReportConversationStatus.initial ||
        state.status == ReportConversationStatus.loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.status == ReportConversationStatus.failure) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal: widget.horizontalPadding,
          ),
          child: Center(
            child: TextButton(
              onPressed: () => context.read<ReportConversationCubit>().retry(),
              child: const Text('Coba muat ulang percakapan'),
            ),
          ),
        ),
      );
    }
    if (state.messages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 24,
            horizontal: widget.horizontalPadding,
          ),
          child: const Center(
            child: Text(
              'Belum ada pesan. Mulai percakapan di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF737A70)),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      sliver: SliverList.builder(
        itemCount: state.messages.length,
        itemBuilder: (context, index) => _bubble(context, state.messages[index]),
      ),
    );
  }

  Widget _messages(BuildContext context, ReportConversationState state) {
    if (state.status == ReportConversationStatus.initial ||
        state.status == ReportConversationStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ReportConversationStatus.failure) {
      return Center(
        child: TextButton(
          onPressed: () => context.read<ReportConversationCubit>().retry(),
          child: const Text('Coba muat ulang percakapan'),
        ),
      );
    }
    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada pesan. Mulai percakapan di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF737A70)),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      shrinkWrap: true,
      itemCount: state.messages.length,
      itemBuilder: (context, index) => _bubble(context, state.messages[index]),
    );
  }

  Future<void> _confirmDeleteMessage(
    BuildContext context,
    ReportConversationCubit cubit,
    ReportMessage message,
  ) async {
    if (cubit.state.deletingIds.contains(message.id)) return;
    final deleted = await showDeleteConfirmationDialog(
      context: context,
      title: 'Hapus pesan?',
      description:
          'Apakah Anda yakin ingin menghapus pesan ini? '
          'Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
      onConfirm: () => cubit.delete(message.id),
    );
    if (deleted && context.mounted) {
      showLabFlowNotification(
        context: context,
        message: 'Pesan berhasil dihapus.',
        type: LabFlowNotificationType.success,
      );
    }
  }

  Widget _bubble(BuildContext context, ReportMessage message) {
    final cubit = context.read<ReportConversationCubit>();
    final own =
        cubit.currentUid.isNotEmpty && message.senderId == cubit.currentUid;
    final color = own ? const Color(0xFFE2F0B9) : const Color(0xFFEAFBCB);
    final role = message.senderRole == 'lab_admin'
        ? 'Respons Lab Admin'
        : 'Student';

    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: own && !message.isDeleted
            ? () => _confirmDeleteMessage(context, cubit, message)
            : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: math.min(300.0, MediaQuery.sizeOf(context).width * 0.82),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(own ? 22 : 7),
              bottomRight: Radius.circular(own ? 7 : 22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    own
                        ? Icons.person_outline_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (!message.isDeleted && message.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _showImage(context, message.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 260,
                          maxHeight: 260,
                        ),
                        child: Image.network(
                          message.imageUrl!,
                          cacheWidth: 780,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const SizedBox(
                                  width: 220,
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 220,
                            height: 100,
                            child: Center(child: Text('Gambar tidak tersedia')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (message.isDeleted || message.text.isNotEmpty)
                Text(
                  message.isDeleted ? 'Pesan telah dihapus' : message.text,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: message.isDeleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              if (message.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${role == 'Respons Lab Admin' ? 'Lab Admin' : 'Student'} · ${_time(message.createdAt!)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF737A70),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    final value = _text.text;
    final image = _selectedImage;
    final cubit = context.read<ReportConversationCubit>();
    await cubit.send(value, image: image);
    if (mounted &&
        cubit.state.errorMessage.isEmpty &&
        ReportConversationService.validateMessage(
              value,
              hasImage: image != null,
            ) ==
            null) {
      _text.clear();
      setState(() => _selectedImage = null);
    }
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );
      if (mounted && picked != null) setState(() => _selectedImage = picked);
    } catch (_) {
      if (mounted) {
        showLabFlowNotification(
          context: context,
          message: 'Gambar tidak dapat dipilih.',
          type: LabFlowNotificationType.error,
        );
      }
    }
  }

  void _showImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
