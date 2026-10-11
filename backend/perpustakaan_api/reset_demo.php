<?php
// HANYA UNTUK LOKAL. Reset password akun demo menjadi "password".
// WAJIB DIHAPUS sebelum aplikasi di-hosting.
require __DIR__ . '/config.php';
if (!in_array($_SERVER['REMOTE_ADDR'] ?? '', ['127.0.0.1', '::1'], true)) {
    fail('Akses ditolak.', 403);
}
$hash = password_hash('password', PASSWORD_BCRYPT);
$pdo->prepare("UPDATE users SET password=? WHERE email IN ('petugas@perpus.com','raffi@siswa.com','claudy@siswa.com')")->execute([$hash]);
ok(null, 'Password akun demo direset menjadi: password');
