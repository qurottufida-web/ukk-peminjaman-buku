import 'package:flutter/material.dart';
import '../theme.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// 3500 -> "Rp 3.500"
String fmtRupiah(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp ${n < 0 ? '-' : ''}$b';
}

/// "2026-10-09" -> "9 Okt 2026"
String fmtDate(String? d) {
  final t = d == null ? null : DateTime.tryParse(d);
  if (t == null) return '-';
  return '${t.day} ${_bulan[t.month - 1]} ${t.year}';
}

/// "2026-10" -> "Okt 2026"
String fmtBulan(String ym) {
  final p = ym.split('-');
  if (p.length != 2) return ym;
  final m = int.tryParse(p[1]) ?? 1;
  return '${_bulan[(m - 1).clamp(0, 11)]} ${p[0]}';
}

/// Warna tetap untuk sebuah teks (dipakai untuk sampul buku & avatar).
Color categoryColor(String s) {
  const palette = [
    Color(0xFF1E3A8A), Color(0xFF0F766E), Color(0xFF7E22CE), Color(0xFFB45309),
    Color(0xFFBE123C), Color(0xFF0369A1), Color(0xFF4D7C0F),
  ];
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h + c) % 1000;
  }
  return palette[h % palette.length];
}

MaterialColor statusColor(String s) {
  switch (s) {
    case 'diajukan':
      return Colors.orange;
    case 'dipinjam':
      return Colors.blue;
    case 'dikembalikan':
      return Colors.green;
    case 'ditolak':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Pindah halaman dengan efek fade.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : kNavy,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String okLabel = 'Ya'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(okLabel)),
      ],
    ),
  );
  return r == true;
}

/// ANIMASI 1: muncul pelan (fade) sambil bergeser naik. [index] membuat item muncul berurutan.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final ms = 350 + index.clamp(0, 8) * 70;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOutCubic,
      builder: (context, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: ch),
      ),
      child: child,
    );
  }
}

/// ANIMASI 2: angka menghitung naik dari 0.
class AnimatedNumber extends StatelessWidget {
  final int value;
  final String Function(int)? format;
  final TextStyle? style;
  const AnimatedNumber({super.key, required this.value, this.format, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.round();
        return Text(format != null ? format!(n) : '$n', style: style);
      },
    );
  }
}

/// Banner gradient (sapaan / judul bagian).
class GradientBanner extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const GradientBanner({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

/// Chip filter bergaya aplikasi.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AppChoiceChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
        selected: selected,
        showCheckmark: false,
        selectedColor: kNavy,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? kNavy : const Color(0xFFD5DCEB)),
        onSelected: (_) => onTap(),
      );
}

/// Tampilan saat data kosong (dengan animasi membesar halus).
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 72, color: Colors.blueGrey.shade200),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade400)),
            ]),
          ),
        ),
      );
}

/// Tampilan saat terjadi error + tombol coba lagi.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi')),
          ]),
        ),
      );
}

/// Pembungkus FutureBuilder: loading -> error -> data.
class AsyncBody<T> extends StatelessWidget {
  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  const AsyncBody({super.key, required this.future, required this.onRetry, required this.builder});

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: onRetry);
          return builder(snap.data as T);
        },
      );
}

/// Label status peminjaman berwarna.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.shade100, borderRadius: BorderRadius.circular(20)),
      child: Text(status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1),
          style: TextStyle(color: c.shade900, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
