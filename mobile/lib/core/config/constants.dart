import 'package:flutter/material.dart';

class AppColors {
  // Modern Dark Mode Palette (Slate theme)
  static const Color background = Color(0xFF0F172A);   // Slate 900
  static const Color surface = Color(0xFF1E293B);      // Slate 800
  static const Color border = Color(0xFF334155);       // Slate 700
  
  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B);     // Slate 500

  // Brand / Accents
  static const Color primary = Color(0xFF06B6D4);       // Cyan / Teal
  static const Color primaryLight = Color(0xFF22D3EE);
  static const Color accent = Color(0xFF8B5CF6);        // Purple / Violet

  // Severity Colors
  static const Color severityHigh = Color(0xFFEF4444);    // Vibrant Red
  static const Color severityMedium = Color(0xFFF59E0B);  // Amber
  static const Color severityLow = Color(0xFF10B981);     // Emerald Green
  
  // Status Colors
  static const Color statusSubmitted = Color(0xFF3B82F6);   // Blue
  static const Color statusInProgress = Color(0xFFF59E0B);  // Amber
  static const Color statusResolved = Color(0xFF10B981);    // Emerald Green
  static const Color statusReopened = Color(0xFFEF4444);    // Red
  static const Color statusVerified = Color(0xFF6366F1);    // Indigo
}

class DepartmentInfo {
  final String id;
  final String name;
  final String description;
  final List<String> keywords;
  final String backendCategory;     // Maps to Developer 2's backend categories
  final String backendDepartment;   // Maps to Developer 2's backend departments

  const DepartmentInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.keywords,
    required this.backendCategory,
    required this.backendDepartment,
  });
}

class AppConstants {
  static const double borderRadius = 16.0;
  static const double padding = 16.0;

  static const List<DepartmentInfo> departments = [
    DepartmentInfo(
      id: 'ROADS_HIGHWAYS',
      name: 'Roads & Highways',
      description: 'Road construction, potholes, broken pavements, and highway maintenance.',
      keywords: ['pothole', 'potholes', 'road', 'road damage', 'broken road', 'road crack', 'footpath', 'sidewalk', 'divider', 'street', 'asphalt', 'tar'],
      backendCategory: 'Roads',
      backendDepartment: 'Roads Dept',
    ),
    DepartmentInfo(
      id: 'WATER_SUPPLY',
      name: 'Water Supply & Water Resources',
      description: 'Water leakages, pipeline bursts, supply shortages, and water quality issues.',
      keywords: ['water', 'leak', 'leakage', 'pipe', 'pipeline', 'burst', 'flood', 'flooding', 'supply', 'tap', 'drinking water', 'pressure'],
      backendCategory: 'Water',
      backendDepartment: 'Water Dept',
    ),
    DepartmentInfo(
      id: 'SANITATION_WASTE',
      name: 'Sanitation & Waste Management',
      description: 'Garbage cleaning, public waste bin overflows, and drainage blocks.',
      keywords: ['garbage', 'trash', 'waste', 'dump', 'bin', 'smell', 'stink', 'litter', 'cleaning', 'sewage', 'overflow', 'toilet', 'drain', 'drainage'],
      backendCategory: 'Sanitation',
      backendDepartment: 'Sanitation Dept',
    ),
    DepartmentInfo(
      id: 'ELECTRICITY_POWER',
      name: 'Electricity & Power',
      description: 'Streetlight outages, power failure, exposed live wires, and damaged poles.',
      keywords: ['electricity', 'power', 'wire', 'cable', 'streetlight', 'light', 'outage', 'transformer', 'spark', 'current', 'pole'],
      backendCategory: 'Electricity',
      backendDepartment: 'Electricity Dept',
    ),
    DepartmentInfo(
      id: 'PUBLIC_HEALTH',
      name: 'Public Health',
      description: 'Hygiene monitoring, vector-borne disease control, and public health hazards.',
      keywords: ['mosquito', 'vector', 'dengue', 'malaria', 'health', 'hygiene', 'hazard', 'safety', 'hospital', 'medical'],
      backendCategory: 'Public Infrastructure',
      backendDepartment: 'Public Infrastructure Dept',
    ),
    DepartmentInfo(
      id: 'URBAN_DEVELOPMENT',
      name: 'Urban Development & Municipal Services',
      description: 'Municipal buildings, parks upkeep, urban facilities, and local services.',
      keywords: ['park', 'bench', 'playground', 'public space', 'municipal', 'civic infrastructure', 'building'],
      backendCategory: 'Public Infrastructure',
      backendDepartment: 'Public Infrastructure Dept',
    ),
    DepartmentInfo(
      id: 'HOUSING_URBAN_AFFAIRS',
      name: 'Housing & Urban Affairs',
      description: 'Public housing, urban planning approvals, and related civic amenities.',
      keywords: ['housing', 'apartment', 'encroachment', 'urban affairs', 'amenities'],
      backendCategory: 'Public Infrastructure',
      backendDepartment: 'Public Infrastructure Dept',
    ),
    DepartmentInfo(
      id: 'ENVIRONMENT_FORESTS',
      name: 'Environment & Forests',
      description: 'Air pollution, noise control, illegal tree cutting, and lake preservation.',
      keywords: ['pollution', 'smoke', 'air quality', 'noise', 'tree', 'forest', 'lake', 'greenery', 'cutting'],
      backendCategory: 'Public Infrastructure',
      backendDepartment: 'Public Infrastructure Dept',
    ),
  ];
}
