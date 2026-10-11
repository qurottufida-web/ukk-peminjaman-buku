import 'package:flutter/material.dart';
import '../services/api.dart';
import 'books_page.dart';
import 'loans_page.dart';
import 'members_page.dart';
import 'navigation.dart';
import 'report_page.dart';

/// Beranda Petugas: Buku, Anggota, Sirkulasi, Laporan.
class PetugasHome extends StatefulWidget {
  const PetugasHome({super.key});
  @override
  State<PetugasHome> createState() => _PetugasHomeState();
}

class _PetugasHomeState extends State<PetugasHome> {
  int _index = 0;
  static const _titles = ['Data Buku', 'Data Anggota', 'Sirkulasi', 'Laporan'];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const BooksPage(isStaff: true);
      case 1:
        return const MembersPage();
      case 2:
        return const LoansPage(isStaff: true);
      default:
        return const ReportPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Center(child: Text(Api.user?.nama.split(' ').first ?? '', style: const TextStyle(fontSize: 13))),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Keluar', onPressed: () => doLogout(context)),
        ],
      ),
      // ANIMASI: perpindahan tab memudar halus
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_index), child: _page(_index)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Buku'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Anggota'),
          NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Sirkulasi'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Laporan'),
        ],
      ),
    );
  }
}
