import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// AI 服务抽象接口
abstract class AIService {
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 2048,
  });
}

/// 可配置的 AI 服务实现（支持 OpenAI 兼容格式）
class ConfigurableAIService implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final Dio _dio;

  ConfigurableAIService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ));

  @override
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      debugPrint('AI Request: baseUrl=$baseUrl, model=$model');

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
      );

      final data = response.data;
      final content = data['choices'][0]['message']['content'] as String;

      debugPrint('AI Response: ${content.substring(0, content.length.clamp(0, 100))}...');

      return content;
    } on DioException catch (e) {
      debugPrint('AI Error: ${e.message}');
      debugPrint('AI Error Response: ${e.response?.data}');

      throw AIServiceException(
        message: 'AI 请求失败: ${_getErrorMessage(e)}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is Map && error.containsKey('message')) {
          return error['message'] as String;
        }
        return error.toString();
      }
    }
    return e.message ?? '未知错误';
  }
}

/// MiMo AI 服务（向后兼容）
class MiMoAIService extends ConfigurableAIService {
  MiMoAIService({
    required String apiKey,
  }) : super(
          apiKey: apiKey,
          baseUrl: 'https://api.xiaomimimo.com/v1',
          model: 'mimo-v2.5-pro',
        );
}

/// AI 服务异常
class AIServiceException implements Exception {
  final String message;
  final int? statusCode;

  const AIServiceException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'AIServiceException: $message';
}
