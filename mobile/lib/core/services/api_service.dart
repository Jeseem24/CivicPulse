import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiService {
  static const Duration _requestTimeout = Duration(seconds: 60);
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
      final response = await http
          .get(url, headers: headers)
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot reach the CivicPulse server. Check that the laptop server is running and both devices are on the same network.',
      );
    } on TimeoutException {
      throw Exception('The CivicPulse server took too long to respond.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot reach the CivicPulse server. Check that the laptop server is running and both devices are on the same network.',
      );
    } on TimeoutException {
      throw Exception('The CivicPulse server took too long to respond.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
    final headers = await _getHeaders(requireAuth: requireAuth);

    try {
      final response = await http
          .patch(url, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot reach the CivicPulse server. Check that the laptop server is running and both devices are on the same network.',
      );
    } on TimeoutException {
      throw Exception('The CivicPulse server took too long to respond.');
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
      final streamedResponse = await request.send().timeout(_requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw Exception(
        'Cannot reach the CivicPulse server. Check that the laptop server is running and both devices are on the same network.',
      );
    } on TimeoutException {
      throw Exception('The CivicPulse server took too long to respond.');
    } catch (e) {
      rethrow;
    }
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    try {
      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['error'] ?? errorData['detail'] ?? errorData['message'];
      if (errorMessage != null) {
        throw Exception(errorMessage.toString());
      }
    } on FormatException {
      // Fall through to the generic status message below.
    }

    throw Exception('Server error: ${response.statusCode}');
  }
}
