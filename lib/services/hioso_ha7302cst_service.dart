import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/hioso_ha7304_service.dart';

class HiosoHa7302CstService {
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

  static OnuData _mapToOnuData(List<String> raw) {
    String getValue(int idx) => idx < raw.length ? raw[idx] : "";

    final String id = getValue(0);
    final String name = getValue(1);
    final String macAddress = getValue(2);
    final String status = getValue(3);
    final String fwVersion = getValue(4);
    final String chipId = getValue(5);
    final String ports = getValue(6);
    final String temperature = getValue(7);
    final String voltage = getValue(8);
    final String biasCurrent = getValue(9);
    final String txPower = getValue(10);
    final String rxPower = getValue(11);
    final String uptimeRaw = getValue(12);
    final String deregisterCnt = getValue(13);
    final String offlineReasonRaw = getValue(14);
    final String rtt = getValue(15);
    final String onlineTime = getValue(16);
    final String offlineTime = getValue(17);

    // Distance calculation
    int? rttVal = int.tryParse(rtt);
    String distance = "--";
    if (rttVal != null) {
      double distVal = rttVal * 1.6393 - 157;
      distVal = distVal > 157 ? (distVal - 157) : 1;
      distance = distVal.toStringAsFixed(0);
    }

    // Offline Reason mapping
    final offReasonList = [
      "Other",
      "TIMEOUT",
      "ONU-init",
      "OLT-init",
      "RejectByBlackList",
      "RejectByWhiteList",
    ];
    String offlineReason = "";
    int? offIdx = int.tryParse(offlineReasonRaw);
    offlineReason =
        (offIdx != null && offIdx >= 0 && offIdx < offReasonList.length)
        ? offReasonList[offIdx]
        : offlineReasonRaw;

    // Uptime formatting
    int? uptimeSec = int.tryParse(uptimeRaw);
    final String uptime = uptimeSec != null
        ? formatSecondsToUptime(uptimeSec)
        : "--";

    return OnuData(
      id: id,
      name: name,
      macAddress: macAddress,
      status: status,
      fwVersion: fwVersion,
      chipId: chipId,
      ports: ports,
      ctcStatus: "--",
      ctcVer: "--",
      activate: "Activate",
      rtt: rtt,
      distance: distance,
      temperature: temperature,
      txPower: txPower,
      rxPower: rxPower,
      onlineTime: onlineTime,
      offlineTime: offlineTime,
      offlineReason: offlineReason,
      uptime: uptime,
      deregisterCnt: deregisterCnt,
      voltage: voltage,
      biasCurrent: biasCurrent,
    );
  }

  static List<OnuData> parseOnuHtml(String html) {
    final RegExp arrayRegex = RegExp(
      r'var\s+onutable\s*=\s*new\s+Array\s*\(([\s\S]*?)\);',
    );
    final match = arrayRegex.firstMatch(html);
    if (match == null) {
      throw Exception(
        "Format Error: Could not locate 'onutable' array content in OLT response.",
      );
    }

    final String arrayContent = match.group(1) ?? '';

    final RegExp regex = RegExp(r"'([^']*)'|([-\d.]+)");
    final List<String> rawValues = [];
    for (final m in regex.allMatches(arrayContent)) {
      if (m.group(1) != null) {
        rawValues.add(m.group(1)!);
      } else if (m.group(2) != null) {
        rawValues.add(m.group(2)!);
      }
    }

    if (rawValues.isEmpty) {
      throw Exception("No ONU data elements found in JS array.");
    }

    final List<OnuData> list = [];
    final int elementsPerRow = 18;
    final int maxIdx = (rawValues.length ~/ elementsPerRow) * elementsPerRow;
    for (int i = 0; i < maxIdx; i += elementsPerRow) {
      list.add(_mapToOnuData(rawValues.sublist(i, i + elementsPerRow)));
    }

    return list;
  }

  static Future<List<OnuData>> fetchOnuList({
    required String url,
    required String username,
    required String password,
  }) async {
    String fullUrl = url.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'http://$fullUrl';
    }
    if (fullUrl.endsWith('/')) {
      fullUrl = fullUrl.substring(0, fullUrl.length - 1);
    }

    final uri = Uri.parse('$fullUrl/onuAllPonOnuList.asp');
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await _getWithAuth(uri, basicAuth);

    if (response.statusCode == 200) {
      return parseOnuHtml(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized (401). Check username & password.");
    } else {
      throw Exception("Server returned HTTP ${response.statusCode}");
    }
  }

  static List<String> _extractArrayElements(String html, String arrayName) {
    final RegExp arrayRegex = RegExp(
      'var\\s+\$arrayName\\s*=\\s*new\\s+Array\\s*\\(([\\s\\S]*?)\\);',
    );
    final match = arrayRegex.firstMatch(html);
    if (match == null) return [];

    final String arrayContent = match.group(1) ?? '';
    final RegExp regex = RegExp(r"'([^']*)'|([-\d.]+)");
    final List<String> rawValues = [];
    for (final m in regex.allMatches(arrayContent)) {
      if (m.group(1) != null) {
        rawValues.add(m.group(1)!);
      } else if (m.group(2) != null) {
        rawValues.add(m.group(2)!);
      }
    }
    return rawValues;
  }

  static Future<OnuData> fetchOnuConfig({
    required OnuData original,
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      String html;
      String fullUrl = url.trim();
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        fullUrl = 'http://$fullUrl';
      }
      if (fullUrl.endsWith('/')) {
        fullUrl = fullUrl.substring(0, fullUrl.length - 1);
      }

      final ponId = original.id.split(':')[0];
      final uri = Uri.parse(
        '$fullUrl/onuConfig.asp?onuno=${original.id}&oltponno=$ponId',
      );
      final String basicAuth =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';

      final response = await _getWithAuth(uri, basicAuth);

      if (response.statusCode != 200) {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
      html = response.body;

      final infoRaw = _extractArrayElements(html, 'onuinfo');
      final opmRaw = _extractArrayElements(html, 'onuOpmInfo');

      if (infoRaw.isEmpty && opmRaw.isEmpty) {
        return original;
      }

      return original.mergeWithConfig(infoRaw: infoRaw, opmRaw: opmRaw);
    } catch (e) {
      return original;
    }
  }

  static Future<bool> rebootOnu({
    required OnuData onu,
    required String url,
    required String username,
    required String password,
  }) async {
    // HA7302CST uses the same reboot command as HA7304
    return HiosoHa7304Service.rebootOnu(
      onu: onu,
      url: url,
      username: username,
      password: password,
    );
  }
}
