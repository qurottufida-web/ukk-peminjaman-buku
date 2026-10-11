import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Kelola data anggota (khusus petugas).
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late Future<List<Member>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = Api.members();
  }

  void _reload() => setState(() => _future = Api.members());

  Future<void> _form([Member? m]) async {
    final key = GlobalKey<FormState>();
    final nama = TextEditingController(text: m?.nama);
    final nis = TextEditingController(text: m?.nis);
    final kelas = TextEditingController(text: m?.kelas);
    final email = TextEditingController(text: m?.email);
    final telp = TextEditingController(text: m?.telepon);
    final pass = TextEditingController();

    Widget f(TextEditingController c, String label,
            {bool obscure = false, TextInputType? type, String? Function(String?)? validator}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: c,
              obscureText: obscure,
              keyboardType: type,
              decoration: InputDecoration(labelText: label),
              validator: validator),
        );
    String? need(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m == null ? 'Tambah Anggota' : 'Edit Anggota'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              f(nama, 'Nama', validator: need),
              f(nis, 'NIS', validator: need),
              f(kelas, 'Kelas'),
              f(email, 'Email', type: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null),
              f(telp, 'Telepon', type: TextInputType.phone),
              f(pass, m == null ? 'Password' : 'Password (kosongkan jika tetap)', obscure: true,
                  validator: (v) {
                    if (m == null && (v == null || v.length < 6)) return 'Minimal 6 karakter';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  }),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
              onPressed: () { if (key.currentState!.validate()) Navigator.pop(ctx, true); },
              child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.saveMember({
        if (m != null) 'id': m.id,
        'nama': nama.text.trim(),
        'nis': nis.text.trim(),
        'kelas': kelas.text.trim(),
        'email': email.text.trim(),
        'telepon': telp.text.trim(),
        'password': pass.text,
      });
      if (!mounted) return;
      showSnack(context, m == null ? 'Anggota ditambahkan' : 'Anggota diperbarui');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(Member m) async {
    if (!await confirmDialog(context, 'Hapus Anggota', 'Hapus anggota "${m.nama}"?', okLabel: 'Hapus')) return;
    try {
      await Api.deleteMember(m.id);
      if (!mounted) return;
      showSnack(context, 'Anggota dihapus');
      _reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _form(),
          icon: const Icon(Icons.person_add),
          label: const Text('Tambah Anggota')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Cari nama / NIS', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: AsyncBody<List<Member>>(
            future: _future,
            onRetry: _reload,
            builder: (all) {
              final list = all
                  .where((m) => m.nama.toLowerCase().contains(_q) || m.nis.toLowerCase().contains(_q))
                  .toList();
              return RefreshIndicator(
                onRefresh: () async { _reload(); await _future; },
                child: list.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 60),
                        EmptyView(icon: Icons.people_outline, message: 'Belum ada data anggota'),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final m = list[i];
                          return FadeSlideIn(
                            index: i,
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: categoryColor(m.nama),
                                  child: Text(m.nama.isEmpty ? '?' : m.nama[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(m.nama, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('NIS ${m.nis} • ${m.kelas.isEmpty ? '-' : m.kelas}\n${m.email}'),
                                isThreeLine: true,
                                onTap: () => _form(m),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) => v == 'edit' ? _form(m) : _delete(m),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
