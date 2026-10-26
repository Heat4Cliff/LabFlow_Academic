import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AssetImageService {
  AssetImageService({ImagePicker? imagePicker, http.Client? httpClient})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _httpClient = httpClient ?? http.Client();

  final ImagePicker _imagePicker;
  final http.Client _httpClient;

  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static const int _maximumImageBytes = 5 * 1024 * 1024;

  /// Memilih satu foto aset dari galeri perangkat.
  Future<XFile?> pickFromGallery() async {
    return _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
  }

  /// Mengunggah foto aset ke Cloudinary.
  ///
  /// Hanya secure URL yang akan disimpan ke Firestore.
  Future<String> uploadAssetImage({
    required XFile image,
    required String laboratoryId,
  }) async {
    _validateConfiguration();

    final file = File(image.path);
    if (!await file.exists()) {
      throw const AssetImageException(
        'File gambar yang dipilih tidak ditemukan.',
      );
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw const AssetImageException('File gambar kosong atau tidak valid.');
    }

    if (fileSize > _maximumImageBytes) {
      throw const AssetImageException('Ukuran gambar maksimal 5 MB.');
    }

    final extension = _fileExtension(image.name);
    if (!_allowedExtensions.contains(extension)) {
      throw const AssetImageException(
        'Format gambar harus JPG, JPEG, PNG, atau WEBP.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'labflow/assets/$laboratoryId';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        filename: image.name,
      ),
    );

    http.StreamedResponse response;
    try {
      response = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw const AssetImageException(
        'Tidak dapat terhubung ke layanan upload gambar.',
      );
    } on HttpException {
      throw const AssetImageException('Upload gambar gagal diproses.');
    } catch (_) {
      throw const AssetImageException(
        'Terjadi kesalahan saat mengunggah gambar.',
      );
    }

    final responseBody = await response.stream.bytesToString();

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final cloudinaryMessage = data?['error'] is Map<String, dynamic>
          ? (data?['error'] as Map<String, dynamic>)['message'] as String?
          : null;

      throw AssetImageException(
        cloudinaryMessage?.trim().isNotEmpty == true
            ? cloudinaryMessage!
            : 'Cloudinary menolak upload gambar.',
      );
    }

    final secureUrl = data?['secure_url'] as String?;
    if (secureUrl == null || secureUrl.trim().isEmpty) {
      throw const AssetImageException(
        'URL gambar tidak diterima dari Cloudinary.',
      );
    }

    return secureUrl.trim();
  }

  void _validateConfiguration() {
    if (_cloudName.trim().isEmpty) {
      throw const AssetImageException(
        'CLOUDINARY_CLOUD_NAME belum dikonfigurasi.',
      );
    }

    if (_uploadPreset.trim().isEmpty) {
      throw const AssetImageException(
        'CLOUDINARY_UPLOAD_PRESET belum dikonfigurasi.',
      );
    }
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
}

class AssetImageException implements Exception {
  const AssetImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
