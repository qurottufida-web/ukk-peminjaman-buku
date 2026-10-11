import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'navigation.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final u = await Api.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(homeFor(u)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: kGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(48), bottomRight: Radius.circular(48)),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(children: [
                  const FadeSlideIn(
                    index: 0,
                    child: Column(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.local_library_rounded, size: 42, color: kNavy),
                      ),
                      SizedBox(height: 12),
                      Text('Perpustakaan Digital',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Masuk untuk melanjutkan', style: TextStyle(color: Colors.white70)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    index: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _form,
                          child: Column(children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                              validator: (v) => (v == null || !v.contains('@')) ? 'Masukkan email yang valid' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _pass,
                              obscureText: _hide,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _hide = !_hide),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                // ANIMASI: tulisan berganti halus menjadi loading
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _loading
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('MASUK', key: ValueKey('text')),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, fadeRoute(const RegisterPage())),
                              child: const Text('Belum punya akun? Daftar sebagai anggota'),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
