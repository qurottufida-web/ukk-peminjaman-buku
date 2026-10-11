import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Pendaftaran akun anggota (siswa).
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _c = {for (final k in ['nama', 'nis', 'kelas', 'email', 'telepon', 'password']) k: TextEditingController()};
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Api.register({for (final e in _c.entries) e.key: e.value.text.trim()});
      if (!mounted) return;
      showSnack(context, 'Registrasi berhasil, silakan login.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(String key, String label, IconData icon,
      {bool required = true, bool obscure = false, TextInputType? type, String? Function(String?)? extra}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _c[key],
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) return '$label wajib diisi';
          return extra?.call(v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Anggota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(children: [
            _field('nama', 'Nama Lengkap', Icons.person_outline),
            _field('nis', 'NIS', Icons.badge_outlined, type: TextInputType.number),
            _field('kelas', 'Kelas', Icons.class_outlined),
            _field('email', 'Email', Icons.email_outlined,
                type: TextInputType.emailAddress, extra: (v) => v!.contains('@') ? null : 'Email tidak valid'),
            _field('telepon', 'No. Telepon', Icons.phone_outlined, required: false, type: TextInputType.phone),
            _field('password', 'Password (min. 6 karakter)', Icons.lock_outline,
                obscure: true, extra: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('DAFTAR'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
