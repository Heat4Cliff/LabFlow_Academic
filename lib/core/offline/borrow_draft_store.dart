import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BorrowRequestDraft {
  const BorrowRequestDraft({
    required this.assetId,
    required this.quantity,
    required this.borrowDate,
    required this.returnDate,
    required this.purpose,
    required this.note,
    required this.updatedAt,
  });

  final String assetId;
  final int quantity;
  final DateTime borrowDate;
  final DateTime returnDate;
  final String purpose;
  final String note;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'assetId': assetId,
    'quantity': quantity,
    'borrowDate': borrowDate.toIso8601String(),
    'returnDate': returnDate.toIso8601String(),
    'purpose': purpose,
    'note': note,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BorrowRequestDraft.fromJson(Map<String, dynamic> json) =>
      BorrowRequestDraft(
        assetId: json['assetId'] as String,
        quantity: json['quantity'] as int,
        borrowDate: DateTime.parse(json['borrowDate'] as String),
        returnDate: DateTime.parse(json['returnDate'] as String),
        purpose: json['purpose'] as String? ?? '',
        note: json['note'] as String? ?? '',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

abstract interface class BorrowDraftStore {
  Future<BorrowRequestDraft?> read(String uid, String assetId);
  Future<void> write(String uid, BorrowRequestDraft draft);
  Future<void> remove(String uid, String assetId);
}

class SharedPreferencesBorrowDraftStore implements BorrowDraftStore {
  SharedPreferencesBorrowDraftStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  String _key(String uid, String assetId) =>
      'offline_borrow_draft_v1/${Uri.encodeComponent(uid)}/${Uri.encodeComponent(assetId)}';

  @override
  Future<BorrowRequestDraft?> read(String uid, String assetId) async {
    final value = await _preferences.getString(_key(uid, assetId));
    if (value == null) return null;
    try {
      return BorrowRequestDraft.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
    } on Object {
      await remove(uid, assetId);
      return null;
    }
  }

  @override
  Future<void> write(String uid, BorrowRequestDraft draft) async {
    await _preferences.setString(
      _key(uid, draft.assetId),
      jsonEncode(draft.toJson()),
    );
  }

  @override
  Future<void> remove(String uid, String assetId) =>
      _preferences.remove(_key(uid, assetId));
}
