import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/borrowing/domain/borrow_request.dart';
import 'package:labflow/features/borrowing/presentation/cubit/admin_borrow_request_detail_state.dart';
import 'package:labflow/features/borrowing/presentation/widgets/borrow_request_detail_cards.dart';

BorrowRequest request({String? name}) => BorrowRequest(
  id: 'request-doc',
  requestNumber: 'BRW-2026-TEST01',
  studentId: 'secret-auth-uid',
  studentName: name,
  labId: 'lab',
  purpose: 'Testing',
  borrowDate: DateTime(2026),
  expectedReturnDate: DateTime(2026, 1, 2),
  status: 'pending',
  studentNote: null,
  approvedBy: null,
  approvedAt: null,
  rejectionReason: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  testWidgets('borrower label uses full name and never renders auth UID', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorrowRequestIdentityCard(
            request: request(name: 'Nama Mahasiswa'),
          ),
        ),
      ),
    );
    expect(find.text('Nama Mahasiswa'), findsOneWidget);
    expect(find.text('secret-auth-uid'), findsNothing);
  });
  testWidgets('legacy borrower without name gets safe fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BorrowRequestIdentityCard(request: request())),
      ),
    );
    expect(find.text('Nama peminjam belum tersedia'), findsOneWidget);
    expect(find.text('secret-auth-uid'), findsNothing);
  });
  testWidgets('asset subtitle uses real inventory code and hides document ID', (
    tester,
  ) async {
    final item = BorrowRequestItem(
      id: 'item-doc',
      itemId: 'asset-document-id',
      itemName: 'ESP32 S3',
      quantity: 2,
      requestedAssetId: 'asset-document-id',
      requestedAssetCode: 'ESP32-S3-001',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorrowRequestItemsCard(
            state: AdminBorrowRequestDetailState(items: [item]),
          ),
        ),
      ),
    );
    expect(find.text('Jumlah 2 · Kode: ESP32-S3-001'), findsOneWidget);
    expect(find.textContaining('asset-document-id'), findsNothing);
  });
  testWidgets(
    'legacy asset without code keeps quantity and hides document ID',
    (tester) async {
      final item = BorrowRequestItem(
        id: 'item-doc',
        itemId: 'asset-document-id',
        itemName: 'ESP32 S3',
        quantity: 1,
        requestedAssetId: 'asset-document-id',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BorrowRequestItemsCard(
              state: AdminBorrowRequestDetailState(items: [item]),
            ),
          ),
        ),
      );
      expect(find.text('Jumlah 1'), findsOneWidget);
      expect(find.textContaining('asset-document-id'), findsNothing);
    },
  );
}
