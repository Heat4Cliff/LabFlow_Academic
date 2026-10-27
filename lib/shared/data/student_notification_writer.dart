import 'package:cloud_firestore/cloud_firestore.dart';

/// Menulis notifikasi best-effort setelah transisi berhasil disimpan.
class StudentNotificationWriter {
  StudentNotificationWriter(this._firestore);
  final FirebaseFirestore _firestore;

  Future<void> borrowing(String requestId, String type) async {
    const copy = <String, (String, String)>{
      'borrow_approved': (
        'Peminjaman disetujui',
        'Pengajuan Anda telah disetujui.',
      ),
      'borrow_rejected': (
        'Peminjaman ditolak',
        'Pengajuan Anda mendapat keputusan dari Lab Admin.',
      ),
      'borrow_waiting_pickup': (
        'Menunggu pengambilan',
        'Aset sudah dialokasikan dan menunggu pengambilan.',
      ),
      'borrow_active': (
        'Peminjaman aktif',
        'Pengambilan aset telah diverifikasi.',
      ),
      'borrow_returned': (
        'Pengembalian selesai',
        'Proses pengembalian aset telah selesai.',
      ),
    };
    final message = copy[type];
    if (message == null) return;
    try {
      final request = await _firestore
          .collection('borrow_requests')
          .doc(requestId)
          .get();
      final data = request.data();
      if (data == null) return;
      await _firestore.collection('notifications').add({
        'studentId': data['studentId'],
        'type': type,
        'title': message.$1,
        'body': '${message.$2} (${data['requestNumber'] ?? requestId})',
        'targetType': 'borrow_request',
        'targetId': requestId,
        'labId': data['labId'],
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notifikasi tidak boleh membatalkan alur peminjaman yang sudah berhasil.
    }
  }

  Future<void> report(
    String reportId, {
    bool message = false,
    bool imageOnly = false,
  }) async {
    try {
      final report = await _firestore.collection('reports').doc(reportId).get();
      final data = report.data();
      if (data == null) return;
      final number = (data['reportNumber'] as String? ?? reportId).trim();
      await _firestore.collection('notifications').add({
        'studentId': data['reporterId'],
        'type': message ? 'report_message' : 'report_update',
        'title': message
            ? 'Pesan baru pada laporan'
            : 'Status laporan diperbarui',
        'body': message
            ? imageOnly
                  ? 'Mengirim sebuah gambar pada laporan $number.'
                  : 'Ada pesan baru pada laporan $number.'
            : 'Ada pembaruan pada laporan $number.',
        'targetType': 'report',
        'targetId': reportId,
        'labId': data['labId'],
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notifikasi tidak boleh membatalkan alur laporan atau pengiriman chat.
    }
  }
}
