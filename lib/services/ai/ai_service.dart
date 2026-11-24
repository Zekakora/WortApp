import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/i18n/app_localizations.dart';

/// AI 服务抽象接口
abstract class AIService {
  /// 发起一次对话请求
  ///
  /// [jsonMode] 为 true 时向服务端声明 `response_format: json_object`
  /// （OpenAI 兼容协议）。部分厂商不支持该字段，故默认关闭：
  /// 训练模块生成结构化数据时打开，失败回退由调用方重试时关闭。
  /// [maxTokens] 训练模块生成整套题目时需要显式放大（默认 2048 会被截断）。
  /// [timeout] 单次请求的接收超时（覆盖默认 120s）。
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool jsonMode = false,
    Duration? timeout,
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
    bool jsonMode = false,
    Duration? timeout,
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
          if (jsonMode) 'response_format': {'type': 'json_object'},
        },
        options: timeout == null
            ? null
            : Options(receiveTimeout: timeout),
      );

      final data = response.data;
      final content = data['choices'][0]['message']['content'] as String;

      debugPrint('AI Response: ${content.substring(0, content.length.clamp(0, 100))}...');

      return content;
    } on DioException catch (e) {
      debugPrint('AI Error: ${e.message}');
      debugPrint('AI Error Response: ${e.response?.data}');

      throw AIServiceException(
        message: AppLocale.trArgs('AI 请求失败: {0}', [_getErrorMessage(e)]),
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
    return e.message ?? AppLocale.tr('未知错误');
  }
}

/// MiMo AI 服务（向后兼容）
class MiMoAIService extends ConfigurableAIService {
  MiMoAIService({
    required super.apiKey,
  }) : super(
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
