import 'package:flutter/material.dart';
import 'screens/splash_page.dart';
import 'theme.dart';

void main() => runApp(const PerpustakaanApp());

class PerpustakaanApp extends StatelessWidget {
  const PerpustakaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Perpustakaan Digital',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Batasi lebar agar tampilan tetap rapi (mirip HP) saat dibuka di Chrome / tablet.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE3E8F2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}
