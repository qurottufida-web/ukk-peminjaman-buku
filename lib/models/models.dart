/// Model data aplikasi + helper konversi tipe.

int toInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
String toStr(dynamic v) => v?.toString() ?? '';

/// Pengguna yang login (petugas / anggota).
class AppUser {
  final int id;
  final String nama, email, role, nis, kelas, telepon;

  AppUser({required this.id, required this.nama, required this.email, required this.role,
      required this.nis, required this.kelas, required this.telepon});

  bool get isStaff => role == 'petugas';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: toInt(j['id']),
        nama: toStr(j['nama']),
        email: toStr(j['email']),
        role: toStr(j['role']),
        nis: toStr(j['nis']),
        kelas: toStr(j['kelas']),
        telepon: toStr(j['telepon']),
      );
}

class Book {
  final int id, stok;
  final String judul, pengarang, penerbit, kategori, rak;

  Book({required this.id, required this.judul, required this.pengarang, required this.penerbit,
      required this.kategori, required this.stok, required this.rak});

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: toInt(j['id']),
        judul: toStr(j['judul']),
        pengarang: toStr(j['pengarang']),
        penerbit: toStr(j['penerbit']),
        kategori: toStr(j['kategori']),
        stok: toInt(j['stok']),
        rak: toStr(j['rak']),
      );
}

class Member {
  final int id;
  final String nama, email, nis, kelas, telepon;

  Member({required this.id, required this.nama, required this.email, required this.nis,
      required this.kelas, required this.telepon});

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: toInt(j['id']),
        nama: toStr(j['nama']),
        email: toStr(j['email']),
        nis: toStr(j['nis']),
        kelas: toStr(j['kelas']),
        telepon: toStr(j['telepon']),
      );
}

class Loan {
  final int id, bukuId, userId, denda, dendaBerjalan;
  final String kode, judul, pengarang, namaAnggota, nis, status;
  final String? tglPinjam, tglJatuhTempo, tglKembali;

  Loan({required this.id, required this.bukuId, required this.userId, required this.denda,
      required this.dendaBerjalan, required this.kode, required this.judul, required this.pengarang,
      required this.namaAnggota, required this.nis, required this.status,
      this.tglPinjam, this.tglJatuhTempo, this.tglKembali});

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: toInt(j['id']),
        bukuId: toInt(j['buku_id']),
        userId: toInt(j['user_id']),
        denda: toInt(j['denda']),
        dendaBerjalan: toInt(j['denda_berjalan']),
        kode: toStr(j['kode']),
        judul: toStr(j['judul']),
        pengarang: toStr(j['pengarang']),
        namaAnggota: toStr(j['nama_anggota']),
        nis: toStr(j['nis']),
        status: toStr(j['status']),
        tglPinjam: j['tgl_pinjam']?.toString(),
        tglJatuhTempo: j['tgl_jatuh_tempo']?.toString(),
        tglKembali: j['tgl_kembali']?.toString(),
      );

  /// Sisa hari menuju jatuh tempo (negatif = terlambat). Null jika belum dipinjam.
  int? get sisaHari {
    final d = tglJatuhTempo == null ? null : DateTime.tryParse(tglJatuhTempo!);
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }

  bool get terlambat => status == 'dipinjam' && (sisaHari ?? 0) < 0;
}
