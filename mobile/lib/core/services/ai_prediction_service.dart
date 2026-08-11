import '../config/constants.dart';

class AiPredictionService {
  /// Predicts the department based on raw complaint text.
  /// Simulates a backend prediction delay of 1.2 seconds.
  static Future<Map<String, dynamic>> predictDepartment(String title, String description) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final fullText = '$title $description'.toLowerCase();

    // Default fallback
    String predictedId = 'URBAN_DEVELOPMENT';
    double confidence = 0.85;

    // Direct keyword matching aligned with Section 11 of the requirements
    if (fullText.contains('pothole') || 
        fullText.contains('road') || 
        fullText.contains('street') || 
        fullText.contains('footpath') ||
        fullText.contains('asphalt') ||
        fullText.contains('crack') ||
        fullText.contains('pavement')) {
      predictedId = 'ROADS_HIGHWAYS';
      confidence = 0.96;
    } else if (fullText.contains('water') || 
               fullText.contains('leak') || 
               fullText.contains('pipe') || 
               fullText.contains('supply') ||
               fullText.contains('drinking') ||
               fullText.contains('tap')) {
      predictedId = 'WATER_SUPPLY';
      confidence = 0.94;
    } else if (fullText.contains('garbage') || 
               fullText.contains('trash') || 
               fullText.contains('waste') || 
               fullText.contains('toilet') || 
               fullText.contains('sewage') ||
               fullText.contains('dump') ||
               fullText.contains('clean') ||
               fullText.contains('drain') ||
               fullText.contains('stink')) {
      predictedId = 'SANITATION_WASTE';
      confidence = 0.92;
    } else if (fullText.contains('light') || 
               fullText.contains('electricity') || 
               fullText.contains('power') || 
               fullText.contains('wire') || 
               fullText.contains('pole') ||
               fullText.contains('outage') ||
               fullText.contains('current') ||
               fullText.contains('transformer')) {
      predictedId = 'ELECTRICITY_POWER';
      confidence = 0.95;
    } else if (fullText.contains('mosquito') || 
               fullText.contains('malaria') || 
               fullText.contains('health') || 
               fullText.contains('hygiene') ||
               fullText.contains('fever') ||
               fullText.contains('medical')) {
      predictedId = 'PUBLIC_HEALTH';
      confidence = 0.89;
    } else if (fullText.contains('housing') || 
               fullText.contains('apartment') || 
               fullText.contains('building') ||
               fullText.contains('planning') ||
               fullText.contains('municipal')) {
      predictedId = 'HOUSING_URBAN_AFFAIRS';
      confidence = 0.88;
    } else if (fullText.contains('pollution') || 
               fullText.contains('smoke') || 
               fullText.contains('tree') || 
               fullText.contains('forest') || 
               fullText.contains('lake') ||
               fullText.contains('dumping') ||
               fullText.contains('greenery')) {
      predictedId = 'ENVIRONMENT_FORESTS';
      confidence = 0.93;
    }

    final dept = AppConstants.departments.firstWhere(
      (d) => d.id == predictedId,
      orElse: () => AppConstants.departments.first,
    );

    return {
      'departmentId': dept.id,
      'departmentName': dept.name,
      'confidence': confidence,
    };
  }
}
