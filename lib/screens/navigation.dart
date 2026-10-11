import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import 'anggota_home.dart';
import 'login_page.dart';
import 'petugas_home.dart';

/// Pilih beranda sesuai role (petugas / anggota).
Widget homeFor(AppUser u) => u.isStaff ? const PetugasHome() : const AnggotaHome();

/// Konfirmasi lalu logout dan kembali ke halaman login.
Future<void> doLogout(BuildContext context) async {
  if (!await confirmDialog(context, 'Keluar', 'Yakin ingin keluar dari aplikasi?', okLabel: 'Keluar')) return;
  await Api.logout();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(fadeRoute(const LoginPage()), (_) => false);
}
