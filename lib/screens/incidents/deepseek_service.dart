// lib/services/deepseek_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  // Get your FREE API key from https://platform.deepseek.com/
  static const String _apiKey = 'sk-4a60bb4335be457b87976f9ab40948e3'; 
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  // Free tier is generous - usually 100+ requests per day
  static const int _maxFreeRequestsPerDay = 100;
  static const int _maxTokensPerRequest = 1000;
  
  static int _requestCount = 0;
  static DateTime? _lastResetDate;
  static bool _apiEnabled = true;

  static Future<Map<String, dynamic>> analyzeIncidentReport(String description) async {
    // Quick validation
    if (description.isEmpty) {
      return _fallbackAnalysis(description);
    }

    // Check if API is disabled (due to previous errors)
    if (!_apiEnabled) {
      print('⚠️ API temporarily disabled, using fallback');
      return _fallbackAnalysis(description);
    }

    // Check rate limiting for free tier
    if (_isOverFreeLimit()) {
      print('⚠️ Free tier limit reached ($_requestCount/$_maxFreeRequestsPerDay), using fallback');
      return _fallbackAnalysis(description);
    }

    // Skip API for very short descriptions to save tokens
    if (description.length < 15) {
      print('📝 Short description detected, using rule-based analysis');
      return _fallbackAnalysis(description);
    }

    try {
      _requestCount++;
      
      print('🚀 Sending request to DeepSeek API...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt()
            },
            {
              'role': 'user', 
              'content': 'Analyze this incident report: "$description"'
            }
          ],
          'temperature': 0.1,
          'max_tokens': 500,
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📡 DeepSeek API Response Status: ${response.statusCode}');

      // Handle different response codes
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'];
          final usage = data['usage']?['total_tokens'] ?? 0;
          
          print('✅ DeepSeek analysis successful (${usage}tokens)');
          
          return _parseDeepSeekResponse(content, description);
          
        case 401:
          print('❌ DeepSeek API: Invalid API Key');
          _apiEnabled = false; // Disable API to prevent repeated failures
          return _fallbackAnalysis(description, error: 'Invalid API configuration');
          
        case 402:
          print('❌ DeepSeek API: Insufficient Balance');
          _apiEnabled = false;
          return _fallbackAnalysis(description, error: 'API credits exhausted');
          
        case 429:
          print('⏰ DeepSeek API: Rate Limit Exceeded');
          return _fallbackAnalysis(description, error: 'Rate limit exceeded');
          
        case 500:
        case 502:
        case 503:
          print('🔧 DeepSeek API: Service Unavailable');
          return _fallbackAnalysis(description, error: 'Service temporarily unavailable');
          
        default:
          print('❌ DeepSeek API: Unexpected Error ${response.statusCode}');
          return _fallbackAnalysis(description, error: 'API error ${response.statusCode}');
      }
    } catch (e) {
      print('🌐 DeepSeek API Network Error: $e');
      return _fallbackAnalysis(description, error: 'Network connection failed');
    }
  }

  static String _buildSystemPrompt() {
    return '''
You are an incident report analyzer for a community safety app. Analyze reports for authenticity.

CRITICAL: Respond with ONLY valid JSON in this exact format:
{
  "suspicion_score": 0.0,
  "matched_patterns": [],
  "explanation": "Brief analysis explanation",
  "requires_review": false
}

Analysis Guidelines:
- suspicion_score: 0.0-1.0 (0=clearly legitimate, 1.0=clearly fake)
- requires_review: true if score >= 0.4
- Be conservative - most reports are legitimate
- Flag: testing language, prank admissions, extremely vague descriptions
- Consider legitimate: specific details, location references, clear descriptions
- Keep explanation concise and professional

Return ONLY the JSON object, no other text.
''';
  }

  static Map<String, dynamic> _parseDeepSeekResponse(String content, String originalDescription) {
    try {
      print('🔍 Parsing AI response: ${content.length} characters');
      
      // Clean the content - remove any markdown code blocks
      String cleanContent = content.trim();
      if (cleanContent.startsWith('```json')) {
        cleanContent = cleanContent.substring(7);
      }
      if (cleanContent.endsWith('```')) {
        cleanContent = cleanContent.substring(0, cleanContent.length - 3);
      }
      cleanContent = cleanContent.trim();

      // Parse JSON
      final analysisResult = jsonDecode(cleanContent) as Map<String, dynamic>;
      
      // Validate required fields
      if (!analysisResult.containsKey('suspicion_score') || 
          !analysisResult.containsKey('requires_review')) {
        throw FormatException('Missing required fields in AI response');
      }

      // Convert and validate scores
      final rawScore = analysisResult['suspicion_score'];
      double score;
      if (rawScore is int) {
        score = rawScore.toDouble();
      } else if (rawScore is double) {
        score = rawScore;
      } else if (rawScore is String) {
        score = double.tryParse(rawScore) ?? 0.5;
      } else {
        score = 0.5;
      }
      
      score = score.clamp(0.0, 1.0);

      return {
        'suspicion_score': score,
        'matched_patterns': List<String>.from(analysisResult['matched_patterns'] ?? []),
        'explanation': analysisResult['explanation'] as String? ?? 'AI analysis completed successfully',
        'requires_review': analysisResult['requires_review'] as bool? ?? (score >= 0.4),
        'analysis_method': 'deepseek_ai',
        'ai_service_available': true,
      };
    } catch (e) {
      print('❌ Failed to parse DeepSeek JSON response: $e');
      print('📄 Raw response was: $content');
      
      return _analyzeFromTextResponse(content, originalDescription);
    }
  }

  static Map<String, dynamic> _analyzeFromTextResponse(String aiResponse, String description) {
    // Fallback analysis when JSON parsing fails but we have text response
    final lowerResponse = aiResponse.toLowerCase();
    double score = 0.3; // Default slightly positive
    
    // Analyze the text response for keywords
    if (lowerResponse.contains('suspicious') || 
        lowerResponse.contains('fake') || 
        lowerResponse.contains('false') ||
        lowerResponse.contains('prank')) {
      score = 0.7;
    } else if (lowerResponse.contains('legitimate') || 
               lowerResponse.contains('genuine') ||
               lowerResponse.contains('authentic')) {
      score = 0.1;
    } else if (lowerResponse.contains('review') || 
               lowerResponse.contains('verify') ||
               lowerResponse.contains('check')) {
      score = 0.6;
    }
    
    // Extract patterns from text
    final patterns = <String>[];
    if (lowerResponse.contains('vague') || lowerResponse.contains('unclear')) {
      patterns.add('Vague description');
    }
    if (lowerResponse.contains('test') || lowerResponse.contains('practice')) {
      patterns.add('Testing language');
    }
    
    return {
      'suspicion_score': score,
      'matched_patterns': patterns,
      'explanation': 'AI analysis completed (text fallback): ${aiResponse.length > 80 ? aiResponse.substring(0, 80) + '...' : aiResponse}',
      'requires_review': score >= 0.4,
      'analysis_method': 'deepseek_text_fallback',
      'ai_service_available': true,
    };
  }

  static Map<String, dynamic> _fallbackAnalysis(String description, {String error = ''}) {
    // Enhanced rule-based analysis
    final lowerDesc = description.toLowerCase().trim();
    double score = 0.0;
    final patterns = <String>[];
    final explanations = <String>[];

    if (error.isNotEmpty) {
      explanations.add('AI service unavailable: $error');
    }

    // High-risk patterns (definite flags)
    if (lowerDesc.contains('this is fake') || 
        lowerDesc.contains('not real') ||
        lowerDesc.contains('just testing') ||
        lowerDesc.contains('practice report')) {
      score = 0.9;
      patterns.add('Explicit false claim');
      explanations.add('User explicitly states this is not a real incident.');
    }
    
    if (lowerDesc.contains('prank') || 
        lowerDesc.contains('joke') || 
        lowerDesc.contains('just kidding') ||
        lowerDesc.contains('fooling')) {
      score = 0.8;
      patterns.add('Prank admission');
      explanations.add('Contains prank or joke language.');
    }
    
    // Medium-risk patterns
    if (lowerDesc.contains('test') || 
        lowerDesc.contains('testing') ||
        lowerDesc.contains('practice') ||
        lowerDesc.contains('example')) {
      score = max(score, 0.5);
      patterns.add('Testing language');
      explanations.add('Uses testing or example scenario wording.');
    }
    
    if (description.length < 15) {
      score = max(score, 0.4);
      patterns.add('Very brief description');
      explanations.add('Description lacks sufficient detail for verification.');
    }
    
    // Low-risk patterns
    if (lowerDesc.contains('maybe') || 
        lowerDesc.contains('probably') || 
        lowerDesc.contains('i think') ||
        lowerDesc.contains('not sure')) {
      score = max(score, 0.3);
      patterns.add('Uncertain language');
      explanations.add('Uses uncertain or speculative wording.');
    }
    
    // Legitimacy indicators (reduce suspicion)
    if (_containsSpecificDetails(description)) {
      score = max(0.0, score - 0.3);
      explanations.add('Contains specific, verifiable details.');
    }
    
    if (description.length > 100) {
      score = max(0.0, score - 0.2);
      explanations.add('Provides detailed description.');
    }
    
    if (_containsLocationDetails(description)) {
      score = max(0.0, score - 0.2);
      explanations.add('Includes location-specific information.');
    }

    // Ensure score is within bounds
    score = score.clamp(0.0, 1.0);
    
    String explanation;
    if (explanations.isNotEmpty) {
      explanation = 'Rule-based analysis: ${explanations.join(' ')}';
    } else if (score < 0.3) {
      explanation = 'No suspicious patterns detected. Report appears legitimate.';
    } else {
      explanation = 'Some patterns require additional verification.';
    }

    return {
      'suspicion_score': score,
      'matched_patterns': patterns,
      'explanation': explanation,
      'requires_review': score >= 0.4,
      'analysis_method': 'rule_based_fallback',
      'ai_service_available': false,
      'fallback_reason': error.isNotEmpty ? error : 'AI service not used',
    };
  }

  static bool _containsSpecificDetails(String text) {
    final detailPatterns = [
      RegExp(r'\d{1,2}:\d{2}'), // Time
      RegExp(r'\b(am|pm)\b', caseSensitive: false),
      RegExp(r'\b(street|avenue|road|barangay|building|house)\b', caseSensitive: false),
      RegExp(r'\d+\s*(meters|feet|blocks|km|minutes)'), // Distances
      RegExp(r'#[a-zA-Z0-9]+'), // Hashtags or codes
    ];
    return detailPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool _containsLocationDetails(String text) {
    final locationPatterns = [
      RegExp(r'\b(near|beside|opposite|behind|in front of)\b', caseSensitive: false),
      RegExp(r'\b(red|blue|green|white|black)\b', caseSensitive: false), // Color descriptors
      RegExp(r'\b(small|big|large|tall|short)\b', caseSensitive: false), // Size descriptors
    ];
    return locationPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool _isOverFreeLimit() {
    final now = DateTime.now();
    
    // Reset counter if it's a new day
    if (_lastResetDate == null || _lastResetDate!.day != now.day) {
      _requestCount = 0;
      _lastResetDate = now;
      print('🔄 Daily request counter reset');
    }
    
    final isOverLimit = _requestCount >= _maxFreeRequestsPerDay;
    if (isOverLimit) {
      print('📊 Daily limit: $_requestCount/$_maxFreeRequestsPerDay requests used');
    }
    
    return isOverLimit;
  }

  // Method to get current usage stats
  static Map<String, dynamic> getUsageStats() {
    final remaining = _maxFreeRequestsPerDay - _requestCount;
    return {
      'requests_today': _requestCount,
      'max_requests': _maxFreeRequestsPerDay,
      'remaining_requests': remaining,
      'last_reset': _lastResetDate,
      'api_enabled': _apiEnabled,
      'percent_used': (_requestCount / _maxFreeRequestsPerDay * 100).round(),
    };
  }

  // Method to manually reset API (for testing)
  static void resetApi() {
    _requestCount = 0;
    _lastResetDate = DateTime.now();
    _apiEnabled = true;
    print('🔄 DeepSeek API manually reset');
  }

  // Method to enable/disable API
  static void setApiEnabled(bool enabled) {
    _apiEnabled = enabled;
    print(_apiEnabled ? '✅ DeepSeek API enabled' : '⏸️ DeepSeek API disabled');
  }
}

// Helper function since we can't use math library directly
double max(double a, double b) => a > b ? a : b;