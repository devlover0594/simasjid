import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

/// Simple repository to fetch prayer times from MyQuran v3 API.
/// It will try a few variants of the endpoint to be tolerant of API responses.
class ApiRepository {
  final http.Client client;
  ApiRepository({http.Client? client}) : client = client ?? http.Client();

  /// Fetches prayer times. If [kotaId] is provided, the repository will try
  /// to request schedules for that city. Returns a map of normalized
  /// prayer name -> time (e.g. {"Subuh": "04:30", ...}) or null on failure.
  Future<Map<String, String>?> fetchPrayerTimes({
    String? kotaId,
    String? kotaName,
    String provider = 'MyQuran',
  }) async {
    try {
      if (provider == 'AlAdhan') {
        return _fetchAlAdhan(kotaName);
      }
      if (provider == 'EQuran') {
        return _fetchEQuran(kotaId, kotaName);
      }

      // Jika provider MyQuran tapi kotaId kosong, tidak bisa ambil jadwal
      if (kotaId == null || kotaId.isEmpty) return null;

      final now = DateTime.now();
      final yyyy = now.year.toString();
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');

      final attempts = <Uri>[];
      // Prefer the /today endpoint with tz param
      attempts.add(
        Uri.parse(
          'https://api.myquran.com/v3/sholat/jadwal/$kotaId/today?tz=Asia%2FJakarta',
        ),
      );
      // Also try the full date endpoint as backup
      attempts.add(
        Uri.parse(
          'https://api.myquran.com/v3/sholat/jadwal/$kotaId/$yyyy/$mm/$dd',
        ),
      );
      // Try query param variant
      attempts.add(
        Uri.https('api.myquran.com', '/v3/sholat', {'kota': kotaId}),
      );

      for (final uri in attempts) {
        try {
          if (kDebugMode) print('ApiRepository: GET $uri');

          // First attempt: http
          String? body;
          try {
            final resp = await client
                .get(uri, headers: {'Accept': 'application/json'})
                .timeout(const Duration(seconds: 10));
            if (kDebugMode) print('ApiRepository: $uri -> ${resp.statusCode}');
            if (resp.statusCode == 200) body = utf8.decode(resp.bodyBytes);
          } catch (e) {
            if (kDebugMode) print('ApiRepository: request $uri failed: $e');
          }

          if (body == null) continue;

          final decodedRaw = jsonDecode(body);
          if (decodedRaw is! Map) continue;
          final decoded = decodedRaw as Map<String, dynamic>;

          // If there's a 'data' with 'jadwal', use it
          if (decoded['data'] is Map) {
            final data = decoded['data'] as Map;

            // Common structure: data.jadwal contains keys like subuh, dzuhur, ashar, dsb
            if (data['jadwal'] is Map) {
              var jadwalGroup = Map<String, dynamic>.from(data['jadwal'] as Map);
              Map<String, dynamic>? jadwal;

              // Try specific date key if today exists
              final todayKey = '$yyyy-$mm-$dd';
              if (jadwalGroup.containsKey(todayKey) &&
                  jadwalGroup[todayKey] is Map) {
                jadwal = Map<String, dynamic>.from(jadwalGroup[todayKey] as Map);
              } else {
                // Fallback: look for any entry containing "subuh"
                for (final val in jadwalGroup.values) {
                  if (val is Map &&
                      (val.containsKey('subuh') || val.containsKey('Subuh'))) {
                    jadwal = Map<String, dynamic>.from(val);
                    break;
                  }
                }
              }

              if (jadwal == null) {
                // If no nested date key found, check if jadwalGroup itself is the record
                if (jadwalGroup.containsKey('subuh') ||
                    jadwalGroup.containsKey('Subuh')) {
                  jadwal = jadwalGroup;
                }
              }

              if (jadwal != null) {
                final map = <String, String>{};
                void addIf(String key, String name) {
                  if (jadwal!.containsKey(key) && jadwal[key] != null) {
                    map[name] = jadwal[key].toString();
                  }
                }

                addIf('subuh', 'Subuh');
                addIf('dzuhur', 'Dzuhur');
                addIf('ashar', 'Ashar');
                addIf('maghrib', 'Maghrib');
                addIf('isya', 'Isya');

                if (map.isNotEmpty) return map;
              }
            } else if (data['jadwal'] is List) {
              // Handle list format (less common for MyQuran v3 day-specific, but possible)
              final List list = data['jadwal'];
              final day = now.day;
              final entry = list.firstWhere(
                (e) =>
                    e is Map &&
                    (e['tanggal'] == day ||
                        e['tanggal'].toString().contains(dd)),
                orElse: () => null,
              );
              if (entry != null) {
                final map = <String, String>{};
                void add(String k, String n) =>
                    entry[k] != null ? map[n] = entry[k].toString() : null;
                add('subuh', 'Subuh');
                add('dzuhur', 'Dzuhur');
                add('ashar', 'Ashar');
                add('maghrib', 'Maghrib');
                add('isya', 'Isya');
                if (map.isNotEmpty) return map;
              }
            }
          }

          // Generic scan: look through nested maps for known keys
          final found = <String, String>{};
          void scan(dynamic node) {
            if (node is Map) {
              for (final entry in node.entries) {
                final k = entry.key.toString().toLowerCase();
                final v = entry.value;
                if (v == null) continue;
                if (k == 'subuh' || k == 'imsak') {
                  found['Subuh'] = v.toString();
                }
                if (k == 'dzuhur' || k == 'dhuhr') {
                  found['Dzuhur'] = v.toString();
                }
                if (k == 'ashar' || k == 'asar') {
                  found['Ashar'] = v.toString();
                }
                if (k == 'maghrib') {
                  found['Maghrib'] = v.toString();
                }
                if (k == 'isya' || k == 'isha') {
                  found['Isya'] = v.toString();
                }

                if (v is Map || v is List) {
                  scan(v);
                }
              }
            } else if (node is List) {
              for (final e in node) {
                scan(e);
              }
            }
          }

          scan(decoded);
          if (found.isNotEmpty) return found;
        } catch (e) {
          if (kDebugMode) print('ApiRepository: request $uri failed: $e');
          continue;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>?> _fetchAlAdhan(String? kotaName) async {
    if (kotaName == null || kotaName.isEmpty) return null;
    // Clean city name for AlAdhan (remove KAB. / KOTA)
    final city = kotaName
        .replaceAll(RegExp(r'(KAB\.|KOTA|ADM\.)\s*', caseSensitive: false), '')
        .trim();

    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timingsByCity?city=$city&country=Indonesia&method=20',
    );

    try {
      if (kDebugMode) print('ApiRepository: GET $uri');
      final resp = await client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        if (decoded['data'] != null && decoded['data']['timings'] != null) {
          final timings = decoded['data']['timings'];
          final map = <String, String>{};

          void add(String key, String name) {
            if (timings[key] != null) {
              // AlAdhan format usually "HH:mm"
              map[name] = timings[key].toString();
            }
          }

          add('Fajr', 'Subuh');
          add('Dhuhr', 'Dzuhur');
          add('Asr', 'Ashar');
          add('Maghrib', 'Maghrib');
          add('Isha', 'Isya');

          // Try to get Hijri date if available
          if (decoded['data']['date'] != null &&
              decoded['data']['date']['hijri'] != null) {
            // We can store it in the map, though main.dart needs to handle it
            // map['hijri_json'] = jsonEncode(decoded['data']['date']['hijri']);
          }

          return map;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches list of provinces from EQuran API (Shalat).
  Future<List<String>?> fetchProvincesShalatEQuran() async {
    try {
      final uri = Uri.parse('https://equran.id/api/v2/shalat/provinsi');
      if (kDebugMode) print('ApiRepository: GET $uri');
      final resp = await client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['code'] == 200 && body['data'] is List) {
          return List<String>.from(body['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiRepository: fetchProvincesShalatEQuran error: $e');
    }
    return null;
  }

  /// Fetches list of cities for a province from EQuran API (Shalat).
  Future<List<String>?> fetchCitiesShalatEQuran(String province) async {
    try {
      final uri = Uri.parse('https://equran.id/api/v2/shalat/kabkota');
      if (kDebugMode) print('ApiRepository: POST $uri');
      final resp = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'provinsi': province}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['code'] == 200 && body['data'] is List) {
          return List<String>.from(body['data']);
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiRepository: fetchCitiesShalatEQuran error: $e');
    }
    return null;
  }

  Future<Map<String, String>?> _fetchEQuran(
    String? province,
    String? city,
  ) async {
    if (province == null || city == null) return null;
    try {
      final uri = Uri.parse('https://equran.id/api/v2/shalat');
      if (kDebugMode) print('ApiRepository: POST $uri');
      final resp = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'provinsi': province, 'kabkota': city}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['code'] == 200 && body['data'] != null) {
          final data = body['data'];
          List? list;
          if (data['jadwal'] is List) {
            list = data['jadwal'];
          } else if (data['imsakiyah'] is List) {
            list = data['imsakiyah'];
          }

          if (list != null) {
            final now = DateTime.now();
            final day = now.day;

            final todayEntry = list.firstWhere(
              (e) =>
                  e['tanggal'] == day ||
                  e['tanggal'].toString() == day.toString(),
              orElse: () => null,
            );

            if (todayEntry != null) {
              return {
                'Subuh': todayEntry['subuh'].toString(),
                'Dzuhur': todayEntry['dzuhur'].toString(),
                'Ashar': todayEntry['ashar'].toString(),
                'Maghrib': todayEntry['maghrib'].toString(),
                'Isya': todayEntry['isya'].toString(),
              };
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('ApiRepository: _fetchEQuran error: $e');
    }
    return null;
  }

  /// Fetches monthly imsakiyah schedule from EQuran API.
  /// Returns a list of maps, each representing a day's schedule, or null on failure.
  Future<List<Map<String, String>>?> fetchMonthlyImsakiyahEQuran(
    String province,
    String city,
  ) async {
    try {
      final uri = Uri.parse('https://equran.id/api/v2/shalat');
      if (kDebugMode) print('ApiRepository: POST $uri');
      final resp = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'provinsi': province, 'kabkota': city}),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body['code'] == 200 && body['data'] != null) {
          final data = body['data'];
          List? list;
          if (data['jadwal'] is List) {
            list = data['jadwal'];
          } else if (data['imsakiyah'] is List) {
            list = data['imsakiyah'];
          }

          if (list != null) {
            return list.map((e) {
              return {
                'tanggal': e['tanggal_lengkap']?.toString() ??
                    e['tanggal']?.toString() ??
                    '',
                'imsak': e['imsak']?.toString() ?? '',
                'subuh': e['subuh']?.toString() ?? '',
                'terbit': e['terbit']?.toString() ?? '',
                'dhuha': e['dhuha']?.toString() ?? '',
                'dzuhur': e['dzuhur']?.toString() ?? '',
                'ashar': e['ashar']?.toString() ?? '',
                'maghrib': e['maghrib']?.toString() ?? '',
                'isya': e['isya']?.toString() ?? '',
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiRepository: fetchMonthlyImsakiyahEQuran error: $e');
      }
    }
    return null;
  }

  /// Fetches Hijri date from MyQuran API.
  /// Returns a Map with keys 'day', 'month', 'year', 'monthName' or null on failure.
  Future<Map<String, dynamic>?> fetchHijriDate({int adjustment = -2}) async {
    try {
      // Menggunakan API v2 dengan penyesuaian adj=-1 sesuai permintaan
      final uri = Uri.parse(
        'https://api.myquran.com/v2/cal/hijr/?adj=$adjustment',
      );
      if (kDebugMode) print('ApiRepository: GET $uri');
      final resp = await client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        // Validasi struktur JSON v2
        // {"status":true, "data": {"date": [...], "num": [...]}}
        if (decoded is Map &&
            decoded['status'] == true &&
            decoded['data'] is Map) {
          final data = decoded['data'];

          if (data['num'] is List && (data['num'] as List).length >= 7) {
            final nums = data['num'] as List;
            // Format num: [dow, greg_day, greg_month, greg_year, hijri_day, hijri_month, hijri_year]
            final day = int.tryParse(nums[4].toString()) ?? 0;
            final month = int.tryParse(nums[5].toString()) ?? 0;
            final year = int.tryParse(nums[6].toString()) ?? 0;

            // Validasi tahun hijriah (sanity check)
            if (year < 1400 || year > 1500) return null;

            String monthName = '';
            // Coba ambil nama bulan dari array date jika ada
            if (data['date'] is List && (data['date'] as List).length >= 2) {
              // Format: "1 Ramadhan 1447 H"
              final dateStr = data['date'][1].toString();
              final parts = dateStr.split(' ');
              // Asumsi format: [Tanggal, Nama_Bulan..., Tahun, H]
              if (parts.length >= 3) {
                // Ambil elemen dari index 1 sampai sebelum tahun (length-2)
                final nameParts = parts.sublist(1, parts.length - 2);
                monthName = nameParts.join(' ');
              }
            }

            // Fallback nama bulan jika parsing gagal
            if (monthName.isEmpty && month >= 1 && month <= 12) {
              const months = [
                'Muharram',
                'Safar',
                'Rabiul Awal',
                'Rabiul Akhir',
                'Jumadil Awal',
                'Jumadil Akhir',
                'Rajab',
                "Sya'ban",
                'Ramadhan',
                'Syawwal',
                'Dzulqaidah',
                'Dzulhijah',
              ];
              monthName = months[month - 1];
            }

            return {
              'day': day,
              'month': month,
              'year': year,
              'monthName': monthName,
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches a random hadith from MyQuran API.
  /// Returns a map with 'text' and 'source' or null on failure.
  Future<Map<String, String>?> fetchRandomHadith() async {
    try {
      final uri = Uri.parse('https://api.myquran.com/v3/hadis/enc/random');
      if (kDebugMode) print('ApiRepository: GET $uri');
      final resp = await client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        if (decoded['data'] is Map) {
          final data = decoded['data'];
          final text = data['text']?['id']?.toString();
          final source = data['takhrij']?.toString();
          if (text != null && source != null) {
            return {'text': text, 'source': source};
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetches list of cities (kabkota) from MyQuran API.
  /// Returns list of maps { 'id': '...', 'lokasi': '...' } or null on failure.
  Future<List<Map<String, String>>?> fetchCities() async {
    try {
      final uri = Uri.parse('https://api.myquran.com/v3/sholat/kabkota/semua');
      if (kDebugMode) print('ApiRepository: GET $uri');
      final resp = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) print('ApiRepository: $uri -> ${resp.statusCode}');
      if (resp.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is Map && decoded['data'] is List) {
        final List data = decoded['data'];
        final out = <Map<String, String>>[];
        for (final item in data) {
          if (item is Map) {
            final id = (item['id'] ?? '').toString();
            final lokasi = (item['lokasi'] ?? '').toString();
            out.add({'id': id, 'lokasi': lokasi});
          }
        }
        return out;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
