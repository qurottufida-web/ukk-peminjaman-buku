import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Laporan rekapitulasi peminjaman & buku terfavorit.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.report();
  }

  void _reload() => setState(() => _future = Api.report());

  Widget _stat(double w, int index, String label, int value, IconData icon, Color color,
      {String Function(int)? format}) {
    return SizedBox(
      width: w,
      child: FadeSlideIn(
        index: index,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              AnimatedNumber(
                value: value,
                format: format,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Map<String, dynamic>>(
      future: _future,
      onRetry: _reload,
      builder: (d) {
        final top = (d['top_books'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        final bulan = (d['per_bulan'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        final maxBulan = bulan.map((e) => toInt(e['total'])).fold<int>(1, (a, c) => a > c ? a : c);
        const medals = [Color(0xFFF59E0B), Color(0xFF94A3B8), Color(0xFFB45309)];
        return RefreshIndicator(
          onRefresh: () async { _reload(); await _future; },
          child: ListView(padding: const EdgeInsets.all(12), children: [
            const FadeSlideIn(
              child: GradientBanner(
                icon: Icons.insights,
                title: 'Ringkasan Perpustakaan',
                subtitle: 'Data peminjaman terbaru',
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, cons) {
              final w = (cons.maxWidth - 10) / 2;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                _stat(w, 1, 'Judul Buku', toInt(d['total_buku']), Icons.menu_book, kBlue),
                _stat(w, 2, 'Anggota', toInt(d['total_anggota']), Icons.people, Colors.teal),
                _stat(w, 3, 'Sedang Dipinjam', toInt(d['dipinjam']), Icons.swap_horiz, Colors.indigo),
                _stat(w, 4, 'Menunggu Persetujuan', toInt(d['diajukan']), Icons.hourglass_top, Colors.orange),
                _stat(w, 5, 'Terlambat', toInt(d['terlambat']), Icons.warning_amber, Colors.red),
                _stat(w, 6, 'Denda Berjalan', toInt(d['denda_berjalan']), Icons.timer, Colors.deepOrange,
                    format: fmtRupiah),
                _stat(w, 7, 'Denda Terkumpul', toInt(d['denda_terkumpul']), Icons.payments, Colors.green,
                    format: fmtRupiah),
              ]);
            }),
            const SizedBox(height: 16),
            const Text('Buku Terfavorit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            FadeSlideIn(
              index: 3,
              child: Card(
                child: top.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data peminjaman'))
                    : Column(children: [
                        for (var i = 0; i < top.length; i++)
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i < 3 ? medals[i] : const Color(0xFFE5EAF5),
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: i < 3 ? Colors.white : Colors.black87)),
                            ),
                            title: Text(toStr(top[i]['judul'])),
                            subtitle: Text(toStr(top[i]['pengarang'])),
                            trailing: Text('${toInt(top[i]['total'])}x',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rekap Peminjaman per Bulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            FadeSlideIn(
              index: 4,
              child: Card(
                child: bulan.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data'))
                    : Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(children: [
                          for (final b in bulan)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(children: [
                                SizedBox(width: 80, child: Text(fmtBulan(toStr(b['bulan'])))),
                                Expanded(
                                  // ANIMASI: batang terisi perlahan
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: toInt(b['total']) / maxBulan),
                                    duration: const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, v, _) => LinearProgressIndicator(
                                      value: v,
                                      minHeight: 10,
                                      color: kBlue,
                                      backgroundColor: const Color(0xFFE5EAF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${toInt(b['total'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ]),
                            ),
                        ]),
                      ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
