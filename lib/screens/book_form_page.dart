import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Form tambah / ubah buku. Mengembalikan `true` jika berhasil disimpan.
class BookFormPage extends StatefulWidget {
  final Book? book;
  const BookFormPage({super.key, this.book});
  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _c = {
      'judul': TextEditingController(text: b?.judul),
      'pengarang': TextEditingController(text: b?.pengarang),
      'penerbit': TextEditingController(text: b?.penerbit),
      'kategori': TextEditingController(text: b?.kategori),
      'stok': TextEditingController(text: b?.stok.toString()),
      'rak': TextEditingController(text: b?.rak),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Api.saveBook({
        if (widget.book != null) 'id': widget.book!.id,
        for (final e in _c.entries) e.key: e.value.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, widget.book == null ? 'Buku ditambahkan' : 'Buku diperbarui');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(String key, String label, {TextInputType? type, String? Function(String?)? extra}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label wajib diisi';
            return extra?.call(v);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book == null ? 'Tambah Buku' : 'Edit Buku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(children: [
            _field('judul', 'Judul'),
            _field('pengarang', 'Pengarang'),
            _field('penerbit', 'Penerbit'),
            _field('kategori', 'Kategori'),
            _field('stok', 'Stok',
                type: TextInputType.number,
                extra: (v) => (int.tryParse(v!) == null || int.parse(v) < 0) ? 'Stok harus angka >= 0' : null),
            _field('rak', 'Rak'),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('SIMPAN'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
