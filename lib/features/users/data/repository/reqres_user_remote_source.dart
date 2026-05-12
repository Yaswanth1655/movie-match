import 'dart:convert';

import 'package:basic_app/core/config/env/app_env.dart';
import 'package:basic_app/data/source/network/network_api_service.dart' show Network;
import 'package:basic_app/features/users/data/models/reqres_api_models.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ReqresUserRemoteSource {
  ReqresUserRemoteSource(this.network);

  final Network network;

  Future<ReqresUsersPageResponse> fetchUsers({required int page}) async {
    final response = await network.apiTypeGet(
      url: '${AppEnv.reqresBaseUrl}/users',
      queryParameters: {
        'page': page,
        'per_page': 8,
      },
      token: AppEnv.reqresApiKey,
    );
    debugPrint('fetchUsers response: ${response.statusCode}');
    final raw = response.data;
    debugPrint('fetchUsers response: $raw');
    if (raw is! Map) {
      throw FormatException('Reqres users: expected JSON object, got ${raw.runtimeType}');
    }
    return ReqresUsersPageResponse.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<ReqresCreateUserResponse> createUser({
    required String name,
    required String job,
  }) async {
    final response = await network.postJsonWithApiKey(
      url: '${AppEnv.reqresBaseUrl}/users',
      body: jsonEncode({'name': name, 'job': job}),
      apiKey: AppEnv.reqresApiKey,
    );
    debugPrint('createUser response: ${response.statusCode}');
    final raw = response.data;
    if (raw is! Map) {
      throw FormatException('Reqres create user: expected JSON object, got ${raw.runtimeType}');
    }
    return ReqresCreateUserResponse.fromJson(Map<String, dynamic>.from(raw));
  }
}
