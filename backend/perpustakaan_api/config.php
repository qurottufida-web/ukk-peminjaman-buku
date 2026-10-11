<?php
/**
 * config.php - Konfigurasi database, header JSON, dan fungsi bantu (helper).
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, X-Token');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

date_default_timezone_set('Asia/Jakarta');

const DB_HOST = 'localhost';
const DB_NAME = 'perpustakaan';
const DB_USER = 'root';   // default XAMPP
const DB_PASS = '';       // default XAMPP kosong

// false saat hosting: detail error tidak ditampilkan ke pengguna
const DEBUG = true;

const DENDA_PER_HARI = 1000; // Rp per hari keterlambatan
const LAMA_PINJAM    = 7;    // hari
const MAX_PINJAM     = 3;    // maksimal buku aktif per anggota

/** Kirim respons JSON lalu hentikan script. */
function respond($success, $message, $data = null, $code = 200) {
    http_response_code($code);
    echo json_encode(['success' => $success, 'message' => $message, 'data' => $data]);
    exit;
}
function ok($data = null, $msg = 'OK') { respond(true, $msg, $data); }
function fail($msg, $code = 400)       { respond(false, $msg, null, $code); }

try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER, DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
    );
} catch (PDOException $e) {
    fail('Koneksi database gagal. Pastikan MySQL di XAMPP aktif & database sudah di-import.', 500);
}

/**
 * Autentikasi lewat header X-Token. Jika $roles diisi, role user harus termasuk di dalamnya.
 * @return array data user yang sedang login
 */
function auth(array $roles = []) {
    global $pdo;
    $token = $_SERVER['HTTP_X_TOKEN'] ?? '';
    if ($token === '') fail('Sesi tidak valid, silakan login ulang.', 401);
    $st = $pdo->prepare('SELECT id,nama,email,role,nis,kelas,telepon FROM users WHERE token = ?');
    $st->execute([$token]);
    $u = $st->fetch();
    if (!$u) fail('Sesi berakhir, silakan login ulang.', 401);
    if ($roles && !in_array($u['role'], $roles)) fail('Anda tidak memiliki akses.', 403);
    return $u;
}
