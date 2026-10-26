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
  Widget build(BuildContext context) =>
      BlocConsumer<ReportConversationCubit, ReportConversationState>(
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
        builder: (context, state) => Container(
          height: 440,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE2D5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Percakapan laporan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Expanded(child: _messages(context, state)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF6F9EF),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.sending ? null : () => _send(context),
                    icon: state.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

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
          style: TextStyle(color: Color(0xFF686E63)),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      itemCount: state.messages.length,
      itemBuilder: (context, index) => _bubble(context, state.messages[index]),
    );
  }

  Widget _bubble(BuildContext context, ReportMessage message) {
    final cubit = context.read<ReportConversationCubit>();
    final own = message.senderId == cubit.currentUid;
    final color = own ? const Color(0xFFEAFBCB) : const Color(0xFFF0F2EC);
    final role = message.senderRole == 'lab_admin' ? 'Lab Admin' : 'Student';
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: own && !message.isDeleted
            ? () => cubit.delete(message.id)
            : null,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF686E63),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message.isDeleted ? 'Pesan telah dihapus' : message.text,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: message.isDeleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              if (message.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _time(message.createdAt!),
                  style: const TextStyle(fontSize: 9, color: Color(0xFF686E63)),
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
