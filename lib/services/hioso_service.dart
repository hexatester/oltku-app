import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oltku/models/onu_data.dart';

/// Unified Hioso OLT service supporting both HA7304 (22-field) and
/// HA7302CST (18-field) response formats.
///
/// Pass [submodel] = 'HA7304' or 'HA7302CST' for an explicit stride;
/// omit it to fall back to auto-detection from element count.
class HiosoService {
  static const String submodelHa7304 = 'HA7304';
  static const String submodelHa7302cst = 'HA7302CST';
  static const List<String> submodels = [submodelHa7304, submodelHa7302cst];
  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  static Future<http.Response> _getWithAuth(Uri uri, String basicAuth) async {
    int redirectCount = 0;
    Uri currentUri = uri;

    while (redirectCount < 5) {
      final request = http.Request('GET', currentUri);
      request.headers['Authorization'] = basicAuth;
      request.followRedirects = false;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.isRedirect) {
        final location = response.headers['location'];
        if (location != null) {
          currentUri = currentUri.resolve(location);
          redirectCount++;
          continue;
        }
      }
      return response;
    }
    throw Exception("Too many redirects");
  }

  static String _normalizeUrl(String url) {
    String full = url.trim();
    if (!full.startsWith('http://') && !full.startsWith('https://')) {
      full = 'http://$full';
    }
    if (full.endsWith('/')) {
      full = full.substring(0, full.length - 1);
    }
    return full;
  }

  static String _basicAuth(String username, String password) =>
      'Basic ${base64Encode(utf8.encode('$username:$password'))}';

  // ---------------------------------------------------------------------------
  // HA7302CST – 18-field ONU mapping
  // ---------------------------------------------------------------------------

  static String _formatSecondsToUptime(int seconds) {
    final d = seconds ~/ 86400;
    final h = (seconds % 86400) ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${d}d ${h}h ${m}m ${s}s';
  }

  static OnuData _mapHa7302CstRow(List<String> raw) {
    String v(int i) => i < raw.length ? raw[i] : '';

    final rtt = v(15);
    int? rttVal = int.tryParse(rtt);
    String distance = '--';
    if (rttVal != null) {
      double distVal = rttVal * 1.6393 - 157;
      distVal = distVal > 157 ? (distVal - 157) : 1;
      distance = distVal.toStringAsFixed(0);
    }

    const offReasonList = [
      'Other',
      'TIMEOUT',
      'ONU-init',
      'OLT-init',
      'RejectByBlackList',
      'RejectByWhiteList',
    ];
    final offlineReasonRaw = v(14);
    final offIdx = int.tryParse(offlineReasonRaw);
    final offlineReason =
        (offIdx != null && offIdx >= 0 && offIdx < offReasonList.length)
        ? offReasonList[offIdx]
        : offlineReasonRaw;

    final uptimeSec = int.tryParse(v(12));
    final uptime = uptimeSec != null ? _formatSecondsToUptime(uptimeSec) : '--';

    return OnuData(
      id: v(0),
      name: v(1),
      macAddress: v(2),
      status: v(3),
      fwVersion: v(4),
      chipId: v(5),
      ports: v(6),
      ctcStatus: '--',
      ctcVer: '--',
      activate: 'Activate',
      rtt: rtt,
      distance: distance,
      temperature: v(7),
      txPower: v(10),
      rxPower: v(11),
      onlineTime: v(16),
      offlineTime: v(17),
      offlineReason: offlineReason,
      uptime: uptime,
      deregisterCnt: v(13),
      voltage: v(8),
      biasCurrent: v(9),
    );
  }

  // ---------------------------------------------------------------------------
  // HTML / JS array parsers
  // ---------------------------------------------------------------------------

  /// Extracts raw string/number values from a JS `new Array(...)` declaration.
  static List<String> parseJsArray(String html, String arrayName) {
    final arrayRegex = RegExp(
      'var\\s+$arrayName\\s*=\\s*new\\s+Array\\s*\\(([\\s\\S]*?)\\);',
    );
    final match = arrayRegex.firstMatch(html);
    if (match == null) return [];

    final content = match.group(1) ?? '';
    final regex = RegExp(r"'([^']*)'|([-\d.]+)");
    final values = <String>[];
    for (final m in regex.allMatches(content)) {
      values.add(m.group(1) ?? m.group(2) ?? '');
    }
    return values;
  }

  /// Parses the ONU list HTML page.
  ///
  /// [submodel] can be 'HA7304' (22-field) or 'HA7302CST' (18-field) to
  /// force a specific stride. When null, the stride is auto-detected from the
  /// element count.
  static List<OnuData> parseOnuHtml(String html, {String? submodel}) {
    final arrayRegex = RegExp(
      r'var\s+onutable\s*=\s*new\s+Array\s*\([\s\S]*?\);',
    );
    if (!arrayRegex.hasMatch(html)) {
      throw Exception(
        "Format Error: Could not locate 'onutable' array in OLT response.",
      );
    }

    final rawValues = parseJsArray(html, 'onutable');
    if (rawValues.isEmpty) {
      throw Exception('No ONU data elements found in JS array.');
    }

    const int stride22 = 22;
    const int stride18 = 18;

    // Use explicit submodel hint when available.
    final int stride;
    if (submodel == submodelHa7304) {
      stride = stride22;
    } else if (submodel == submodelHa7302cst) {
      stride = stride18;
    } else if (rawValues.length % stride22 == 0) {
      stride = stride22;
    } else if (rawValues.length % stride18 == 0) {
      stride = stride18;
    } else {
      // Pick whichever leaves fewer orphan elements
      stride = (rawValues.length % stride22 <= rawValues.length % stride18)
          ? stride22
          : stride18;
    }

    final list = <OnuData>[];
    final int maxIdx = (rawValues.length ~/ stride) * stride;

    for (int i = 0; i < maxIdx; i += stride) {
      final row = rawValues.sublist(i, i + stride);
      if (stride == stride22) {
        list.add(OnuData.fromRawList(row));
      } else {
        list.add(_mapHa7302CstRow(row));
      }
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Future<List<OnuData>> fetchOnuList({
    required String url,
    required String username,
    required String password,
    String? submodel,
  }) async {
    final fullUrl = _normalizeUrl(url);
    final uri = Uri.parse('$fullUrl/onuAllPonOnuList.asp');
    final auth = _basicAuth(username, password);

    final response = await _getWithAuth(uri, auth);
    if (response.statusCode == 200) {
      return parseOnuHtml(response.body, submodel: submodel);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized (401). Check username & password.');
    } else {
      throw Exception('Server returned HTTP ${response.statusCode}');
    }
  }

  static Future<OnuData> fetchOnuConfig({
    required OnuData original,
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      final fullUrl = _normalizeUrl(url);
      final ponId = original.id.split(':')[0];
      final uri = Uri.parse(
        '$fullUrl/onuConfig.asp?onuno=${original.id}&oltponno=$ponId',
      );
      final auth = _basicAuth(username, password);

      final response = await _getWithAuth(uri, auth);
      if (response.statusCode != 200) {
        // Gracefully return original on non-200
        return original;
      }

      final html = response.body;
      final infoRaw = parseJsArray(html, 'onuinfo');
      final opmRaw = parseJsArray(html, 'onuOpmInfo');

      if (infoRaw.isEmpty && opmRaw.isEmpty) return original;

      return original.mergeWithConfig(infoRaw: infoRaw, opmRaw: opmRaw);
    } catch (_) {
      return original;
    }
  }

  static Future<bool> rebootOnu({
    required OnuData onu,
    required String url,
    required String username,
    required String password,
  }) async {
    final fullUrl = _normalizeUrl(url);
    final uri = Uri.parse('$fullUrl/goform/setOnu');
    final auth = _basicAuth(username, password);

    final request = http.Request('POST', uri);
    request.headers['Authorization'] = auth;
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';
    request.body =
        'onuId=${Uri.encodeComponent(onu.id)}'
        '&onuName=${Uri.encodeComponent(onu.name)}'
        '&onuOperation=rebootOp';
    request.followRedirects = false;

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 10),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 302 || response.statusCode == 200) {
      final location = response.headers['location'] ?? '';
      if (location.contains('msg=21') || response.body.contains('msg=21')) {
        return true;
      }
    }

    throw Exception(
      'Failed to reboot. Server returned status: ${response.statusCode}',
    );
  }
}
