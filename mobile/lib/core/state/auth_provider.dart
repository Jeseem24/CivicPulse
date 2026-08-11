import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // List of mock users: 3 Admins and 1 User, as specified
  static final List<User> _mockUsers = [
    User(
      id: 'admin_roads',
      name: 'Rajesh Kumar (Roads Admin)',
      email: 'roads_admin@gov.in',
      phone: '+91 98765 00001',
      role: 'ADMIN',
      departmentId: 'ROADS_HIGHWAYS',
    ),
    User(
      id: 'admin_water',
      name: 'Anil Sharma (Water Admin)',
      email: 'water_admin@gov.in',
      phone: '+91 98765 00002',
      role: 'ADMIN',
      departmentId: 'WATER_SUPPLY',
    ),
    User(
      id: 'admin_sanitation',
      name: 'Suresh Patel (Sanitation Admin)',
      email: 'sanitation_admin@gov.in',
      phone: '+91 98765 00003',
      role: 'ADMIN',
      departmentId: 'SANITATION_WASTE',
    ),
    User(
      id: 'user_citizen',
      name: 'Janardhan Rao',
      email: 'citizen@example.com',
      phone: '+91 98765 43210',
      role: 'USER',
      departmentId: null,
    ),
  ];

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.readToken();
      if (token != null) {
        if (ApiConfig.useMockMode) {
          final email = await _storage.readEmail();
          _currentUser = _mockUsers.firstWhere(
            (u) => u.email.toLowerCase() == (email?.toLowerCase() ?? 'citizen@example.com'),
            orElse: () => _mockUsers.last, // Fallback to normal citizen
          );
        } else {
          // Live API check profile
          final response = await _apiService.get('/api/v1/auth/me');
          final data = jsonDecode(response.body);
          _currentUser = User.fromJson(data['user']);
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      await _storage.deleteToken();
      await _storage.deleteEmail();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        
        final user = _mockUsers.firstWhere(
          (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => throw Exception('User not found. Try roads_admin@gov.in or citizen@example.com'),
        );

        // Password verification (min 6 chars for new, strict for mocks)
        bool isPasswordCorrect = false;
        if (user.id.startsWith('admin_')) {
          isPasswordCorrect = (password == 'admin123');
        } else if (user.id == 'user_citizen') {
          isPasswordCorrect = (password == 'citizen123');
        } else {
          isPasswordCorrect = (password.length >= 6);
        }

        if (isPasswordCorrect) {
          await _storage.writeToken('mock_jwt_token');
          await _storage.writeEmail(user.email);
          _currentUser = user;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception('Incorrect password. Please try again.');
        }
      } else {
        // FastAPI authentication post request
        final response = await _apiService.post(
          ApiConfig.loginEndpoint,
          {'email': email, 'password': password},
          requireAuth: false,
        );
        
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.writeToken(token);
        
        _currentUser = User.fromJson(data['user']);
        await _storage.writeEmail(_currentUser!.email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (ApiConfig.useMockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (name.isNotEmpty && email.contains('@') && phone.isNotEmpty && password.length >= 6) {
          // Verify if user already exists
          final exists = _mockUsers.any((u) => u.email.toLowerCase() == email.toLowerCase());
          if (exists) {
            throw Exception('Email already registered.');
          }

          final newUser = User(
            id: 'mock_u_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            email: email,
            phone: phone,
            role: 'USER',
            departmentId: null,
          );
          _mockUsers.add(newUser);
          await _storage.writeToken('mock_jwt_token');
          await _storage.writeEmail(email);
          _currentUser = newUser;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception('Please fill all fields. Password must be at least 6 characters.');
        }
      } else {
        // FastAPI registration post request
        final response = await _apiService.post(
          ApiConfig.registerEndpoint,
          {
            'name': name,
            'email': email,
            'phone': phone,
            'password': password,
            'role': 'USER', // Citizen role defaults
          },
          requireAuth: false,
        );
        
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.writeToken(token);
        
        _currentUser = User.fromJson(data['user']);
        await _storage.writeEmail(_currentUser!.email);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.deleteEmail();
    _currentUser = null;
    notifyListeners();
  }
}
