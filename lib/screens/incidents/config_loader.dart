import 'dart:convert';
import 'package:flutter/services.dart';

class ConfigLoader {
  static Map<String, dynamic>? _config;
  
  static Future<Map<String, dynamic>> loadConfig() async {
    if (_config != null) return _config!;
    
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/config/incident_analysis_config.json'
      );
      
      _config = json.decode(jsonString);
      print('=== CONFIG LOADED SUCCESSFULLY ===');
      print('Total suspicious patterns: ${getAllSuspiciousPatterns().length}');
      return _config!;
    } catch (e) {
      print('Error loading config: $e');
      return _getDefaultConfig();
    }
  }
  
  static Map<String, dynamic> _getDefaultConfig() {
    return {
      "analysisRules": {
        "suspiciousPatterns": {
          "english": ["test", "fake", "joke", "prank"],
          "filipino": ["biro", "peke", "test"]
        }
      }
    };
  }
  
  static List<String> getAllSuspiciousPatterns() {
    try {
      final patterns = _config?['analysisRules']['suspiciousPatterns'] ?? _getDefaultConfig()['analysisRules']['suspiciousPatterns'];
      final List<String> allPatterns = [];
      allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
      allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
      return allPatterns;
    } catch (e) {
      print('Error getting suspicious patterns: $e');
      return ['test', 'fake', 'joke'];
    }
  }

  static List<String> getAllInappropriateLanguage() {
    try {
      final patterns = _config?['analysisRules']['inappropriateLanguage'] ?? _getDefaultConfig()['analysisRules']['inappropriateLanguage'];
      final List<String> allPatterns = [];
      allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
      allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
      return allPatterns;
    } catch (e) {
      print('Error getting inappropriate language: $e');
      return [];
    }
  }

  static List<String> getAllDisrespectfulContent() {
    try {
      final patterns = _config?['analysisRules']['disrespectfulContent'] ?? _getDefaultConfig()['analysisRules']['disrespectfulContent'];
      final List<String> allPatterns = [];
      allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
      allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
      return allPatterns;
    } catch (e) {
      print('Error getting disrespectful content: $e');
      return [];
    }
  }

  static List<String> getAllLustfulContent() {
    try {
      final patterns = _config?['analysisRules']['lustfulContent'] ?? _getDefaultConfig()['analysisRules']['lustfulContent'];
      final List<String> allPatterns = [];
      allPatterns.addAll((patterns['english'] as List<dynamic>).cast<String>());
      allPatterns.addAll((patterns['filipino'] as List<dynamic>).cast<String>());
      return allPatterns;
    } catch (e) {
      print('Error getting lustful content: $e');
      return [];
    }
  }

  static List<String> getAllImplausibleScenarios() {
    try {
      return (_config?['analysisRules']['implausibleScenarios'] as List<dynamic>? ?? []).cast<String>();
    } catch (e) {
      print('Error getting implausible scenarios: $e');
      return [];
    }
  }

  static List<String> getAllVagueDescriptions() {
    try {
      return (_config?['analysisRules']['vagueDescriptions'] as List<dynamic>? ?? []).cast<String>();
    } catch (e) {
      print('Error getting vague descriptions: $e');
      return [];
    }
  }
}