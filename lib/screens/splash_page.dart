import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';
import 'navigation.dart';

/// Layar pembuka beranimasi. Sambil menunggu, cek sesi login yang tersimpan.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Tunggu minimal 1,6 detik supaya animasi sempat terlihat.
    final r = await Future.wait([
      Api.restoreSession(),
      Future.delayed(const Duration(milliseconds: 1600), () => true),
    ]);
    if (!mounted) return;
    final page = r[0] ? homeFor(Api.user!) : const LoginPage();
    Navigator.of(context).pushReplacement(fadeRoute(page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: kGradient),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Logo membesar dengan efek memantul
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10))],
                ),
                child: const Icon(Icons.local_library_rounded, size: 72, color: kNavy),
              ),
            ),
            const SizedBox(height: 28),
            // Teks muncul pelan
            const FadeSlideIn(
              index: 3,
              child: Column(children: [
                Text('Perpustakaan Digital',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Sistem Peminjaman Buku Sekolah', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }
}
