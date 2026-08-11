class ApiConfig {
  // GLOBAL MOCK MODE SWITCH
  // Set this to true to run offline with mock data.
  // Set this to false to connect to the live FastAPI backend.
  static bool useMockMode = true;

  // PROVISIONAL BASE URL — TO BE CONFIRMED BY BACKEND TEAM
  // 10.0.2.2 is the special IP to access localhost from the Android emulator.
  static String baseUrl = 'http://10.0.2.2:8000';

  // PROVISIONAL ENDPOINTS — TO BE CONFIRMED BY BACKEND TEAM
  static String loginEndpoint = '/api/v1/auth/login';
  static String registerEndpoint = '/api/v1/auth/register';
  static String complaintsEndpoint = '/api/v1/complaints';
  static String mapComplaintsEndpoint = '/api/v1/complaints/map';
  
  static String getVerifyEndpoint(String id) => '/api/v1/complaints/$id/verify';
  static String getComplaintDetailEndpoint(String id) => '/api/v1/complaints/$id';

  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
