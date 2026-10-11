import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/models.dart';

/// Error yang pesannya aman ditampilkan ke pengguna.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Semua komunikasi ke REST API (PHP + MySQL) lewat kelas ini.
class Api {
  static String? token;
  static AppUser? user;

  /// Request dasar. GET jika [body] null, selain itu POST (JSON).
  static Future<dynamic> _request(String action,
      {Map<String, String>? query, Map<String, dynamic>? body}) async {
    final uri = Uri.parse(AppConfig.baseUrl)
        .replace(queryParameters: {'action': action, ...?query});
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'X-Token': token!,
    };
    try {
      final res = body == null
          ? await http.get(uri, headers: headers).timeout(const Duration(seconds: 15))
          : await http.post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
      final json = jsonDecode(res.body);
      if (json['success'] != true) {
        throw ApiException(json['message']?.toString() ?? 'Terjadi kesalahan',
            statusCode: res.statusCode);
      }
      return json['data'];
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan Apache & MySQL XAMPP aktif dan alamat di config.dart benar.');
    } on TimeoutException {
      throw ApiException(kDebugMode
          ? 'Server tidak merespons (timeout). Alamat yang dipakai: ${AppConfig.baseUrl}'
          : 'Server tidak merespons. Coba lagi nanti.');
    } on http.ClientException {
      throw ApiException('Koneksi ke server gagal. Periksa alamat server.');
    } on FormatException {
      throw ApiException('Respons server tidak valid. Cek error PHP di browser.');
    }
  }

  // ---------- Sesi ----------
  static Future<bool> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    if (token == null) return false;
    try {
      user = AppUser.fromJson(Map<String, dynamic>.from(await _request('me')));
      return true;
    } catch (_) {
      token = null;
      await p.remove('token');
      return false;
    }
  }

  static Future<AppUser> login(String email, String password) async {
    final d = await _request('login', body: {'email': email, 'password': password});
    token = d['token'];
    user = AppUser.fromJson(Map<String, dynamic>.from(d['user']));
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    return user!;
  }

  static Future<void> register(Map<String, dynamic> data) => _request('register', body: data);

  static Future<void> logout() async {
    try {
      await _request('logout', body: {});
    } catch (_) {}
    token = null;
    user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }

  // ---------- Buku ----------
  static Future<List<Book>> books({String q = '', String kategori = ''}) async {
    final d = await _request('books', query: {'q': q, 'kategori': kategori});
    return (d as List).map((e) => Book.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<List<String>> categories() async {
    final d = await _request('categories');
    return (d as List).map((e) => e.toString()).toList();
  }

  static Future<void> saveBook(Map<String, dynamic> data) => _request('book_save', body: data);
  static Future<void> deleteBook(int id) => _request('book_delete', body: {'id': id});

  // ---------- Anggota ----------
  static Future<List<Member>> members() async {
    final d = await _request('members');
    return (d as List).map((e) => Member.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> saveMember(Map<String, dynamic> data) => _request('member_save', body: data);
  static Future<void> deleteMember(int id) => _request('member_delete', body: {'id': id});

  // ---------- Sirkulasi ----------
  static Future<List<Loan>> loans({String status = ''}) async {
    final d = await _request('loans', query: {'status': status});
    return (d as List).map((e) => Loan.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> requestLoan(int bukuId) => _request('loan_request', body: {'buku_id': bukuId});
  static Future<void> createLoan(int userId, int bukuId) =>
      _request('loan_create', body: {'user_id': userId, 'buku_id': bukuId});
  static Future<void> approveLoan(int id) => _request('loan_approve', body: {'id': id});
  static Future<void> rejectLoan(int id) => _request('loan_reject', body: {'id': id});
  static Future<void> returnLoan(int id) => _request('loan_return', body: {'id': id});

  // ---------- Laporan ----------
  static Future<Map<String, dynamic>> report() async =>
      Map<String, dynamic>.from(await _request('report'));
}
