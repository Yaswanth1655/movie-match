import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import '../network/failure.dart';
import '../network/network_api_service.dart';

class ApiCallType {
  static final _network = Network();
  static String baseUrl = "";

  static Future<Either<Failure, dynamic>> apiTypeGet({
    required String url,
    String? token,
  }) async {
    try {
      String fullUrl = baseUrl + url;
      final Either<Failure, Response> responseEither =
          await _network.apiTypeGet(url: fullUrl, token: token);

      return responseEither.fold(
        (failure) => Left(failure),
        (response) => Right(returnResponse(response)),
      );
    } on SocketException {
      return Left(Failure("No Internet Connection"));
    } catch (e) {
      return Left(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  static Future<Either<Failure, dynamic>> apiTypePost({
    required String url,
    String? token,
    required Map<String, dynamic> data,
  }) async {
    try {
      String fullUrl = baseUrl + url;
      final Either<Failure, Response> responseEither =
          await _network.apiTypePost(
        url: fullUrl,
        token: token!,
        body: jsonEncode(data),
      );

      return responseEither.fold(
        (failure) => Left(failure),
        (response) => Right(returnResponse(response)),
      );
    } on SocketException {
      return Left(Failure("No Internet Connection"));
    } catch (e) {
      return Left(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  static Future<Either<Failure, dynamic>> apiTypePut({
    required String url,
    String? token,
    required Map<String, dynamic> data,
  }) async {
    try {
      String fullUrl = baseUrl + url;
      final Either<Failure, Response> responseEither =
          await _network.apiTypePut(
        url: fullUrl,
        token: token!,
        body: jsonEncode(data),
      );

      return responseEither.fold(
        (failure) => Left(failure),
        (response) => Right(returnResponse(response)),
      );
    } on SocketException {
      return Left(Failure("No Internet Connection"));
    } catch (e) {
      return Left(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  static Future<Either<Failure, dynamic>> apiTypeDelete({
    required String url,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      String fullUrl = baseUrl + url;
      final Either<Failure, Response> responseEither =
          await _network.apiTypeDelete(
        url: fullUrl,
        token: token,
        body: jsonEncode(data),
      );

      return responseEither.fold(
        (failure) => Left(failure),
        (response) => Right(returnResponse(response)),
      );
    } on SocketException {
      return Left(Failure("No Internet Connection"));
    } catch (e) {
      return Left(Failure("Unexpected error: ${e.toString()}"));
    }
  }

  static Future<Either<Failure, dynamic>> multipartFileUpload({
    required String url,
    required String token,
    required XFile file,
  }) async {
    try {
      String fullUrl = baseUrl + url;
      final Either<Failure, Response> responseEither =
          await _network.apiTypeMultiPart(
        url: fullUrl,
        token: token,
        file: file,
      );

      return responseEither.fold(
        (failure) => Left(failure),
        (response) => Right(returnResponse(response)),
      );
    } on SocketException {
      return Left(Failure("No Internet Connection"));
    } catch (e) {
      return Left(Failure("Unexpected error: ${e.toString()}"));
    }
  }
}

dynamic returnResponse(Response response) {
  switch (response.statusCode) {
    case 200:
      return jsonDecode(response.data);
    case 201:
      return jsonDecode(response.data);
    case 400:
      throw Failure("Something went wrong");
    case 500:
      throw Failure("Server request failed");
    case 404:
      throw Failure("Unauthorized request");
    default:
      throw Failure(
          "Error occurred while communicating with server: ${response.statusCode}");
  }
}
