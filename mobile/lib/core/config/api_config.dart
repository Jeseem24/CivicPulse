class ApiConfig {
  // GLOBAL MOCK MODE SWITCH
  // Set to false to connect to the live Node.js Express AI backend.
  static bool useMockMode = false;

  // Override for a physical phone with:
  // flutter run --dart-define=API_BASE_URL=http://YOUR_LAPTOP_IP:3000
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static String get baseUrl => _configuredBaseUrl.endsWith('/')
      ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
      : _configuredBaseUrl;

  // DEV 2 EXPRESS BACKEND ENDPOINTS
  static String loginEndpoint = '/api/v1/auth/login';
  static String registerEndpoint = '/api/v1/auth/register';
  static String complaintsEndpoint = '/complaints';
  static String departmentsEndpoint = '/departments';
  static String analyticsEndpoint = '/analytics';
  static String assistantEndpoint = '/assistant/ask';
  static String decisionFeedEndpoint = '/decision-log/feed';
  static String hotspotsEndpoint = '/analytics/hotspots';

  static String getVerifyEndpoint(String id) => '/complaints/$id/verify';
  static String getResolveEndpoint(String id) => '/complaints/$id/resolve';
  static String getComplaintDetailEndpoint(String id) => '/complaints/$id';
  static String getDecisionLogEndpoint(String id) =>
      '/complaints/$id/decision-log';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
