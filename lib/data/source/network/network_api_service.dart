//network call

import 'package:basic_app/data/source/network/retry_dio_factory.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'base_api_service.dart';

class Network extends BaseApiService {
  /// All HTTP traffic flows through a single retry-enabled [Dio].
  /// Tests / WorkManager isolates may pass their own instance; otherwise we
  /// build one via [RetryDioFactory] so every request gets exponential-backoff
  /// retries and feeds the "reconnecting…" banner.
  Network({Dio? dio}) : _dio = dio ?? RetryDioFactory.create();

  final Dio _dio;

  //GET API
  @override
  Future apiTypeGet({required String url, String? token, Map<String, dynamic>? queryParameters}) async {
    Map<String, dynamic> header ={
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'x-api-key': token,
        };
    final response = await _dio.get(
      url,
      queryParameters: queryParameters,
      options: Options(
        headers: token == null ? null : header,
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return response;
  }

  /// Reqres expects `x-api-key` on POST; [apiTypePost] uses Bearer for other APIs.
  Future<Response<dynamic>> postJsonWithApiKey({
    required String url,
    required String body,
    required String apiKey,
  }) async {
    return _dio.post<dynamic>(
      url,
      data: body,
      options: Options(
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'x-api-key': apiKey,
        },
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  }

  //DELETE API
  @override
  Future apiTypeDelete(
      {required String url,
      required String token,
      required String body}) async {
    final response = await _dio.delete(
      url,
      data: body,
      options: Options(
          headers: {
            'Content-type': 'application/json',
            'Accept': 'application/json',
            "authorization": "Bearer $token",
          },
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90)),
    );
    return response;
  }

  //POST API
  @override
  Future apiTypePost(
      {required String url, String? token, required String body}) async {
    Map<String, dynamic> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      "authorization": "Bearer $token",
    };

    final response = await _dio.post(
      url,
      data: body,
      options: Options(
          headers: token == null ? null : header,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90)),
    );
    return response;
  }

  //PUT API
  @override
  Future apiTypePut(
      {required String url, String? token, required String body}) async {
    Map<String, dynamic> header = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      "authorization": "Bearer $token",
    };
    final response = await _dio.put(
      url,
      data: body,
      options: Options(
          headers: token == null ? null : header,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90)),
    );
    return response;
  }

  @override
  Future apiTypeMultiPart(
      {required String url, required String token, required XFile file}) async {
    FormData formData = FormData.fromMap({
      'file':
          await MultipartFile.fromFile(file.path, filename: "jpf/${file.name}"),
    });
    final response = await _dio.post(url,
        data: formData,
        options: Options(
            headers: {
              'Content-type': 'multipart/form-data',
              "authorization": "Bearer $token",
            },
            receiveTimeout: const Duration(seconds: 90),
            sendTimeout: const Duration(seconds: 90)));

    return response;
  }
}
