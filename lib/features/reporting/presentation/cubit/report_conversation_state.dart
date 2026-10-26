import '../../domain/report_message.dart';

enum ReportConversationStatus { initial, loading, loaded, failure }

class ReportConversationState {
  const ReportConversationState({
    this.status = ReportConversationStatus.initial,
    this.messages = const [],
    this.sending = false,
    this.errorMessage = '',
  });

  final ReportConversationStatus status;
  final List<ReportMessage> messages;
  final bool sending;
  final String errorMessage;

  ReportConversationState copyWith({
    ReportConversationStatus? status,
    List<ReportMessage>? messages,
    bool? sending,
    String? errorMessage,
  }) => ReportConversationState(
    status: status ?? this.status,
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
