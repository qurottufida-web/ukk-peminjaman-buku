import 'package:flutter/material.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'books_page.dart';
import 'loans_page.dart';
import 'navigation.dart';

/// Beranda Anggota: Katalog, Riwayat (+ pengingat), Profil.
class AnggotaHome extends StatefulWidget {
  const AnggotaHome({super.key});
  @override
  State<AnggotaHome> createState() => _AnggotaHomeState();
}

class _AnggotaHomeState extends State<AnggotaHome> {
  int _index = 0;
  static const _titles = ['Katalog Buku', 'Riwayat Peminjaman', 'Profil Saya'];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const BooksPage(isStaff: false);
      case 1:
        return const LoansPage(isStaff: false);
      default:
        return const _ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: _page(_index)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Katalog'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final u = Api.user;
    if (u == null) return const SizedBox();
    return ListView(padding: const EdgeInsets.all(16), children: [
      FadeSlideIn(
        index: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(gradient: kGradient, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: Text(u.nama.isEmpty ? '?' : u.nama[0].toUpperCase(),
                  style: const TextStyle(fontSize: 34, color: kNavy, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(u.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Anggota Perpustakaan', style: TextStyle(color: Colors.white70)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      FadeSlideIn(
        index: 2,
        child: Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('NIS'), subtitle: Text(u.nis)),
            ListTile(leading: const Icon(Icons.class_outlined), title: const Text('Kelas'), subtitle: Text(u.kelas.isEmpty ? '-' : u.kelas)),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(u.email)),
            ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Telepon'), subtitle: Text(u.telepon.isEmpty ? '-' : u.telepon)),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      FadeSlideIn(
        index: 3,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => doLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ),
    ]);
  }
}
