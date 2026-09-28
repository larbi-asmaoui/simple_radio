import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared HTTP client. Radio Browser asks clients to send a descriptive
/// User-Agent (browsers forbid setting it, hence the web check).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 25),
      headers: {if (!kIsWeb) 'User-Agent': 'SimpleRadio/1.0'},
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
