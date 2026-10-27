import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/reporting/data/report_conversation_service.dart';
import 'package:labflow/features/reporting/domain/report_message.dart';

void main() {
  test(
    'legacy text validation and image-only validation remain compatible',
    () {
      expect(ReportConversationService.validateMessage('teks'), isNull);
      expect(ReportConversationService.validateMessage(' '), isNotNull);
      expect(
        ReportConversationService.validateMessage('', hasImage: true),
        isNull,
      );
      expect(
        ReportConversationService.validateMessage('caption', hasImage: true),
        isNull,
      );
      expect(
        ReportConversationService.validateMessage('x' * 1001, hasImage: true),
        isNotNull,
      );
    },
  );

  test('legacy message defaults to text and image deletion is represented', () {
    final legacy = ReportMessage.fromData('legacy', {
      'senderId': 'student-1',
      'senderRole': 'student',
      'text': 'old message',
    });
    final deletedImage = ReportMessage.fromData('image', {
      'senderId': 'student-1',
      'senderRole': 'student',
      'text': '',
      'type': 'image',
      'imageUrl': 'https://example.invalid/image.jpg',
      'deletedAt': DateTime.utc(2026),
    });
    expect(legacy.type, 'text');
    expect(legacy.isDeleted, isFalse);
    expect(deletedImage.type, 'image');
    expect(deletedImage.isDeleted, isTrue);
    expect(deletedImage.imageUrl, isNotNull);
  });
}
