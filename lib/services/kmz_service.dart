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

class KmzService {
  static Future<void> exportToKmz(
    List<OnuLocationData> onus,
    List<OdpData> odps,
    List<OnuData> onuList,
    String oltId,
  ) async {
    // 1. Generate KML string
    final StringBuffer kml = StringBuffer();
    kml.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kml.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    kml.writeln('  <Document>');
    kml.writeln('    <name>OLT Export - $oltId</name>');
    
    // Add Styles
    kml.writeln('    <Style id="onuStyle">');
    kml.writeln('      <IconStyle>');
    kml.writeln('        <color>ff00ffff</color> <!-- Yellow -->');
    kml.writeln('        <scale>1.1</scale>');
    kml.writeln('        <Icon>');
    kml.writeln('          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>');
    kml.writeln('        </Icon>');
    kml.writeln('      </IconStyle>');
    kml.writeln('    </Style>');

    kml.writeln('    <Style id="odpStyle">');
    kml.writeln('      <IconStyle>');
    kml.writeln('        <color>ff0000ff</color> <!-- Red -->');
    kml.writeln('        <scale>1.3</scale>');
    kml.writeln('        <Icon>');
    kml.writeln('          <href>http://maps.google.com/mapfiles/kml/shapes/donut.png</href>');
    kml.writeln('        </Icon>');
    kml.writeln('      </IconStyle>');
    kml.writeln('    </Style>');

    kml.writeln('    <Style id="cableStyle">');
    kml.writeln('      <LineStyle>');
    kml.writeln('        <color>ffff0000</color> <!-- Blue -->');
    kml.writeln('        <width>3</width>');
    kml.writeln('      </LineStyle>');
    kml.writeln('    </Style>');

    // Add ODPs
    kml.writeln('    <Folder>');
    kml.writeln('      <name>ODPs</name>');
    for (var odp in odps) {
      kml.writeln('      <Placemark>');
      kml.writeln('        <name>${_escapeXml(odp.name)}</name>');
      kml.writeln('        <styleUrl>#odpStyle</styleUrl>');
      kml.writeln('        <Point>');
      kml.writeln('          <coordinates>${odp.longitude},${odp.latitude},0</coordinates>');
      kml.writeln('        </Point>');
      kml.writeln('      </Placemark>');
    }
    kml.writeln('    </Folder>');

    // Add ONUs
    kml.writeln('    <Folder>');
    kml.writeln('      <name>ONUs</name>');
    for (var onuLoc in onus) {
      final onuData = onuList.firstWhere(
        (o) => o.id == onuLoc.onuId,
        orElse: () => OnuData(
          id: onuLoc.onuId, name: 'Unknown', macAddress: '', status: '',
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
      kml.writeln('            Rx Power: ${onuData.rxPower}');
      kml.writeln('          ]]>');
      kml.writeln('        </description>');
      kml.writeln('        <styleUrl>#onuStyle</styleUrl>');
      kml.writeln('        <Point>');
      kml.writeln('          <coordinates>${onuLoc.longitude},${onuLoc.latitude},0</coordinates>');
      kml.writeln('        </Point>');
      kml.writeln('      </Placemark>');
    }
    kml.writeln('    </Folder>');

    // Add Cables
    kml.writeln('    <Folder>');
    kml.writeln('      <name>Cables</name>');
    for (var onuLoc in onus) {
      OdpData? assignedOdp;
      if (onuLoc.odpId != null) {
        assignedOdp = odps.where((o) => o.id == onuLoc.odpId).firstOrNull;
      } else {
        assignedOdp = odps.where((o) => o.onuIds.contains(onuLoc.onuId)).firstOrNull;
      }

      if (assignedOdp != null) {
        kml.writeln('      <Placemark>');
        kml.writeln('        <name>Cable to ${_escapeXml(assignedOdp.name)}</name>');
        kml.writeln('        <styleUrl>#cableStyle</styleUrl>');
        kml.writeln('        <LineString>');
        kml.writeln('          <tessellate>1</tessellate>');
        kml.writeln('          <coordinates>');
        
        kml.writeln('            ${onuLoc.longitude},${onuLoc.latitude},0');
        if (onuLoc.cablePath != null && onuLoc.cablePath!.isNotEmpty) {
          for (var pt in onuLoc.cablePath!) {
            kml.writeln('            ${pt['longitude']},${pt['latitude']},0');
          }
        }
        kml.writeln('            ${assignedOdp.longitude},${assignedOdp.latitude},0');
        
        kml.writeln('          </coordinates>');
        kml.writeln('        </LineString>');
        kml.writeln('      </Placemark>');
      }
    }
    kml.writeln('    </Folder>');

    kml.writeln('  </Document>');
    kml.writeln('</kml>');

    // 2. Create KMZ (Zip)
    final archive = Archive();
    final kmlBytes = utf8.encode(kml.toString());
    archive.addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));
    
    final kmzBytes = ZipEncoder().encode(archive);
    
    if (kmzBytes != null) {
      // 3. Share / Save File
      final xFile = XFile.fromData(
        Uint8List.fromList(kmzBytes),
        name: 'map_export_$oltId.kmz',
        mimeType: 'application/vnd.google-earth.kmz',
      );
      
      await Share.shareXFiles([xFile], text: 'Exported KMZ for OLT $oltId');
    }
  }

  static Future<int> importKmz(String filePath, String oltId) async {
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
      throw Exception('No KML file found or parsed from the provided file.');
    }
    
    final document = XmlDocument.parse(kmlString);
    final placemarks = document.findAllElements('Placemark');
    
    int importedCount = 0;
    
    for (var placemark in placemarks) {
      final nameNode = placemark.findElements('name').firstOrNull;
      final name = nameNode?.innerText ?? 'Imported Marker';
      
      final descNode = placemark.findElements('description').firstOrNull;
      final desc = descNode?.innerText;
      
      final pointNode = placemark.findAllElements('Point').firstOrNull;
      if (pointNode != null) {
        final coordNode = pointNode.findElements('coordinates').firstOrNull;
        if (coordNode != null) {
          final coords = coordNode.innerText.trim().split(',');
          if (coords.length >= 2) {
            final lng = double.tryParse(coords[0].trim());
            final lat = double.tryParse(coords[1].trim());
            
            if (lat != null && lng != null) {
              final id = 'marker_${DateTime.now().millisecondsSinceEpoch}_$importedCount';
              final marker = UnknownMarkerData(
                id: id,
                oltId: oltId,
                name: name,
                latitude: lat,
                longitude: lng,
                description: desc,
              );
              await StorageService.saveUnknownMarker(marker);
              importedCount++;
            }
          }
        }
      }
    }
    
    return importedCount;
  }

  static String _escapeXml(String xmlString) {
    return xmlString
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
