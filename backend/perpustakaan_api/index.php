<?php
/**
 * index.php - REST API Aplikasi Peminjaman Buku.
 * Pemakaian: index.php?action=NAMA_ACTION  (body JSON untuk POST)
 */
require __DIR__ . '/config.php';

$action = $_GET['action'] ?? '';
$in = json_decode(file_get_contents('php://input'), true);
if (!is_array($in)) $in = [];

/** Pastikan field wajib terisi. */
function req(array $in, array $keys) {
    foreach ($keys as $k) {
        if (!isset($in[$k]) || trim((string)$in[$k]) === '') fail("Field '$k' wajib diisi.");
    }
}
function today() { return date('Y-m-d'); }

/** Tambah / ubah anggota (dipakai register & kelola anggota). */
function saveUser(array $in, $id = null) {
    global $pdo;
    req($in, ['nama', 'email', 'nis']);
    if (!filter_var($in['email'], FILTER_VALIDATE_EMAIL)) fail('Format email tidak valid.');
    $pw = trim((string)($in['password'] ?? ''));
    if (!$id && strlen($pw) < 6) fail('Password minimal 6 karakter.');
    if ($pw !== '' && strlen($pw) < 6) fail('Password minimal 6 karakter.');

    $st = $pdo->prepare('SELECT id FROM users WHERE email=? AND id<>?');
    $st->execute([$in['email'], $id ?? 0]);
    if ($st->fetch()) fail('Email sudah terdaftar.');
    $st = $pdo->prepare('SELECT id FROM users WHERE nis=? AND id<>?');
    $st->execute([$in['nis'], $id ?? 0]);
    if ($st->fetch()) fail('NIS sudah terdaftar.');

    if ($id) {
        $pdo->prepare("UPDATE users SET nama=?,email=?,nis=?,kelas=?,telepon=? WHERE id=? AND role='anggota'")
            ->execute([$in['nama'], $in['email'], $in['nis'], $in['kelas'] ?? '', $in['telepon'] ?? '', $id]);
        if ($pw !== '') {
            $pdo->prepare('UPDATE users SET password=? WHERE id=?')->execute([password_hash($pw, PASSWORD_BCRYPT), $id]);
        }
        return $id;
    }
    $pdo->prepare("INSERT INTO users (nama,email,password,role,nis,kelas,telepon) VALUES (?,?,?,'anggota',?,?,?)")
        ->execute([$in['nama'], $in['email'], password_hash($pw, PASSWORD_BCRYPT), $in['nis'], $in['kelas'] ?? '', $in['telepon'] ?? '']);
    return (int)$pdo->lastInsertId();
}

/** Cek batas maksimal pinjaman aktif anggota. */
function cekBatas($uid) {
    global $pdo;
    $st = $pdo->prepare("SELECT COUNT(*) FROM peminjaman WHERE user_id=? AND status IN ('diajukan','dipinjam')");
    $st->execute([$uid]);
    if ((int)$st->fetchColumn() >= MAX_PINJAM) fail('Batas maksimal ' . MAX_PINJAM . ' buku (pinjam + pengajuan) sudah tercapai.');
}

function kodePinjam() { return 'PJM-' . date('ymdHis') . rand(10, 99); }

