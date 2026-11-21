import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../asset/domain/laboratory_asset.dart';

class AssetQrPrintException implements Exception {
  const AssetQrPrintException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AssetQrPrintDriver {
  Future<bool> printPdf({
    required String jobName,
    required Uint8List pdfBytes,
  });

  Future<bool> sharePdf({
    required String fileName,
    required Uint8List pdfBytes,
    String? subject,
  });
}

class PrintingAssetQrPrintDriver implements AssetQrPrintDriver {
  const PrintingAssetQrPrintDriver();

  @override
  Future<bool> printPdf({
    required String jobName,
    required Uint8List pdfBytes,
  }) {
    return Printing.layoutPdf(
      name: jobName,
      format: PdfPageFormat.a4,
      onLayout: (_) async => pdfBytes,
    );
  }

  @override
  Future<bool> sharePdf({
    required String fileName,
    required Uint8List pdfBytes,
    String? subject,
  }) {
    return Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
      subject: subject,
    );
  }
}

class AssetQrPrintService {
  AssetQrPrintService({AssetQrPrintDriver? driver})
    : _driver = driver ?? const PrintingAssetQrPrintDriver();

  final AssetQrPrintDriver _driver;

  static const int maxQrPayloadLength = 512;

  /// Validates [rawQrValue] strictly without generating any substitute payload.
  static String validateQrPayload(String rawQrValue) {
    final clean = rawQrValue.trim();
    if (clean.isEmpty) {
      throw const AssetQrPrintException(
        'Nilai QR aset belum tersedia sehingga label tidak dapat dicetak.',
      );
    }
    if (clean.length > maxQrPayloadLength ||
        clean.contains('\n') ||
        clean.contains('\r')) {
      throw const AssetQrPrintException(
        'Nilai QR aset tidak valid sehingga label tidak dapat dibuat.',
      );
    }
    return clean;
  }

  static String buildPdfFileName(LaboratoryAsset asset) {
    final rawSlug = asset.code.trim().isNotEmpty
        ? asset.code.trim()
        : asset.id.trim();
    final sanitized = rawSlug
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final suffix = sanitized.isEmpty ? 'asset' : sanitized;
    return 'labflow_qr_$suffix.pdf';
  }

  /// Generates a monochrome, print-ready A4 PDF containing one asset QR label.
  Future<Uint8List> buildLabelPdf({
    required LaboratoryAsset asset,
    required String laboratoryName,
  }) async {
    final qrPayload = validateQrPayload(asset.qrValue);
    final assetName = _safePdfText(asset.name, fallback: 'Aset Laboratorium');
    final assetCode = _safePdfText(asset.code, fallback: '-');
    final cleanLabName = _safePdfText(
      laboratoryName,
      fallback: 'Laboratorium LabFlow',
    );
    final location = _safePdfText(asset.location, fallback: '-');
    final category = _safePdfText(asset.category, fallback: '-');
    final safeQrDisplay = _safePdfText(qrPayload, fallback: qrPayload);

    final regularFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final document = pw.Document(
      title: 'Label QR - $assetName',
      author: 'LabFlow Academic',
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Container(
              width: 300,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.black, width: 1.5),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1.2,
                          ),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'LABFLOW',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      pw.Text(
                        'LABEL INVENTARIS QR',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 8.5,
                          color: PdfColors.black,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.black, thickness: 1, height: 1),
                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 0.8,
                        ),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(
                          errorCorrectLevel:
                              pw.BarcodeQRCorrectionLevel.medium,
                        ),
                        data: qrPayload,
                        width: 156,
                        height: 156,
                        color: PdfColors.black,
                        backgroundColor: PdfColors.white,
                        drawText: false,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    assetName,
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.black, thickness: 0.6, height: 1),
                  pw.SizedBox(height: 8),
                  _labelMetaRow(
                    label: 'Kode Aset',
                    value: assetCode,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  pw.SizedBox(height: 4),
                  _labelMetaRow(
                    label: 'Laboratorium',
                    value: cleanLabName,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  pw.SizedBox(height: 4),
                  _labelMetaRow(
                    label: 'Kategori / Lokasi',
                    value: '$category | $location',
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  pw.SizedBox(height: 4),
                  _labelMetaRow(
                    label: 'ID QR',
                    value: safeQrDisplay,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 0.5,
                      ),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Pindai QR ini melalui menu Scan QR aplikasi LabFlow untuk identifikasi dan peminjaman aset.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return document.save();
  }

  Future<bool> printAssetQrLabel({
    required LaboratoryAsset asset,
    required String laboratoryName,
  }) async {
    final pdfBytes = await buildLabelPdf(
      asset: asset,
      laboratoryName: laboratoryName,
    );
    final fileName = buildPdfFileName(asset);
    return _driver.printPdf(jobName: fileName, pdfBytes: pdfBytes);
  }

  Future<bool> shareAssetQrLabel({
    required LaboratoryAsset asset,
    required String laboratoryName,
  }) async {
    final pdfBytes = await buildLabelPdf(
      asset: asset,
      laboratoryName: laboratoryName,
    );
    final fileName = buildPdfFileName(asset);
    final assetLabel = _safePdfText(asset.name, fallback: asset.code);
    return _driver.sharePdf(
      fileName: fileName,
      pdfBytes: pdfBytes,
      subject: 'Label QR Aset LabFlow - $assetLabel',
    );
  }

  static pw.Widget _labelMetaRow({
    required String label,
    required String value,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 86,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 9,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  static String _safePdfText(String raw, {required String fallback}) {
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2022', '|')
        .replaceAll('\u00B7', '|')
        .replaceAll(RegExp(r'[^\x20-\xFF]'), '');
    return normalized.isEmpty ? fallback : normalized;
  }
}
