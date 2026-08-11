class ApiConfig {
  // GLOBAL MOCK MODE SWITCH
  // Set to false to connect to the live Node.js Express AI backend.
  static bool useMockMode = false;

  // EXPRESS AI BACKEND BASE URL
  // 10.0.2.2 accesses localhost from Android Emulator; localhost for Web/Desktop/iOS
  static String baseUrl = 'http://10.0.2.2:3000';

  // DEV 2 EXPRESS BACKEND ENDPOINTS
  static String complaintsEndpoint = '/complaints';
  static String departmentsEndpoint = '/departments';
  static String analyticsEndpoint = '/analytics';
  static String assistantEndpoint = '/assistant/ask';
  static String decisionFeedEndpoint = '/decision-log/feed';
  static String hotspotsEndpoint = '/analytics/hotspots';
  
  static String getVerifyEndpoint(String id) => '/complaints/$id/verify';
  static String getResolveEndpoint(String id) => '/complaints/$id/resolve';
  static String getComplaintDetailEndpoint(String id) => '/complaints/$id';
  static String getDecisionLogEndpoint(String id) => '/complaints/$id/decision-log';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
