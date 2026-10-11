import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Sirkulasi. Petugas: proses pinjam/kembali + denda. Anggota: riwayat + pengingat jatuh tempo.
class LoansPage extends StatefulWidget {
  final bool isStaff;
  const LoansPage({super.key, required this.isStaff});
  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  static const _filters = ['', 'diajukan', 'dipinjam', 'dikembalikan', 'ditolak'];
  String _status = '';
  late Future<List<Loan>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.loans();
  }

  void _reload() => setState(() => _future = Api.loans(status: _status));

  /// Jalankan aksi API, tampilkan pesan, lalu muat ulang daftar.
  Future<void> _run(Future<dynamic> Function() action, String okMsg) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, okMsg);
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _return(Loan l) async {
    final msg = 'Buku: ${l.judul}\nPeminjam: ${l.namaAnggota}\n'
        'Jatuh tempo: ${fmtDate(l.tglJatuhTempo)}\n'
        '${l.terlambat ? 'Terlambat ${-(l.sisaHari ?? 0)} hari\n' : ''}'
        'Denda: ${fmtRupiah(l.dendaBerjalan)}\n\nProses pengembalian?';
    if (!await confirmDialog(context, 'Pengembalian Buku', msg, okLabel: 'Proses')) return;
    await _run(() => Api.returnLoan(l.id),
        l.dendaBerjalan > 0 ? 'Dikembalikan. Denda ${fmtRupiah(l.dendaBerjalan)}' : 'Buku dikembalikan');
  }

  /// Dialog transaksi pinjam langsung oleh petugas.
  Future<void> _create() async {
    try {
      final r = await Future.wait([Api.members(), Api.books()]);
      final members = r[0] as List<Member>;
      final books = (r[1] as List<Book>).where((b) => b.stok > 0).toList();
      if (!mounted) return;
      int? uid, bid;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: const Text('Transaksi Peminjaman'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Anggota'),
                items: members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text('${m.nama} (${m.nis})', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setS(() => uid = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Buku (stok tersedia)'),
                items: books
                    .map((b) => DropdownMenuItem(value: b.id, child: Text('${b.judul} (${b.stok})', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setS(() => bid = v),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              FilledButton(
                  onPressed: (uid != null && bid != null) ? () => Navigator.pop(ctx, true) : null,
                  child: const Text('Proses')),
            ],
          ),
        ),
      );
      if (ok == true) await _run(() => Api.createLoan(uid!, bid!), 'Transaksi peminjaman berhasil');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.isStaff
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _create,
              icon: const Icon(Icons.add_task),
              label: const Text('Pinjam Baru'))
          : null,
      body: Column(children: [
        if (widget.isStaff)
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => AppChoiceChip(
                label: _filters[i].isEmpty ? 'Semua' : _filters[i][0].toUpperCase() + _filters[i].substring(1),
                selected: _status == _filters[i],
                onTap: () { _status = _filters[i]; _reload(); },
              ),
            ),
          ),
        Expanded(
          child: AsyncBody<List<Loan>>(
            future: _future,
            onRetry: _reload,
            builder: (loans) {
              // Pengingat: buku yang jatuh tempo <= 2 hari atau sudah terlambat.
              final reminders = widget.isStaff
                  ? <Loan>[]
                  : loans.where((l) => l.status == 'dipinjam' && (l.sisaHari ?? 99) <= 2).toList();
              return RefreshIndicator(
                onRefresh: () async { _reload(); await _future; },
                child: loans.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 60),
                        EmptyView(icon: Icons.receipt_long_outlined, message: 'Belum ada data peminjaman'),
                      ])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        children: [
                          if (reminders.isNotEmpty) FadeSlideIn(child: _reminderBanner(reminders)),
                          for (var i = 0; i < loans.length; i++) _loanCard(loans[i], i),
                        ],
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _reminderBanner(List<Loan> items) {
    return Card(
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade400),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.notifications_active, color: Colors.orange.shade900),
            const SizedBox(width: 8),
            const Text('Pengingat Pengembalian', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          for (final l in items)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l.terlambat
                  ? '• "${l.judul}" terlambat ${-(l.sisaHari ?? 0)} hari (denda ${fmtRupiah(l.dendaBerjalan)})'
                  : (l.sisaHari == 0
                      ? '• "${l.judul}" jatuh tempo HARI INI'
                      : '• "${l.judul}" jatuh tempo ${l.sisaHari} hari lagi')),
            ),
        ]),
      ),
    );
  }

  Widget _loanCard(Loan l, int i) {
    return FadeSlideIn(
      index: i,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 5, color: statusColor(l.status)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(l.judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    StatusChip(l.status),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.isStaff ? 'Peminjam: ${l.namaAnggota} (${l.nis})' : l.pengarang,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  if (l.tglPinjam != null)
                    Text('Pinjam: ${fmtDate(l.tglPinjam)}  •  Jatuh tempo: ${fmtDate(l.tglJatuhTempo)}',
                        style: const TextStyle(fontSize: 13)),
                  if (l.status == 'diajukan')
                    const Text('Menunggu persetujuan petugas', style: TextStyle(fontSize: 13)),
                  if (l.status == 'dipinjam')
                    Text(
                      l.terlambat
                          ? 'Terlambat ${-(l.sisaHari ?? 0)} hari • Denda ${fmtRupiah(l.dendaBerjalan)}'
                          : 'Sisa waktu ${l.sisaHari} hari',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: l.terlambat ? Colors.red.shade700 : Colors.green.shade800),
                    ),
                  if (l.status == 'dikembalikan')
                    Text('Dikembalikan: ${fmtDate(l.tglKembali)}${l.denda > 0 ? '  •  Denda ${fmtRupiah(l.denda)}' : ''}',
                        style: const TextStyle(fontSize: 13)),
                  if (widget.isStaff && l.status == 'diajukan')
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(spacing: 8, children: [
                        TextButton(
                            onPressed: () => _run(() => Api.rejectLoan(l.id), 'Pengajuan ditolak'),
                            child: const Text('Tolak')),
                        FilledButton(
                            onPressed: () => _run(() => Api.approveLoan(l.id), 'Pengajuan disetujui'),
                            child: const Text('Setujui')),
                      ]),
                    ),
                  if (widget.isStaff && l.status == 'dipinjam')
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                          onPressed: () => _return(l),
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Kembalikan')),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
