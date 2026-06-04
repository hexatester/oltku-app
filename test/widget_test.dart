import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oltku/main.dart';
import 'package:oltku/services/olt_service.dart';
import 'package:oltku/services/hioso_ha7304_service.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/storage_service.dart';

void main() {
  testWidgets('Olt List View UI elements test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify presence of title and empty state
    expect(find.text('Saved OLTs'), findsOneWidget);
    expect(find.text('No OLTs Saved Yet'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Navigate to add OLT screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add New OLT'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);
  });

  test('HTML Parser extracts data correctly', () {
    const testHtml = """
<script type="text/javascript">
var onutable=new Array(
'0/1:1','Kantor','FC:8E:5B:2B:66:98','Up','0101','9127','5','5','30','0','160','46.00','3.00','12.00','2.06','-17.06','2026-06-03 10:20:22','2026-06-03 10:19:21','1','62121','3','1'
);
</script>
""";

    final onus = HiosoHa7304Service.parseOnuHtml(testHtml);
    expect(onus.length, 1);

    final onu = onus.first;
    expect(onu.id, '0/1:1');
    expect(onu.name, 'Kantor');
    expect(onu.macAddress, 'FC:8E:5B:2B:66:98');
    expect(onu.status, 'Up');
    expect(onu.fwVersion, '0101');
    expect(onu.chipId, '9127');
    expect(onu.ports, '5');
    expect(onu.ctcStatus, 'CtcNegDone'); // maps from index 5
    expect(onu.ctcVer, '30');
    expect(onu.activate, 'Activate'); // maps from 0
    expect(onu.rtt, '160');
    expect(
      onu.distance,
      '1',
    ); // (160 * 1.6393 - 157) = 105.288 <= 157 -> returns 1
    expect(onu.temperature, '46.00');
    expect(onu.txPower, '2.06');
    expect(onu.rxPower, '-17.06');
    expect(onu.onlineTime, '2026-06-03 10:20:22');
    expect(onu.offlineTime, '2026-06-03 10:19:21');
    expect(
      onu.offlineReason,
      'Dying_gasp',
    ); // dyingGaspRaw '1' overrides other reason indexes
    expect(onu.uptime, '17H 15M 21S'); // 62121 seconds
    expect(onu.deregisterCnt, '3');
  });

  test('HTML Parser extracts detailed config data correctly', () {
    const testOnuHtml = """
<script language="javascript">
var oltponno = '0/1';
var onuno = '0/1:1';
var onuinfo = new Array(
  '0/1:1', 'Kantor', 'FC:8E:5B:2B:66:98', 'Up', '0101', '9127', '5', '2026-04-18 08:46:47', '2026-06-03 10:20:22', '2026-06-03 10:19:21', '5', '30', '0', '1', '64600', '3', '1'
);
var onuOpmInfo = new Array(
  '0/1:1', '47.00', '3.00', '13.00', '2.08', '-17.14'
);
</script>
""";

    final infoRaw = HiosoHa7304Service.parseJsArray(testOnuHtml, 'onuinfo');
    final opmRaw = HiosoHa7304Service.parseJsArray(testOnuHtml, 'onuOpmInfo');

    expect(infoRaw.length, 17);
    expect(opmRaw.length, 6);

    final original = OnuData(
      id: '0/1:1',
      name: 'Kantor',
      macAddress: 'FC:8E:5B:2B:66:98',
      status: 'Up',
      fwVersion: '0101',
      chipId: '9127',
      ports: '5',
      ctcStatus: 'CtcNegDone',
      ctcVer: '30',
      activate: 'Activate',
      rtt: '160',
      distance: '1',
      temperature: '46.00',
      txPower: '2.06',
      rxPower: '-17.06',
      onlineTime: '2026-06-03 10:20:22',
      offlineTime: '2026-06-03 10:19:21',
      offlineReason: 'Dying_gasp',
      uptime: '17H 15M 21S',
      deregisterCnt: '3',
    );

    final merged = original.mergeWithConfig(infoRaw: infoRaw, opmRaw: opmRaw);

    expect(merged.id, '0/1:1');
    expect(merged.name, 'Kantor');
    expect(merged.firstUpTime, '2026-04-18 08:46:47');
    expect(merged.voltage, '3.00');
    expect(merged.biasCurrent, '13.00');
    expect(merged.temperature, '47.00');
    expect(merged.txPower, '2.08');
    expect(merged.rxPower, '-17.14');
    expect(merged.uptime, '17H 56M 40S');
  });

  test('OnuData toJson and fromJson serialization/deserialization', () {
    final original = OnuData(
      id: '0/1:2',
      name: 'TestOnu',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      status: 'Up',
      fwVersion: '1.0',
      chipId: '9127',
      ports: '4',
      ctcStatus: 'CtcNegDone',
      ctcVer: '30',
      activate: 'Activate',
      rtt: '100',
      distance: '10',
      temperature: '45.0',
      txPower: '1.5',
      rxPower: '-15.0',
      onlineTime: '2026-06-03 12:00:00',
      offlineTime: '2026-06-03 11:00:00',
      offlineReason: 'Other',
      uptime: '1H 0M 0S',
      deregisterCnt: '1',
      firstUpTime: '2026-06-03 10:00:00',
      voltage: '3.3',
      biasCurrent: '12.5',
    );

    final jsonMap = original.toJson();
    final reconstructed = OnuData.fromJson(jsonMap);

    expect(reconstructed.id, original.id);
    expect(reconstructed.name, original.name);
    expect(reconstructed.macAddress, original.macAddress);
    expect(reconstructed.status, original.status);
    expect(reconstructed.fwVersion, original.fwVersion);
    expect(reconstructed.chipId, original.chipId);
    expect(reconstructed.ports, original.ports);
    expect(reconstructed.ctcStatus, original.ctcStatus);
    expect(reconstructed.ctcVer, original.ctcVer);
    expect(reconstructed.activate, original.activate);
    expect(reconstructed.rtt, original.rtt);
    expect(reconstructed.distance, original.distance);
    expect(reconstructed.temperature, original.temperature);
    expect(reconstructed.txPower, original.txPower);
    expect(reconstructed.rxPower, original.rxPower);
    expect(reconstructed.onlineTime, original.onlineTime);
    expect(reconstructed.offlineTime, original.offlineTime);
    expect(reconstructed.offlineReason, original.offlineReason);
    expect(reconstructed.uptime, original.uptime);
    expect(reconstructed.deregisterCnt, original.deregisterCnt);
    expect(reconstructed.firstUpTime, original.firstUpTime);
    expect(reconstructed.voltage, original.voltage);
    expect(reconstructed.biasCurrent, original.biasCurrent);
  });

  test('OltService fetchOnuList falls back to cache on failure', () async {

    final list = [
      OnuData(
        id: '0/1:1',
        name: 'CachedONU',
        macAddress: '11:22:33:44:55:66',
        status: 'Down',
        fwVersion: 'v1',
        chipId: '9127',
        ports: '1',
        ctcStatus: '--',
        ctcVer: '20',
        activate: 'Activate',
        rtt: '0',
        distance: '--',
        temperature: '0',
        txPower: '0',
        rxPower: '0',
        onlineTime: '',
        offlineTime: '',
        offlineReason: '',
        uptime: '',
        deregisterCnt: '0',
      ),
    ];

    // Cache the list
    await StorageService.saveOnuList('test_olt_id', list);

    // Call fetchOnuList with a bad address which will fail
    // Since cache is not empty, it should fall back and load the cached list, setting isLastLoadFromCache to true.
    OltService.isLastLoadFromCache = false;
    final result = await OltService.fetchOnuList(
      model: 'Hioso HA7304',
      url: 'http://invalid-address-that-throws.local',
      username: 'user',
      password: 'pwd',
      oltId: 'test_olt_id',
    );

    expect(OltService.isLastLoadFromCache, isTrue);
    expect(result.length, 1);
    expect(result.first.name, 'CachedONU');
    expect(result.first.macAddress, '11:22:33:44:55:66');
  });

  test(
    'OltService fetchOnuList throws exception if fetch fails and cache is empty',
    () async {
      OltService.isLastLoadFromCache = false;

      // Clear cache by retrieving (actually we just initialized with empty map)
      final cacheVal = await StorageService.getOnuList('test_olt_id_empty');
      expect(cacheVal.isEmpty, isTrue);

      expect(
        () => OltService.fetchOnuList(
          model: 'Hioso HA7304',
          url: 'http://invalid-address-that-throws.local',
          username: 'user',
          password: 'pwd',
          oltId: 'test_olt_id_empty',
        ),
        throwsA(isA<Exception>()),
      );
    },
  );
}
