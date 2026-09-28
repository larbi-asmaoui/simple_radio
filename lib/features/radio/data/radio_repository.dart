import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../models/radio_station.dart';

abstract interface class RadioRepository {
  /// Most popular stations, optionally narrowed to a tag and/or country.
  Future<List<RadioStation>> stations({String? tag, String countryCode = ''});

  Future<List<RadioStation>> search(String query, {String countryCode = ''});

  /// Tells Radio Browser a station was played (feeds its popularity ranking,
  /// as their API guidelines ask). Fire-and-forget.
  Future<void> reportClick(String stationId);
}

final radioRepositoryProvider = Provider<RadioRepository>(
  (ref) => RadioBrowserRepository(ref.watch(dioProvider)),
);

/// https://api.radio-browser.info — free, no key, community run.
///
/// There is no single host: we fetch the mirror list once, shuffle it to
/// spread load, and fall through to the next mirror on failure.
class RadioBrowserRepository implements RadioRepository {
  RadioBrowserRepository(this._dio);

  final Dio _dio;
  List<String>? _mirrors;

  static const _fallbackMirrors = [
    'de1.api.radio-browser.info',
    'de2.api.radio-browser.info',
    'fi1.api.radio-browser.info',
  ];

  static const _pageSize = 60;

  @override
  Future<List<RadioStation>> stations({String? tag, String countryCode = ''}) =>
      _searchStations({
        'tag': ?tag,
        if (countryCode.isNotEmpty) 'countrycode': countryCode,
      });

  @override
  Future<List<RadioStation>> search(String query, {String countryCode = ''}) =>
      _searchStations({
        'name': query,
        if (countryCode.isNotEmpty) 'countrycode': countryCode,
      });

  @override
  Future<void> reportClick(String stationId) async {
    try {
      await _get('/json/url/$stationId');
    } catch (_) {
      // Analytics only; never let this surface to the user.
    }
  }

  Future<List<RadioStation>> _searchStations(
    Map<String, Object> filters,
  ) async {
    final data = await _get('/json/stations/search', {
      ...filters,
      'order': 'clickcount',
      'reverse': 'true',
      'hidebroken': 'true',
      // Over-fetch: we drop duplicates and unplayable entries below.
      'limit': '${_pageSize + 20}',
    });

    final seen = <String>{};
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(RadioStation.fromRadioBrowser)
        .where((s) => s.name.isNotEmpty && s.streamUrl.isNotEmpty)
        // The directory has many near-identical entries for big stations.
        .where((s) => seen.add(s.name.toLowerCase()))
        .take(_pageSize)
        .toList();
  }

  Future<dynamic> _get(String path, [Map<String, Object>? params]) async {
    Object? lastError;
    for (final host in await _resolveMirrors()) {
      try {
        final res = await _dio.get<dynamic>(
          'https://$host$path',
          queryParameters: params,
        );
        return res.data;
      } on DioException catch (e) {
        lastError = e;
        // 4xx won't get better on another mirror.
        final code = e.response?.statusCode ?? 0;
        if (code >= 400 && code < 500) rethrow;
      }
    }
    throw lastError!;
  }

  Future<List<String>> _resolveMirrors() async {
    if (_mirrors != null) return _mirrors!;
    try {
      final res = await _dio.get<List<dynamic>>(
        'https://all.api.radio-browser.info/json/servers',
      );
      final names =
          res.data!.map((s) => (s as Map)['name'] as String).toSet().toList()
            ..shuffle(Random());
      if (names.isNotEmpty) return _mirrors = names;
    } catch (_) {
      // Fall through to the static list.
    }
    return _mirrors = [..._fallbackMirrors]..shuffle(Random());
  }
}
