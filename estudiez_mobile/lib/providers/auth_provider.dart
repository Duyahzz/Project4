import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String _apiBaseUrl = ApiService.defaultBaseUrl;
  late ApiService _apiService;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get apiBaseUrl => _apiBaseUrl;
  ApiService get apiService => _apiService;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _apiService = ApiService(customBaseUrl: _apiBaseUrl);
    _loadSession();
  }

  // ─── Set custom API URL ───────────────────────────────────────────────────
  Future<void> setApiBaseUrl(String url) async {
    if (url.isEmpty) return;
    _apiBaseUrl = url;
    _apiService = ApiService(customBaseUrl: _apiBaseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
    notifyListeners();
  }

  // ─── Load session on startup ────────────────────────────────────────────────
  Future<void> _loadSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load custom URL if exists
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _apiBaseUrl = savedUrl;
        _apiService = ApiService(customBaseUrl: _apiBaseUrl);
      }

      final savedUserJson = prefs.getString('current_user');
      if (savedUserJson != null) {
        final Map<String, dynamic> userMap = json.decode(savedUserJson);
        _currentUser = User.fromJson(userMap);
        
        // Load API name/email caches on startup if logged in (in background)
        _apiService.loadUserCaches();
      }
    } catch (e) {
      print('[AuthProvider] Load session error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Login ──────────────────────────────────────────────────────────────────
  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loginData = await _apiService.login(username, password);
      if (loginData != null) {
        // Map backend LoginResponse to canonical User object
        final roleStr = (loginData['role'] ?? 'STUDENT').toString().toLowerCase();
        
        // Synthesise email if null
        final email = loginData['email'] ?? '$username@estudiez.edu.vn';

        final user = User(
          userId: loginData['userId'],
          username: loginData['username'] ?? username,
          fullName: loginData['fullName'] ?? 'User',
          email: email,
          phone: loginData['phone'],
          role: roleStr,
          isActive: loginData['isActive'] ?? true,
        );

        _currentUser = user;

        // Save session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', json.encode(user.toJson()));

        _isLoading = false;
        notifyListeners();
        return null; // Return null on success
      }
    } catch (e) {
      print('[AuthProvider] Login error: $e');
      _isLoading = false;
      notifyListeners();
      return 'Server connection failed';
    }

    _isLoading = false;
    notifyListeners();
    return 'Invalid username or password';
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      print('[AuthProvider] Logout error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Refresh current user details (e.g. after password change) ──────────────
  Future<void> refreshUserCaches() async {
    await _apiService.loadUserCaches();
    notifyListeners();
  }
}
