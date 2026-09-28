import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../models/podcast.dart';
import 'podcast_repository.dart';
import 'rss_parser.dart';

/// The podcast source (free, no account or API key):
/// - Discovery: Apple's public top-charts feed and iTunes Search API.
/// - Episodes: the show's own RSS feed, parsed on-device.
class AppleRssPodcastRepository implements PodcastRepository {
  AppleRssPodcastRepository(this._dio);

  final Dio _dio;

  @override
  String get attribution => 'Charts by Apple Podcasts · Episodes from RSS';

  @override
  Future<List<Podcast>> topPodcasts({required String region}) async {
    final ids = await _topChartIds(region);
    if (ids.isEmpty) return const [];

    // The chart has no feed URLs; one batched lookup adds them (and HD art).
    final lookup = await _getJson('https://itunes.apple.com/lookup', {
      'id': ids.join(','),
      'entity': 'podcast',
    });
    final byId = {
      for (final r in (lookup['results'] as List).cast<Map<String, dynamic>>())
        '${r['collectionId']}': _fromItunes(r),
    };
    // Keep chart order; drop shows without a feed (can't list episodes).
    return [
      for (final id in ids)
        if (byId[id] case final p? when p.feedUrl != null) p,
    ];
  }

  /// Apple show ids of the top chart, in rank order.
  ///
  /// The legacy iTunes feed is fast and dependable; the newer marketing-tools
  /// feed often hangs ~30 s then 504s, so it is only the fallback.
  Future<List<String>> _topChartIds(String region) async {
    try {
      final json = await _getJson(
        'https://itunes.apple.com/$region/rss/toppodcasts/limit=50/json',
      );
      final entries = json['feed']['entry'];
      final list = entries is List ? entries : [entries];
      return [
        for (final e in list) (e as Map)['id']['attributes']['im:id'] as String,
      ];
    } catch (_) {
      final json = await _getJson(
        'https://rss.marketingtools.apple.com/api/v2/$region/podcasts/top/50/podcasts.json',
      );
      return [
        for (final r in (json['feed']['results'] as List))
          (r as Map)['id'] as String,
      ];
    }
  }

  @override
  Future<List<Podcast>> search(String query, {required String region}) async {
    final json = await _getJson('https://itunes.apple.com/search', {
      'media': 'podcast',
      'term': query,
      'country': region,
      'limit': '40',
    });
    return (json['results'] as List)
        .cast<Map<String, dynamic>>()
        .map(_fromItunes)
        .where((p) => p.feedUrl != null)
        .toList();
  }

  @override
  Future<PodcastDetails> details(Podcast podcast) async {
    var feedUrl = podcast.feedUrl;
    if (feedUrl == null) {
      final json = await _getJson('https://itunes.apple.com/lookup', {
        'id': podcast.id,
      });
      final results = json['results'] as List;
      if (results.isEmpty) throw const ApiException('Podcast not found.');
      feedUrl = _fromItunes(results.first as Map<String, dynamic>).feedUrl;
    }
    if (feedUrl == null) {
      throw const ApiException('This podcast has no public feed.');
    }

    final res = await _dio.get<String>(
      feedUrl,
      options: Options(responseType: ResponseType.plain),
    );
    try {
      return await compute(parsePodcastFeed, res.data ?? '');
    } catch (_) {
      throw const ApiException("This podcast's feed couldn't be read.");
    }
  }

  /// Apple serves JSON as `text/javascript`, so we decode it ourselves.
  /// Its endpoints return sporadic 5xx; one quick retry hides most of them.
  Future<Map<String, dynamic>> _getJson(
    String url, [
    Map<String, String>? params,
  ]) async {
    Future<Response<String>> get() => _dio.get<String>(
      url,
      queryParameters: params,
      options: Options(responseType: ResponseType.plain),
    );

    Response<String> res;
    try {
      res = await get();
    } on DioException catch (e) {
      if ((e.response?.statusCode ?? 0) < 500) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 600));
      res = await get();
    }
    return jsonDecode(res.data!) as Map<String, dynamic>;
  }

  static Podcast _fromItunes(Map<String, dynamic> r) => Podcast(
    id: '${r['collectionId']}',
    title: r['collectionName'] as String? ?? '',
    publisher: r['artistName'] as String? ?? '',
    artworkUrl:
        r['artworkUrl600'] as String? ?? r['artworkUrl100'] as String? ?? '',
    feedUrl: r['feedUrl'] as String?,
  );
}
