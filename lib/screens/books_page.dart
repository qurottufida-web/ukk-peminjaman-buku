import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import 'book_form_page.dart';

/// Katalog buku. [isStaff] = true -> CRUD buku, false -> cari/filter & ajukan pinjam.
class BooksPage extends StatefulWidget {
  final bool isStaff;
  const BooksPage({super.key, required this.isStaff});
  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _kategori = '';
  late Future<List<Book>> _future;
  late Future<List<String>> _cats;

  @override
  void initState() {
    super.initState();
    _future = Api.books();
    _cats = Api.categories();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload({bool cats = false}) {
    setState(() {
      _future = Api.books(q: _search.text.trim(), kategori: _kategori);
      if (cats) _cats = Api.categories();
    });
  }

  Future<void> _openForm([Book? b]) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => BookFormPage(book: b)));
    if (saved == true) _reload(cats: true);
  }

  Future<void> _delete(Book b) async {
    if (!await confirmDialog(context, 'Hapus Buku', 'Hapus "${b.judul}"?', okLabel: 'Hapus')) return;
    try {
      await Api.deleteBook(b.id);
      if (!mounted) return;
      showSnack(context, 'Buku dihapus');
      _reload(cats: true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _borrow(Book b) async {
    if (!await confirmDialog(context, 'Ajukan Peminjaman',
        'Ajukan peminjaman "${b.judul}"?\nPetugas akan memproses pengajuan Anda.', okLabel: 'Ajukan')) return;
    try {
      await Api.requestLoan(b.id);
      if (mounted) showSnack(context, 'Pengajuan terkirim, menunggu persetujuan petugas.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (Api.user?.nama ?? '').split(' ').first;
    return Scaffold(
      floatingActionButton: widget.isStaff
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Buku'))
          : null,
      body: Column(children: [
        if (!widget.isStaff)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: FadeSlideIn(
              child: GradientBanner(
                icon: Icons.auto_stories,
                title: 'Halo, $firstName!',
                subtitle: 'Temukan buku favoritmu dan ajukan peminjaman.',
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Cari judul / pengarang / penerbit',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () { _search.clear(); _reload(); }),
            ),
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), _reload);
            },
          ),
        ),
        SizedBox(
          height: 50,
          child: FutureBuilder<List<String>>(
            future: _cats,
            builder: (context, s) {
              final cats = ['', ...(s.data ?? <String>[])];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => AppChoiceChip(
                  label: cats[i].isEmpty ? 'Semua' : cats[i],
                  selected: _kategori == cats[i],
                  onTap: () { _kategori = cats[i]; _reload(); },
                ),
              );
            },
          ),
        ),
        Expanded(
          child: AsyncBody<List<Book>>(
            future: _future,
            onRetry: () => _reload(cats: true),
            builder: (books) => RefreshIndicator(
              onRefresh: () async { _reload(cats: true); await _future; },
              child: books.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 60),
                      EmptyView(icon: Icons.menu_book_outlined, message: 'Buku tidak ditemukan'),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                      itemCount: books.length,
                      itemBuilder: (_, i) => _bookTile(books[i], i),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _badge(String text, IconData icon, {Color bg = const Color(0xFFEEF2FF), Color fg = const Color(0xFF3730A3)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _bookTile(Book b, int i) {
    final available = b.stok > 0;
    return FadeSlideIn(
      index: i,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.isStaff ? () => _openForm(b) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              // "Sampul" buku: huruf pertama judul
              Container(
                width: 52,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: categoryColor(b.kategori), borderRadius: BorderRadius.circular(10)),
                child: Text(b.judul.isEmpty ? '?' : b.judul[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.judul, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${b.pengarang} • ${b.penerbit}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _badge(b.kategori, Icons.label_outline),
                    _badge('Rak ${b.rak}', Icons.place_outlined),
                    _badge(
                      available ? 'Stok ${b.stok}' : 'Habis',
                      Icons.inventory_2_outlined,
                      bg: available ? Colors.green.shade50 : Colors.red.shade50,
                      fg: available ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ]),
                ]),
              ),
              if (widget.isStaff)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'edit' ? _openForm(b) : _delete(b),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                )
              else
                FilledButton.tonal(
                  onPressed: available ? () => _borrow(b) : null,
                  child: const Text('Pinjam'),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
