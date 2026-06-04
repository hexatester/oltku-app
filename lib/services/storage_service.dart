
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/models/odp_data.dart';

class StorageService {
  static Database? _db;
  static final _oltStore = intMapStoreFactory.store('olt_configs');
  static final _onuStore = intMapStoreFactory.store('onu_data');
  static final _locationStore = intMapStoreFactory.store('onu_locations');
  static final _odpStore = intMapStoreFactory.store('odp_data');

  static Future<Database> get _database async {
    if (_db != null) {
      return _db!;
    }
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    final dbPath = join(dir.path, 'oltku.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }

  static Future<List<OltConfig>> getOltConfigs() async {
    final db = await _database;
    final records = await _oltStore.find(db);
    return records.map((r) => OltConfig.fromJson(r.value)).toList();
  }

  static Future<OltConfig?> getOltConfig(String id) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('id', id));
    final record = await _oltStore.findFirst(db, finder: finder);
    if (record != null) {
      return OltConfig.fromJson(record.value);
    }
    return null;
  }

  static Future<void> saveOltConfig(OltConfig config) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('id', config.id));
    final existing = await _oltStore.findFirst(db, finder: finder);

    if (existing != null) {
      await _oltStore.record(existing.key).update(db, config.toJson());
    } else {
      await _oltStore.add(db, config.toJson());
    }
  }

  static Future<void> deleteOltConfig(String id) async {
    final db = await _database;
    final oltFinder = Finder(filter: Filter.equals('id', id));
    await _oltStore.delete(db, finder: oltFinder);

    // Cascade delete related ONUs
    final onuFinder = Finder(filter: Filter.equals('oltId', id));
    await _onuStore.delete(db, finder: onuFinder);

    // Cascade delete related locations
    await _locationStore.delete(db, finder: Finder(filter: Filter.equals('oltId', id)));

    // Cascade delete related ODPs
    await _odpStore.delete(db, finder: Finder(filter: Filter.equals('oltId', id)));
  }

  static Future<void> saveOnuList(String oltId, List<OnuData> onus) async {
    final db = await _database;
    // Delete existing ONUs for this OLT to replace them
    final finder = Finder(filter: Filter.equals('oltId', oltId));
    await _onuStore.delete(db, finder: finder);

    // Insert new ONUs
    final jsons = onus.map((onu) {
      final json = onu.toJson();
      json['oltId'] = oltId; // Ensure the parent link is set
      return json;
    }).toList();

    await db.transaction((txn) async {
      for (var json in jsons) {
        await _onuStore.add(txn, json);
      }
    });
  }

  static Future<List<OnuData>> getOnuList(String oltId) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('oltId', oltId));
    final records = await _onuStore.find(db, finder: finder);
    return records.map((r) => OnuData.fromJson(r.value)).toList();
  }

  static Future<void> saveOnuLocation(OnuLocationData location) async {
    final db = await _database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('oltId', location.oltId),
        Filter.equals('onuId', location.onuId),
      ]),
    );
    final existing = await _locationStore.findFirst(db, finder: finder);

    if (existing != null) {
      await _locationStore.record(existing.key).update(db, location.toJson());
    } else {
      await _locationStore.add(db, location.toJson());
    }
  }

  static Future<List<OnuLocationData>> getOnuLocations(String oltId) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('oltId', oltId));
    final records = await _locationStore.find(db, finder: finder);
    return records.map((r) => OnuLocationData.fromJson(r.value)).toList();
  }

  static Future<void> deleteOnuLocation(String oltId, String onuId) async {
    final db = await _database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('oltId', oltId),
        Filter.equals('onuId', onuId),
      ]),
    );
    await _locationStore.delete(db, finder: finder);
  }

  static Future<void> saveOdp(OdpData odp) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('id', odp.id));
    final existing = await _odpStore.findFirst(db, finder: finder);

    if (existing != null) {
      await _odpStore.record(existing.key).update(db, odp.toJson());
    } else {
      await _odpStore.add(db, odp.toJson());
    }
  }

  static Future<List<OdpData>> getOdps(String oltId) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('oltId', oltId));
    final records = await _odpStore.find(db, finder: finder);
    return records.map((r) => OdpData.fromJson(r.value)).toList();
  }

  static Future<void> deleteOdp(String odpId) async {
    final db = await _database;
    final finder = Finder(filter: Filter.equals('id', odpId));
    await _odpStore.delete(db, finder: finder);
  }
}
