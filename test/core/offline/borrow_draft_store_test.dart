import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/offline/borrow_draft_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('borrow draft is isolated by user and asset', () async {
    final store = SharedPreferencesBorrowDraftStore();
    final draft = BorrowRequestDraft(
      assetId: 'asset-1',
      quantity: 2,
      borrowDate: DateTime.utc(2026, 10, 27),
      returnDate: DateTime.utc(2026, 10, 28),
      purpose: 'Praktikum',
      note: '',
      updatedAt: DateTime.utc(2026, 10, 27, 9),
    );

    await store.write('user-a', draft);

    expect((await store.read('user-a', 'asset-1'))?.quantity, 2);
    expect(await store.read('user-b', 'asset-1'), isNull);
    expect(await store.read('user-a', 'asset-2'), isNull);
  });

  test('draft can be removed after successful submission', () async {
    final store = SharedPreferencesBorrowDraftStore();
    final draft = BorrowRequestDraft(
      assetId: 'asset-1',
      quantity: 1,
      borrowDate: DateTime.utc(2026, 10, 27),
      returnDate: DateTime.utc(2026, 10, 28),
      purpose: 'Praktikum',
      note: '',
      updatedAt: DateTime.utc(2026, 10, 27, 9),
    );
    await store.write('user-a', draft);

    await store.remove('user-a', 'asset-1');

    expect(await store.read('user-a', 'asset-1'), isNull);
  });
}
