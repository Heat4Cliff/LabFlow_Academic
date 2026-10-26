import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/report_conversation_service.dart';
import '../../domain/report_message.dart';
import '../cubit/report_conversation_cubit.dart';
import '../cubit/report_conversation_state.dart';

class ReportConversationPanel extends StatelessWidget {
  const ReportConversationPanel({required this.reportId, super.key});
  final String reportId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        ReportConversationCubit(ReportConversationService())..watch(reportId),
    child: _ConversationView(reportId: reportId),
  );
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({required this.reportId});
  final String reportId;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportConversationCubit, ReportConversationState>(
      listenWhen: (previous, current) =>
          previous.messages.length != current.messages.length ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.messages.length > _lastCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.animateTo(
                _scroll.position.maxScrollExtent,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
              );
            }
          });
        }
        _lastCount = state.messages.length;
        if (state.errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage)));
        }
      },
      builder: (context, state) {
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
                const SizedBox(width: 9),
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
      },
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

  Widget _bubble(BuildContext context, ReportMessage message) {
    final cubit = context.read<ReportConversationCubit>();
    final own = message.senderId == cubit.currentUid;
    final color = own ? const Color(0xFFE2F0B9) : const Color(0xFFEAFBCB);
    final role = message.senderRole == 'lab_admin'
        ? 'Respons Lab Admin'
        : 'Student';

    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: own && !message.isDeleted
            ? () => cubit.delete(message.id)
            : null,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
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
                children: [
                  Icon(
                    own
                        ? Icons.person_outline_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
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
    final cubit = context.read<ReportConversationCubit>();
    await cubit.send(value);
    if (mounted &&
        cubit.state.errorMessage.isEmpty &&
        ReportConversationService.validateMessage(value) == null) {
      _text.clear();
    }
  }

  String _time(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