try {
switch ($action) {

// ---------------- AUTH ----------------
case 'register':
    $id = saveUser($in);
    ok(['id' => $id], 'Registrasi berhasil, silakan login.');

case 'login':
    req($in, ['email', 'password']);
    $st = $pdo->prepare('SELECT * FROM users WHERE email=?');
    $st->execute([$in['email']]);
    $u = $st->fetch();
    if (!$u || !password_verify($in['password'], $u['password'])) fail('Email atau password salah.', 401);
    $token = bin2hex(random_bytes(32));
    $pdo->prepare('UPDATE users SET token=? WHERE id=?')->execute([$token, $u['id']]);
    unset($u['password'], $u['token']);
    ok(['token' => $token, 'user' => $u], 'Login berhasil');

case 'me':
    ok(auth());

case 'logout':
    $u = auth();
    $pdo->prepare('UPDATE users SET token=NULL WHERE id=?')->execute([$u['id']]);
    ok(null, 'Logout berhasil');

// ---------------- BUKU ----------------
case 'categories':
    auth();
    ok($pdo->query('SELECT DISTINCT kategori FROM buku ORDER BY kategori')->fetchAll(PDO::FETCH_COLUMN));

case 'books':
    auth();
    $q = trim($_GET['q'] ?? ''); $kat = trim($_GET['kategori'] ?? '');
    $sql = 'SELECT * FROM buku WHERE 1=1'; $p = [];
    if ($q !== '')   { $sql .= ' AND (judul LIKE ? OR pengarang LIKE ? OR penerbit LIKE ?)'; array_push($p, "%$q%", "%$q%", "%$q%"); }
    if ($kat !== '') { $sql .= ' AND kategori=?'; $p[] = $kat; }
    $st = $pdo->prepare($sql . ' ORDER BY judul');
    $st->execute($p);
    ok($st->fetchAll());

case 'book_save':
    auth(['petugas']);
    req($in, ['judul', 'pengarang', 'penerbit', 'kategori', 'rak']);
    if (!isset($in['stok']) || !is_numeric($in['stok']) || (int)$in['stok'] < 0) fail('Stok harus angka >= 0.');
    $f = [$in['judul'], $in['pengarang'], $in['penerbit'], $in['kategori'], (int)$in['stok'], $in['rak']];
    if (!empty($in['id'])) {
        $f[] = (int)$in['id'];
        $pdo->prepare('UPDATE buku SET judul=?,pengarang=?,penerbit=?,kategori=?,stok=?,rak=? WHERE id=?')->execute($f);
        ok(null, 'Buku diperbarui');
    }
    $pdo->prepare('INSERT INTO buku (judul,pengarang,penerbit,kategori,stok,rak) VALUES (?,?,?,?,?,?)')->execute($f);
    ok(null, 'Buku ditambahkan');

case 'book_delete':
    auth(['petugas']);
    req($in, ['id']);
    try { $pdo->prepare('DELETE FROM buku WHERE id=?')->execute([(int)$in['id']]); }
    catch (PDOException $e) { fail('Buku tidak bisa dihapus karena sudah memiliki riwayat peminjaman.'); }
    ok(null, 'Buku dihapus');

// ---------------- ANGGOTA ----------------
case 'members':
    auth(['petugas']);
    ok($pdo->query("SELECT id,nama,email,nis,kelas,telepon FROM users WHERE role='anggota' ORDER BY nama")->fetchAll());

case 'member_save':
    auth(['petugas']);
    $id = !empty($in['id']) ? (int)$in['id'] : null;
    saveUser($in, $id);
    ok(null, $id ? 'Anggota diperbarui' : 'Anggota ditambahkan');

case 'member_delete':
    auth(['petugas']);
    req($in, ['id']);
    try { $pdo->prepare("DELETE FROM users WHERE id=? AND role='anggota'")->execute([(int)$in['id']]); }
    catch (PDOException $e) { fail('Anggota tidak bisa dihapus karena sudah memiliki riwayat peminjaman.'); }
    ok(null, 'Anggota dihapus');

// ---------------- SIRKULASI ----------------
case 'loans':
    $u = auth();
    $sql = "SELECT p.id,p.kode,p.buku_id,p.user_id,p.tgl_pinjam,p.tgl_jatuh_tempo,p.tgl_kembali,p.status,p.denda,
                   b.judul,b.pengarang,u.nama AS nama_anggota,u.nis,
                   CASE WHEN p.status='dipinjam' THEN GREATEST(DATEDIFF(?, p.tgl_jatuh_tempo),0)*" . DENDA_PER_HARI . " ELSE p.denda END AS denda_berjalan
            FROM peminjaman p JOIN buku b ON b.id=p.buku_id JOIN users u ON u.id=p.user_id WHERE 1=1";
    $p = [today()];
    if ($u['role'] === 'anggota') { $sql .= ' AND p.user_id=?'; $p[] = $u['id']; }
    $status = $_GET['status'] ?? '';
    if ($status !== '') { $sql .= ' AND p.status=?'; $p[] = $status; }
    $st = $pdo->prepare($sql . ' ORDER BY p.id DESC');
    $st->execute($p);
    ok($st->fetchAll());

case 'loan_request': // anggota mengajukan
    $u = auth(['anggota']);
    req($in, ['buku_id']);
    $bid = (int)$in['buku_id'];
    $st = $pdo->prepare('SELECT stok FROM buku WHERE id=?'); $st->execute([$bid]);
    $b = $st->fetch();
    if (!$b) fail('Buku tidak ditemukan.', 404);
    if ((int)$b['stok'] < 1) fail('Stok buku habis.');
    $st = $pdo->prepare("SELECT id FROM peminjaman WHERE user_id=? AND buku_id=? AND status IN ('diajukan','dipinjam')");
    $st->execute([$u['id'], $bid]);
    if ($st->fetch()) fail('Anda sudah mengajukan/meminjam buku ini.');
    cekBatas($u['id']);
    $pdo->prepare("INSERT INTO peminjaman (kode,buku_id,user_id,status) VALUES (?,?,?,'diajukan')")->execute([kodePinjam(), $bid, $u['id']]);
    ok(null, 'Pengajuan terkirim, menunggu persetujuan petugas.');

case 'loan_create': // petugas memproses langsung
    auth(['petugas']);
    req($in, ['user_id', 'buku_id']);
    $uid = (int)$in['user_id']; $bid = (int)$in['buku_id'];
    cekBatas($uid);
    $pdo->beginTransaction();
    $st = $pdo->prepare('SELECT stok FROM buku WHERE id=? FOR UPDATE'); $st->execute([$bid]);
    $b = $st->fetch();
    if (!$b || (int)$b['stok'] < 1) { $pdo->rollBack(); fail('Stok buku habis.'); }
    $pdo->prepare("INSERT INTO peminjaman (kode,buku_id,user_id,tgl_pinjam,tgl_jatuh_tempo,status) VALUES (?,?,?,?,?,'dipinjam')")
        ->execute([kodePinjam(), $bid, $uid, today(), date('Y-m-d', strtotime('+' . LAMA_PINJAM . ' days'))]);
    $pdo->prepare('UPDATE buku SET stok=stok-1 WHERE id=?')->execute([$bid]);
    $pdo->commit();
    ok(null, 'Transaksi peminjaman berhasil. Jatuh tempo ' . LAMA_PINJAM . ' hari.');

case 'loan_approve':
    auth(['petugas']);
    req($in, ['id']);
    $pdo->beginTransaction();
    $st = $pdo->prepare("SELECT * FROM peminjaman WHERE id=? AND status='diajukan' FOR UPDATE"); $st->execute([(int)$in['id']]);
    $l = $st->fetch();
    if (!$l) { $pdo->rollBack(); fail('Pengajuan tidak ditemukan / sudah diproses.'); }
    $st = $pdo->prepare('SELECT stok FROM buku WHERE id=? FOR UPDATE'); $st->execute([$l['buku_id']]);
    if ((int)$st->fetchColumn() < 1) { $pdo->rollBack(); fail('Stok buku habis, tidak bisa disetujui.'); }
    $pdo->prepare("UPDATE peminjaman SET status='dipinjam',tgl_pinjam=?,tgl_jatuh_tempo=? WHERE id=?")
        ->execute([today(), date('Y-m-d', strtotime('+' . LAMA_PINJAM . ' days')), $l['id']]);
    $pdo->prepare('UPDATE buku SET stok=stok-1 WHERE id=?')->execute([$l['buku_id']]);
    $pdo->commit();
    ok(null, 'Pengajuan disetujui');

case 'loan_reject':
    auth(['petugas']);
    req($in, ['id']);
    $pdo->prepare("UPDATE peminjaman SET status='ditolak' WHERE id=? AND status='diajukan'")->execute([(int)$in['id']]);
    ok(null, 'Pengajuan ditolak');

case 'loan_return':
    auth(['petugas']);
    req($in, ['id']);
    $pdo->beginTransaction();
    $st = $pdo->prepare("SELECT * FROM peminjaman WHERE id=? AND status='dipinjam' FOR UPDATE"); $st->execute([(int)$in['id']]);
    $l = $st->fetch();
    if (!$l) { $pdo->rollBack(); fail('Data peminjaman tidak ditemukan / sudah dikembalikan.'); }
    $telat = max(0, (int)floor((strtotime(today()) - strtotime($l['tgl_jatuh_tempo'])) / 86400));
    $denda = $telat * DENDA_PER_HARI;
    $pdo->prepare("UPDATE peminjaman SET status='dikembalikan',tgl_kembali=?,denda=? WHERE id=?")->execute([today(), $denda, $l['id']]);
    $pdo->prepare('UPDATE buku SET stok=stok+1 WHERE id=?')->execute([$l['buku_id']]);
    $pdo->commit();
    ok(['denda' => $denda, 'hari_telat' => $telat], $denda > 0 ? "Dikembalikan, terlambat $telat hari. Denda Rp $denda" : 'Buku dikembalikan tepat waktu');

// ---------------- LAPORAN ----------------
case 'report':
    auth(['petugas']);
    $one = function ($sql, $p = []) use ($pdo) { $s = $pdo->prepare($sql); $s->execute($p); return (int)$s->fetchColumn(); };
    $t = today();
    $data = [
        'total_buku'      => $one('SELECT COUNT(*) FROM buku'),
        'total_anggota'   => $one("SELECT COUNT(*) FROM users WHERE role='anggota'"),
        'diajukan'        => $one("SELECT COUNT(*) FROM peminjaman WHERE status='diajukan'"),
        'dipinjam'        => $one("SELECT COUNT(*) FROM peminjaman WHERE status='dipinjam'"),
        'terlambat'       => $one("SELECT COUNT(*) FROM peminjaman WHERE status='dipinjam' AND tgl_jatuh_tempo < ?", [$t]),
        'denda_terkumpul' => $one("SELECT COALESCE(SUM(denda),0) FROM peminjaman WHERE status='dikembalikan'"),
        'denda_berjalan'  => $one("SELECT COALESCE(SUM(GREATEST(DATEDIFF(?,tgl_jatuh_tempo),0)),0)*" . DENDA_PER_HARI . " FROM peminjaman WHERE status='dipinjam'", [$t]),
    ];
    $data['top_books'] = $pdo->query("SELECT b.judul,b.pengarang,COUNT(*) AS total FROM peminjaman p JOIN buku b ON b.id=p.buku_id
                                      WHERE p.status IN ('dipinjam','dikembalikan') GROUP BY b.id,b.judul,b.pengarang ORDER BY total DESC LIMIT 5")->fetchAll();
    $data['per_bulan'] = $pdo->query("SELECT DATE_FORMAT(tgl_pinjam,'%Y-%m') AS bulan, COUNT(*) AS total FROM peminjaman
                                      WHERE tgl_pinjam IS NOT NULL GROUP BY bulan ORDER BY bulan DESC LIMIT 6")->fetchAll();
    ok($data);

default:
    fail('Action tidak dikenal.', 404);
}
} catch (PDOException $e) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    fail(DEBUG ? 'Kesalahan database: ' . $e->getMessage() : 'Terjadi kesalahan pada server.', 500);
}
