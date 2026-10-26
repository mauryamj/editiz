import 'dart:math';
import 'package:dio/dio.dart';
import 'package:editiz/models/app_exception.dart';

// Class: remote data source fetching tips from JSONPlaceholder via Dio.
class TipsRemoteSource {
  // Field: Dio HTTP client instance.
  final Dio _dio;

  // Constructor: initializes Dio with timeouts and options.
  TipsRemoteSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://jsonplaceholder.typicode.com',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
              ),
            );

  // Method: fetches a random post formatted as an editing tip.
  Future<Map<String, String>> fetchTip() async {
    final randomId = Random().nextInt(100) + 1;
    try {
      final response = await _dio.get('/posts/$randomId');
      final data = response.data as Map<String, dynamic>;
      final title = (data['title'] as String? ?? 'Editing Tip').trim();
      final body = (data['body'] as String? ?? '').replaceAll('\n', ' ').trim();
      return {
        'title': title,
        'body': body,
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw const AppException('No internet connection.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const AppException('Connection timed out.');
      } else {
        throw const AppException('Unable to load editing tip right now.');
      }
    } catch (_) {
      throw const AppException('Something went wrong while loading tips.');
    }
  }
}
