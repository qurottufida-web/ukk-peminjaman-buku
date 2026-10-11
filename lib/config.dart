import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Konfigurasi aplikasi.
class AppConfig {
  /// Isi HANYA jika menjalankan di HP asli, contoh: '192.168.1.5' (cek dengan `ipconfig`).
  /// Kosongkan ('') untuk emulator / Chrome. Saat hosting, isi dengan domain, mis. 'perpus.sekolah.sch.id'.
  static const String hostManual = '';

  static const String _path = '/perpustakaan_api/index.php';

  /// Alamat API dipilih otomatis:
  /// - hostManual terisi  -> http://hostManual/...
  /// - Emulator Android   -> http://10.0.2.2/...  (alias localhost laptop)
  /// - Chrome / Windows   -> http://localhost/...
  static String get baseUrl {
    if (hostManual.isNotEmpty) return 'http://$hostManual$_path';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2$_path';
    return 'http://localhost$_path';
  }

  /// Hanya untuk tampilan; perhitungan denda sebenarnya dilakukan server.
  static const int dendaPerHari = 1000;
}
