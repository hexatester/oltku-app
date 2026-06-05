import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/services/hioso_service.dart';

/// General OLT Service that handles caching and delegates to specific OLT implementations.
class OltService {
  static bool isLastLoadFromCache = false;

  /// Fetches the stats HTML page from OLT and falls back to cache
  static Future<List<OnuData>> fetchOnuList({
    required String model,
    required String url,
    required String username,
    required String password,
    required String oltId,
  }) async {
    try {
      final List<OnuData> list;
      if (model == 'Hioso') {
        list = await HiosoService.fetchOnuList(
          url: url,
          username: username,
          password: password,
        );
      } else {
        throw Exception('Unsupported OLT model: $model');
      }
      isLastLoadFromCache = false;
      await StorageService.saveOnuList(oltId, list);
      return list;
    } catch (e) {
      if (e.toString().contains("Unauthorized (401)")) {
        rethrow;
      }
      final cachedList = await StorageService.getOnuList(oltId);
      if (cachedList.isNotEmpty) {
        isLastLoadFromCache = true;
        return cachedList;
      }
      rethrow;
    }
  }

  /// Fetches detailed config and optical parameters for a specific ONU
  static Future<OnuData> getOnuDetail({
    required String model,
    required OnuData original,
    required String url,
    required String username,
    required String password,
  }) async {
    if (model == 'Hioso') {
      return HiosoService.fetchOnuConfig(
        original: original,
        url: url,
        username: username,
        password: password,
      );
    }
    throw Exception('Unsupported OLT model: $model');
  }

  /// Reboots the specified ONU
  static Future<bool> rebootOnu({
    required String model,
    required OnuData onu,
    required String url,
    required String username,
    required String password,
  }) async {
    if (model == 'Hioso') {
      return HiosoService.rebootOnu(
        onu: onu,
        url: url,
        username: username,
        password: password,
      );
    }
    throw Exception('Unsupported OLT model: $model');
  }
}
