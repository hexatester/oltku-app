import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oltku/models/onu_data.dart';

class HiosoHa7304Service {
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

  static List<OnuData> parseOnuHtml(String html) {
    final int arrayStart = html.indexOf('var onutable=new Array(');
    if (arrayStart == -1) {
      throw Exception(
        "Format Error: Could not locate 'onutable' array in OLT response.",
      );
    }

    final int arrayEnd = html.indexOf(');', arrayStart);
    if (arrayEnd == -1) {
      throw Exception(
        "Format Error: Missing end sequence of 'onutable' array.",
      );
    }

    final String arrayContent = html.substring(
      arrayStart + 'var onutable=new Array('.length,
      arrayEnd,
    );

    // Extract all single-quoted text elements
    final RegExp regex = RegExp(r"'([^']*)'");
    final List<String> rawValues = [];
    for (final match in regex.allMatches(arrayContent)) {
      rawValues.add(match.group(1) ?? '');
    }

    if (rawValues.isEmpty) {
      throw Exception("No ONU data elements found in JS array.");
    }

    final List<OnuData> list = [];
    final int maxIdx = (rawValues.length ~/ 22) * 22;
    for (int i = 0; i < maxIdx; i += 22) {
      list.add(OnuData.fromRawList(rawValues.sublist(i, i + 22)));
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

  static List<String> parseJsArray(String html, String arrayName) {
    final RegExp regex = RegExp(
      'var\\s+$arrayName\\s*=\\s*new\\s+Array\\s*\\(([^)]*)\\)',
      caseSensitive: false,
    );
    final Match? match = regex.firstMatch(html);
    if (match == null) return [];

    final String arrayContent = match.group(1) ?? '';
    final RegExp stringRegex = RegExp(r"'([^']*)'");
    final List<String> rawValues = [];
    for (final m in stringRegex.allMatches(arrayContent)) {
      rawValues.add(m.group(1) ?? '');
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

      if (response.statusCode == 200) {
        html = response.body;
      } else {
        throw Exception("OLT returned status code ${response.statusCode}");
      }

      final infoRaw = parseJsArray(html, 'onuinfo');
      final opmRaw = parseJsArray(html, 'onuOpmInfo');

      if (infoRaw.isEmpty) {
        throw Exception("Failed to parse detailed config parameters.");
      }

      return original.mergeWithConfig(infoRaw: infoRaw, opmRaw: opmRaw);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<bool> rebootOnu({
    required OnuData onu,
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

    final uri = Uri.parse('$fullUrl/goform/setOnu');
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final request = http.Request('POST', uri);
    request.headers['Authorization'] = basicAuth;
    request.headers['Content-Type'] = 'application/x-www-form-urlencoded';

    // Construct the payload required for a reboot operation
    final payload =
        'onuId=${Uri.encodeComponent(onu.id)}&onuName=${Uri.encodeComponent(onu.name)}&onuOperation=rebootOp';
    request.body = payload;

    // We disable automatic redirects to easily capture the 302 Found response pointing to message.asp?msg=21
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
