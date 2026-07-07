import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String keyToken = 'jwt_auth_token';
  
  // Default URL of the FastAPI server
  String _baseUrl = 'http://127.0.0.1:18000';
  
  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  
  factory ApiClient() => _instance;
  
  ApiClient._internal() {
    _loadBaseUrl();
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
    _saveBaseUrl(url);
  }

  Future<void> _loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url') ?? 'http://127.0.0.1:18000';
  }

  Future<void> _saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', url);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyToken);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyToken, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyToken);
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    return http.get(url, headers: headers).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    return http.post(
      url, 
      headers: headers, 
      body: jsonEncode(body)
    ).timeout(const Duration(seconds: 45)); // Longer timeout for AI generations
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    return http.put(
      url, 
      headers: headers, 
      body: jsonEncode(body)
    ).timeout(const Duration(seconds: 15));
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _headers();
    return http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
  }
}
