// lib/services/deepseek_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  // DeepSeek offers free API tokens - sign up at https://platform.deepseek.com/
  static const String _apiKey = 'sk-4a60bb4335be457b87976f9ab40948e3'; // Get free token from DeepSeek platform
  static const String _baseUrl = 'https://api.deepseek.com/v1';

  // Free tier limits (approximate - check DeepSeek's current offering)
  static const int _maxFreeRequestsPerDay = 100; // Usually generous for free tier
  static const int _maxTokensPerRequest = 1000;
  
  static int _requestCount = 0;
  static DateTime? _lastResetDate;

  static Future<Map<String, dynamic>> analyzeIncidentReport(String description) async {
    // Check rate limiting for free tier
    if (_isOverFreeLimit()) {
      print('⚠️ Free tier limit reached, using fallback analysis');
      return _fallbackAnalysis(description);
    }

    try {
      _requestCount++;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat', // Use the chat model available in free tier
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt()
            },
            {
              'role': 'user',
              'content': 'Incident report to analyze: "$description"'
            }
          ],
          'temperature': 0.1, // Low temperature for consistent results
          'max_tokens': 400, // Keep it short to save tokens
          'stream': false,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        print('✅ DeepSeek API response received');
        print('📊 Token usage: ${data['usage']?['total_tokens']}');
        
        return _parseDeepSeekResponse(content, description);
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        print('⚠️ Rate limit exceeded, using fallback');
        return _fallbackAnalysis(description);
      } else {
        print('❌ DeepSeek API error: ${response.statusCode} - ${response.body}');
        return _fallbackAnalysis(description);
      }
    } catch (e) {
      print('❌ DeepSeek analysis error: $e');
      return _fallbackAnalysis(description);
    }
  }

  static String _buildSystemPrompt() {
    return '''
You are an incident report analyzer. Analyze reports for potential false/misleading content.

CRITICAL: Respond with ONLY valid JSON in this exact format:
{
  "suspicion_score": 0.0 to 1.0,
  "matched_patterns": ["pattern1", "pattern2"],
  "explanation": "Brief explanation",
  "requires_review": true/false
}

Guidelines:
- suspicion_score: 0.0=clearly legitimate, 1.0=highly suspicious
- requires_review: true if score >= 0.4
- Consider: vague descriptions, testing language, prank mentions, unrealistic scenarios
- Be fair - most reports are legitimate
- Keep explanation concise (1-2 sentences)
''';
  }

  static Map<String, dynamic> _parseDeepSeekResponse(String content, String originalDescription) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final analysisResult = jsonDecode(jsonString) as Map<String, dynamic>;
        
        return {
          'suspicion_score': (analysisResult['suspicion_score'] as num).toDouble().clamp(0.0, 1.0),
          'matched_patterns': List<String>.from(analysisResult['matched_patterns'] ?? []),
          'explanation': analysisResult['explanation'] as String? ?? 'AI analysis completed',
          'requires_review': analysisResult['requires_review'] as bool? ?? false,
          'analysis_method': 'deepseek_ai',
        };
      }
    } catch (e) {
      print('❌ Failed to parse DeepSeek JSON response: $e');
    }
    
    // Fallback if JSON parsing fails
    return _analyzeFromTextResponse(content, originalDescription);
  }

  static Map<String, dynamic> _analyzeFromTextResponse(String aiResponse, String description) {
    // Fallback analysis based on text response
    final lowerResponse = aiResponse.toLowerCase();
    double score = 0.5; // Default neutral
    
    if (lowerResponse.contains('suspicious') || lowerResponse.contains('false') || lowerResponse.contains('fake')) {
      score = 0.7;
    } else if (lowerResponse.contains('legitimate') || lowerResponse.contains('genuine')) {
      score = 0.2;
    } else if (lowerResponse.contains('review') || lowerResponse.contains('check')) {
      score = 0.6;
    }
    
    return {
      'suspicion_score': score,
      'matched_patterns': _extractPatternsFromText(aiResponse),
      'explanation': 'AI analysis: ${aiResponse.length > 100 ? aiResponse.substring(0, 100) + '...' : aiResponse}',
      'requires_review': score >= 0.4,
      'analysis_method': 'deepseek_text_fallback',
    };
  }

  static List<String> _extractPatternsFromText(String text) {
    final patterns = <String>[];
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('vague') || lowerText.contains('unclear')) {
      patterns.add('Vague description');
    }
    if (lowerText.contains('test') || lowerText.contains('practice')) {
      patterns.add('Testing language');
    }
    if (lowerText.contains('prank') || lowerText.contains('joke')) {
      patterns.add('Prank content');
    }
    if (lowerText.contains('brief') || lowerText.contains('short')) {
      patterns.add('Lacks detail');
    }
    
    return patterns;
  }

  static Map<String, dynamic> _fallbackAnalysis(String description) {
    // Enhanced rule-based fallback
    final lowerDesc = description.toLowerCase();
    double score = 0.0;
    final patterns = <String>[];
    final explanations = <String>[];

    // High-risk patterns
    if (lowerDesc.contains('fake') || lowerDesc.contains('false') || lowerDesc.contains('not real')) {
      score += 0.7;
      patterns.add('Explicit false claim');
      explanations.add('Report explicitly mentions being fake or false.');
    }
    
    if (lowerDesc.contains('prank') || lowerDesc.contains('joke') || lowerDesc.contains('just kidding')) {
      score += 0.8;
      patterns.add('Prank admission');
      explanations.add('User admits this is a prank or joke.');
    }
    
    // Medium-risk patterns
    if (lowerDesc.contains('test') || lowerDesc.contains('practice') || lowerDesc.contains('example')) {
      score += 0.4;
      patterns.add('Testing language');
      explanations.add('Contains testing or example scenario language.');
    }
    
    if (description.length < 20) {
      score += 0.3;
      patterns.add('Very brief');
      explanations.add('Description lacks sufficient detail.');
    }
    
    // Low-risk patterns
    if (lowerDesc.contains('maybe') || lowerDesc.contains('probably') || lowerDesc.contains('i think')) {
      score += 0.2;
      patterns.add('Uncertain language');
      explanations.add('Uses uncertain or speculative wording.');
    }
    
    // Legitimacy indicators (reduce score)
    if (_containsSpecificDetails(description)) {
      score -= 0.3;
      explanations.add('Contains specific, verifiable details.');
    }
    
    if (description.length > 50) {
      score -= 0.2;
      explanations.add('Provides detailed description.');
    }

    score = score.clamp(0.0, 1.0);
    
    return {
      'suspicion_score': score,
      'matched_patterns': patterns,
      'explanation': explanations.isNotEmpty 
          ? 'Rule-based analysis: ${explanations.join(" ")}'
          : 'No suspicious patterns detected. Report appears legitimate.',
      'requires_review': score >= 0.4,
      'analysis_method': 'rule_based_fallback',
    };
  }

  static bool _containsSpecificDetails(String text) {
    final detailPatterns = [
      RegExp(r'\d{1,2}:\d{2}'), // Time
      RegExp(r'\b(am|pm)\b', caseSensitive: false),
      RegExp(r'\b(street|avenue|road|barangay|building)\b', caseSensitive: false),
      RegExp(r'\d+'), // Numbers
    ];
    return detailPatterns.any((pattern) => pattern.hasMatch(text));
  }

  static bool _isOverFreeLimit() {
    final now = DateTime.now();
    
    // Reset counter if it's a new day
    if (_lastResetDate == null || _lastResetDate!.day != now.day) {
      _requestCount = 0;
      _lastResetDate = now;
    }
    
    return _requestCount >= _maxFreeRequestsPerDay;
  }

  // Method to get current usage stats
  static Map<String, dynamic> getUsageStats() {
    return {
      'requests_today': _requestCount,
      'max_requests': _maxFreeRequestsPerDay,
      'remaining_requests': _maxFreeRequestsPerDay - _requestCount,
      'last_reset': _lastResetDate,
    };
  }
}