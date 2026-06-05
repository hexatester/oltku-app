import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/models/unknown_marker_data.dart';
import 'package:oltku/services/storage_service.dart';

/// Placemark type tags embedded in ExtendedData for import disambiguation
const _typeOnu = 'OLTKU_ONU';
const _typeOdp = 'OLTKU_ODP';
const _typeUnknown = 'OLTKU_UNKNOWN';

class KmzService {
  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------
  static Future<void> exportToKmz(
    List<OnuLocationData> onus,
    List<OdpData> odps,
    List<OnuData> onuList,
    String oltId, {
    List<UnknownMarkerData>? unknownMarkers,
  }) async {
    final StringBuffer kml = StringBuffer();
    kml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kml.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    kml.writeln('  <Document>');
    kml.writeln('    <name>OLTKU Export - $oltId</name>');

    // ── Styles ───────────────────────────────────────────────────────────────
    kml.writeln('    <Style id="onuStyle">');
    kml.writeln('      <IconStyle>');
    kml.writeln('        <color>ff00ffff</color>');
    kml.writeln('        <scale>1.1</scale>');
    kml.writeln('        <Icon>');
    kml.writeln('          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>');
    kml.writeln('        </Icon>');
    kml.writeln('      </IconStyle>');
    kml.writeln('    </Style>');

    kml.writeln('    <Style id="odpStyle">');
    kml.writeln('      <IconStyle>');
    kml.writeln('        <color>ff0000ff</color>');
    kml.writeln('        <scale>1.3</scale>');
    kml.writeln('        <Icon>');
    kml.writeln('          <href>http://maps.google.com/mapfiles/kml/shapes/donut.png</href>');
    kml.writeln('        </Icon>');
    kml.writeln('      </IconStyle>');
    kml.writeln('    </Style>');

    kml.writeln('    <Style id="unknownStyle">');
    kml.writeln('      <IconStyle>');
    kml.writeln('        <color>ffff00ff</color>');
    kml.writeln('        <scale>1.0</scale>');
    kml.writeln('      </IconStyle>');
    kml.writeln('    </Style>');

    kml.writeln('    <Style id="cableStyle">');
    kml.writeln('      <LineStyle>');
    kml.writeln('        <color>ffff0000</color>');
    kml.writeln('        <width>3</width>');
    kml.writeln('      </LineStyle>');
    kml.writeln('    </Style>');

    // ── ODP Folder ───────────────────────────────────────────────────────────
    kml.writeln('    <Folder>');
    kml.writeln('      <name>ODPs</name>');
    for (var odp in odps) {
      kml.writeln('      <Placemark>');
      kml.writeln('        <name>${_escapeXml(odp.name)}</name>');
      kml.writeln('        <description><![CDATA[${_escapeXml(odp.name)} - ODP]]></description>');
      kml.writeln('        <styleUrl>#odpStyle</styleUrl>');
      // ExtendedData: all ODP fields
      kml.writeln('        <ExtendedData>');
      _writeData(kml, 'type', _typeOdp);
      _writeData(kml, 'id', odp.id);
      _writeData(kml, 'oltId', odp.oltId);
      _writeData(kml, 'name', odp.name);
      _writeData(kml, 'portCount', odp.portCount.toString());
      if (odp.parentId != null) _writeData(kml, 'parentId', odp.parentId!);
      if (odp.cableName != null) _writeData(kml, 'cableName', odp.cableName!);
      if (odp.coreColor != null) _writeData(kml, 'coreColor', odp.coreColor!);
      if (odp.tubeColor != null) _writeData(kml, 'tubeColor', odp.tubeColor!);
      if (odp.onuIds.isNotEmpty) _writeData(kml, 'onuIds', jsonEncode(odp.onuIds));
      kml.writeln('        </ExtendedData>');
      kml.writeln('        <Point>');
      kml.writeln('          <coordinates>${odp.longitude},${odp.latitude},0</coordinates>');
      kml.writeln('        </Point>');
      kml.writeln('      </Placemark>');
    }
    kml.writeln('    </Folder>');

    // ── ONU Folder ───────────────────────────────────────────────────────────
    kml.writeln('    <Folder>');
    kml.writeln('      <name>ONUs</name>');
    for (var loc in onus) {
      final onuData = onuList.firstWhere(
        (o) => o.id == loc.onuId,
        orElse: () => OnuData(
          id: loc.onuId, name: 'Unknown', macAddress: '', status: '',
          fwVersion: '', chipId: '', ports: '', ctcStatus: '', ctcVer: '',
          activate: '', rtt: '', distance: '', temperature: '', txPower: '',
          rxPower: '', onlineTime: '', offlineTime: '', offlineReason: '',
          uptime: '', deregisterCnt: '',
        ),
      );

      kml.writeln('      <Placemark>');
      kml.writeln('        <name>${_escapeXml(onuData.name)}</name>');
      kml.writeln('        <description>');
      kml.writeln('          <![CDATA[');
      kml.writeln('            MAC: ${onuData.macAddress}<br/>');
      kml.writeln('            Status: ${onuData.status}<br/>');
      kml.writeln('            Rx Power: ${onuData.rxPower} dBm<br/>');
      kml.writeln('            Uptime: ${onuData.uptime}');
      kml.writeln('          ]]>');
      kml.writeln('        </description>');
      kml.writeln('        <styleUrl>#onuStyle</styleUrl>');
      // ExtendedData: all ONU location & live data fields
      kml.writeln('        <ExtendedData>');
      _writeData(kml, 'type', _typeOnu);
      _writeData(kml, 'onuId', loc.onuId);
      _writeData(kml, 'oltId', loc.oltId);
      // ONU live data
      _writeData(kml, 'onuName', onuData.name);
      _writeData(kml, 'macAddress', onuData.macAddress);
      _writeData(kml, 'status', onuData.status);
      _writeData(kml, 'rxPower', onuData.rxPower);
      _writeData(kml, 'txPower', onuData.txPower);
      _writeData(kml, 'distance', onuData.distance);
      _writeData(kml, 'uptime', onuData.uptime);
      _writeData(kml, 'fwVersion', onuData.fwVersion);
      // ONU location-specific fields
      if (loc.cableName != null) _writeData(kml, 'cableName', loc.cableName!);
      if (loc.cableLength != null) _writeData(kml, 'cableLength', loc.cableLength!);
      if (loc.coreColor != null) _writeData(kml, 'coreColor', loc.coreColor!);
      if (loc.tubeColor != null) _writeData(kml, 'tubeColor', loc.tubeColor!);
      if (loc.odpId != null) _writeData(kml, 'odpId', loc.odpId!);
      if (loc.icon != null) _writeData(kml, 'icon', loc.icon!);
      if (loc.cablePath != null && loc.cablePath!.isNotEmpty) {
        _writeData(kml, 'cablePath', jsonEncode(loc.cablePath));
      }
      kml.writeln('        </ExtendedData>');
      kml.writeln('        <Point>');
      kml.writeln('          <coordinates>${loc.longitude},${loc.latitude},0</coordinates>');
      kml.writeln('        </Point>');
      kml.writeln('      </Placemark>');
    }
    kml.writeln('    </Folder>');

    // ── Unknown Markers Folder ────────────────────────────────────────────────
    if (unknownMarkers != null && unknownMarkers.isNotEmpty) {
      kml.writeln('    <Folder>');
      kml.writeln('      <name>Unknown Markers</name>');
      for (var marker in unknownMarkers) {
        kml.writeln('      <Placemark>');
        kml.writeln('        <name>${_escapeXml(marker.name)}</name>');
        if (marker.description != null) {
          kml.writeln('        <description><![CDATA[${_escapeXml(marker.description!)}]]></description>');
        }
        kml.writeln('        <styleUrl>#unknownStyle</styleUrl>');
        kml.writeln('        <ExtendedData>');
        _writeData(kml, 'type', _typeUnknown);
        _writeData(kml, 'id', marker.id);
        _writeData(kml, 'oltId', marker.oltId);
        _writeData(kml, 'name', marker.name);
        if (marker.description != null) _writeData(kml, 'description', marker.description!);
        kml.writeln('        </ExtendedData>');
        kml.writeln('        <Point>');
        kml.writeln('          <coordinates>${marker.longitude},${marker.latitude},0</coordinates>');
        kml.writeln('        </Point>');
        kml.writeln('      </Placemark>');
      }
      kml.writeln('    </Folder>');
    }

    // ── Cable Routes Folder ───────────────────────────────────────────────────
    kml.writeln('    <Folder>');
    kml.writeln('      <name>Cables</name>');
    for (var loc in onus) {
      OdpData? assignedOdp;
      if (loc.odpId != null) {
        assignedOdp = odps.where((o) => o.id == loc.odpId).firstOrNull;
      } else {
        assignedOdp = odps.where((o) => o.onuIds.contains(loc.onuId)).firstOrNull;
      }
      if (assignedOdp == null) continue;

      final onuName = onuList.firstWhere((o) => o.id == loc.onuId,
          orElse: () => OnuData(id: loc.onuId, name: loc.onuId, macAddress: '', status: '', fwVersion: '', chipId: '', ports: '', ctcStatus: '', ctcVer: '', activate: '', rtt: '', distance: '', temperature: '', txPower: '', rxPower: '', onlineTime: '', offlineTime: '', offlineReason: '', uptime: '', deregisterCnt: '')).name;

      kml.writeln('      <Placemark>');
      kml.writeln('        <name>Cable: ${_escapeXml(onuName)} → ${_escapeXml(assignedOdp.name)}</name>');
      kml.writeln('        <styleUrl>#cableStyle</styleUrl>');
      kml.writeln('        <ExtendedData>');
      _writeData(kml, 'type', 'OLTKU_CABLE');
      _writeData(kml, 'onuId', loc.onuId);
      _writeData(kml, 'odpId', assignedOdp.id);
      if (loc.cableName != null) _writeData(kml, 'cableName', loc.cableName!);
      if (loc.cableLength != null) _writeData(kml, 'cableLength', loc.cableLength!);
      if (loc.coreColor != null) _writeData(kml, 'coreColor', loc.coreColor!);
      if (loc.tubeColor != null) _writeData(kml, 'tubeColor', loc.tubeColor!);
      kml.writeln('        </ExtendedData>');
      kml.writeln('        <LineString>');
      kml.writeln('          <tessellate>1</tessellate>');
      kml.writeln('          <coordinates>');
      kml.writeln('            ${loc.longitude},${loc.latitude},0');
      if (loc.cablePath != null && loc.cablePath!.isNotEmpty) {
        for (var pt in loc.cablePath!) {
          kml.writeln('            ${pt['longitude']},${pt['latitude']},0');
        }
      }
      kml.writeln('            ${assignedOdp.longitude},${assignedOdp.latitude},0');
      kml.writeln('          </coordinates>');
      kml.writeln('        </LineString>');
      kml.writeln('      </Placemark>');
    }
    kml.writeln('    </Folder>');

    kml.writeln('  </Document>');
    kml.writeln('</kml>');

    // Pack as KMZ
    final archive = Archive();
    final kmlBytes = utf8.encode(kml.toString());
    archive.addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));
    final kmzBytes = ZipEncoder().encode(archive);

    if (kmzBytes != null) {
      final xFile = XFile.fromData(
        Uint8List.fromList(kmzBytes),
        name: 'oltku_export_$oltId.kmz',
        mimeType: 'application/vnd.google-earth.kmz',
      );
      await Share.shareXFiles([xFile], text: 'OLTKU Export for OLT $oltId');
    }
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------
  /// Returns a map of imported counts per category.
  static Future<Map<String, int>> importKmz(String filePath, String oltId) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    String kmlString = '';
    if (filePath.toLowerCase().endsWith('.kmz') || filePath.toLowerCase().endsWith('.zip')) {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final archiveFile in archive) {
        if (archiveFile.isFile && archiveFile.name.toLowerCase().endsWith('.kml')) {
          kmlString = utf8.decode(archiveFile.content as List<int>);
          break;
        }
      }
    } else if (filePath.toLowerCase().endsWith('.kml')) {
      kmlString = utf8.decode(bytes);
    }

    if (kmlString.isEmpty) {
      throw Exception('No KML file found in the provided file.');
    }

    final document = XmlDocument.parse(kmlString);
    final placemarks = document.findAllElements('Placemark');

    int onuCount = 0;
    int odpCount = 0;
    int unknownCount = 0;

    for (var placemark in placemarks) {
      final ext = _parseExtendedData(placemark);
      final type = ext['type'];

      // Read coordinates from Point (if present)
      double? lat, lng;
      final pointNode = placemark.findAllElements('Point').firstOrNull;
      if (pointNode != null) {
        final coordNode = pointNode.findElements('coordinates').firstOrNull;
        if (coordNode != null) {
          final parts = coordNode.innerText.trim().split(',');
          if (parts.length >= 2) {
            lng = double.tryParse(parts[0].trim());
            lat = double.tryParse(parts[1].trim());
          }
        }
      }

      if (type == _typeOnu && lat != null && lng != null) {
        // Restore full OnuLocationData
        List<Map<String, double>>? cablePath;
        if (ext['cablePath'] != null) {
          try {
            final raw = jsonDecode(ext['cablePath']!) as List<dynamic>;
            cablePath = raw.map((e) => Map<String, double>.from(e)).toList();
          } catch (_) {}
        }

        final location = OnuLocationData(
          oltId: ext['oltId'] ?? oltId,
          onuId: ext['onuId'] ?? '',
          latitude: lat,
          longitude: lng,
          cableName: ext['cableName'],
          cableLength: ext['cableLength'],
          coreColor: ext['coreColor'],
          tubeColor: ext['tubeColor'],
          odpId: ext['odpId'],
          icon: ext['icon'],
          cablePath: cablePath,
        );

        if (location.onuId.isNotEmpty) {
          await StorageService.saveOnuLocation(location);
          onuCount++;
        }
      } else if (type == _typeOdp && lat != null && lng != null) {
        // Restore full OdpData
        List<String> onuIds = [];
        if (ext['onuIds'] != null) {
          try {
            onuIds = List<String>.from(jsonDecode(ext['onuIds']!));
          } catch (_) {}
        }

        final nameNode = placemark.findElements('name').firstOrNull;
        final odp = OdpData(
          id: ext['id'] ?? 'odp_${DateTime.now().millisecondsSinceEpoch}_$odpCount',
          oltId: ext['oltId'] ?? oltId,
          name: ext['name'] ?? nameNode?.innerText ?? 'Imported ODP',
          latitude: lat,
          longitude: lng,
          parentId: ext['parentId'],
          portCount: int.tryParse(ext['portCount'] ?? '') ?? 8,
          cableName: ext['cableName'],
          coreColor: ext['coreColor'],
          tubeColor: ext['tubeColor'],
          onuIds: onuIds,
        );

        await StorageService.saveOdp(odp);
        odpCount++;
      } else if (type == _typeUnknown && lat != null && lng != null) {
        final nameNode = placemark.findElements('name').firstOrNull;
        final marker = UnknownMarkerData(
          id: ext['id'] ?? 'marker_${DateTime.now().millisecondsSinceEpoch}_$unknownCount',
          oltId: ext['oltId'] ?? oltId,
          name: ext['name'] ?? nameNode?.innerText ?? 'Imported Marker',
          latitude: lat,
          longitude: lng,
          description: ext['description'],
        );
        await StorageService.saveUnknownMarker(marker);
        unknownCount++;
      } else if (type == null && lat != null && lng != null) {
        // Fallback: treat untagged Point placemarks as unknown markers
        final nameNode = placemark.findElements('name').firstOrNull;
        final descNode = placemark.findElements('description').firstOrNull;
        final id = 'marker_${DateTime.now().millisecondsSinceEpoch}_$unknownCount';
        final marker = UnknownMarkerData(
          id: id,
          oltId: oltId,
          name: nameNode?.innerText ?? 'Imported Marker',
          latitude: lat,
          longitude: lng,
          description: descNode?.innerText,
        );
        await StorageService.saveUnknownMarker(marker);
        unknownCount++;
      }
    }

    return {
      'onu': onuCount,
      'odp': odpCount,
      'unknown': unknownCount,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Writes a KML <Data> element into the buffer.
  static void _writeData(StringBuffer buf, String name, String value) {
    buf.writeln('          <Data name="${_escapeXml(name)}">');
    buf.writeln('            <value>${_escapeXml(value)}</value>');
    buf.writeln('          </Data>');
  }

  /// Parses all <Data> children of the nearest <ExtendedData> element in [placemark].
  static Map<String, String> _parseExtendedData(XmlElement placemark) {
    final result = <String, String>{};
    final extNode = placemark.findElements('ExtendedData').firstOrNull;
    if (extNode == null) return result;
    for (var dataNode in extNode.findElements('Data')) {
      final name = dataNode.getAttribute('name');
      final value = dataNode.findElements('value').firstOrNull?.innerText;
      if (name != null && value != null) {
        result[name] = value;
      }
    }
    return result;
  }

  static String _escapeXml(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
