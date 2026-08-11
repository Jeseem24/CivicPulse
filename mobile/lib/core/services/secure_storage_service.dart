class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  String? _token;
  String? _email;

  Future<void> writeToken(String token) async {
    _token = token;
  }

  Future<String?> readToken() async {
    return _token;
  }

  Future<void> deleteToken() async {
    _token = null;
  }

  Future<void> writeEmail(String email) async {
    _email = email;
  }

  Future<String?> readEmail() async {
    return _email;
  }

  Future<void> deleteEmail() async {
    _email = null;
  }
}
