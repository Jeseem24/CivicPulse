import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await _storage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    required String filePath,
    required String fileKey,
  }) async {
    final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
    final request = http.MultipartRequest('POST', url);

    final token = await _storage.readToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    if (filePath.isNotEmpty) {
      final file = await http.MultipartFile.fromPath(fileKey, filePath);
      request.files.add(file);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      rethrow;
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? errorData['message'] ?? 'An error occurred (${response.statusCode})';
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }
}
