import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide ClusterManager, Cluster;
import 'package:geolocator/geolocator.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/widgets/odp_form_dialog.dart';

class MapItem with ClusterItem {
  final String id;
  final bool isOnu;
  final LatLng latLng;
  final dynamic data;
  final dynamic locationData;

  MapItem({
    required this.id,
    required this.isOnu,
    required this.latLng,
    required this.data,
    this.locationData,
  });

  @override
  LatLng get location => latLng;
}

class MapView extends StatefulWidget {
  final String oltId;
  final List<OnuData> onuList;

  const MapView({super.key, required this.oltId, required this.onuList});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  late ClusterManager _manager;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  List<OnuLocationData> _savedLocations = [];
  List<OdpData> _savedOdps = [];
  bool _isLoading = true;
  OltConfig? _oltConfig;

  final Map<String, IconData> _availableIcons = {
    'router': Icons.router,
    'device_hub': Icons.device_hub,
    'wifi': Icons.wifi,
    'home': Icons.home,
    'business': Icons.business,
    'cell_tower': Icons.cell_tower,
    'hub': Icons.hub,
    'settings_input_antenna': Icons.settings_input_antenna,
    'account_tree': Icons.account_tree,
    'location_on': Icons.location_on,
  };

  final Map<String, BitmapDescriptor> _iconCache = {};

  Color _getRxColor(String rxStr, {bool isOnline = true}) {
    if (!isOnline) return Colors.grey;
    final rxValue = double.tryParse(rxStr.replaceAll(' dBm', ''));
    if (rxValue == null) return Colors.grey;

    if (rxValue < -27) return Colors.red[900]!;
    if (rxValue <= -24) return Colors.red;
    if (rxValue <= -8) return Colors.green;
    return Colors.blue;
  }

  Color _getFiberColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'brown':
        return Colors.brown;
      case 'slate':
        return Colors.blueGrey;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'black':
        return Colors.grey; // Grey for visibility on dark bg
      case 'yellow':
        return Colors.yellow;
      case 'violet':
        return Colors.purple;
      case 'rose':
        return Colors.pinkAccent;
      case 'aqua':
        return Colors.cyan;
      case 'transparent':
        return Colors.white30;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();
    _manager = ClusterManager<MapItem>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
    _initMap();
  }

  Future<void> _initMap() async {
    _oltConfig = await StorageService.getOltConfig(widget.oltId);
    await _loadSavedLocations();
    await _getCurrentLocation();
  }

  Future<BitmapDescriptor> _getCachedIconBitmap(IconData iconData, Color color, {double size = 100.0}) async {
    final String cacheKey = '${iconData.codePoint}_${color.toARGB32()}';
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final TextPainter shadowPainter = TextPainter(textDirection: TextDirection.ltr);
    shadowPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.black.withValues(alpha: 0.5),
      ),
    );
    shadowPainter.layout();
    shadowPainter.paint(canvas, const Offset(2.0, 2.0));

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(0.0, 0.0));

    final img = await pictureRecorder.endRecording().toImage(size.toInt() + 4, size.toInt() + 4);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = BitmapDescriptor.bytes(data!.buffer.asUint8List());
    
    _iconCache[cacheKey] = bitmap;
    return bitmap;
  }

  Future<void> _loadSavedLocations() async {
    final locations = await StorageService.getOnuLocations(widget.oltId);
    final odps = await StorageService.getOdps(widget.oltId);
    if (mounted) {
      setState(() {
        _savedLocations = locations;
        _savedOdps = odps;
      });
      _updateManagerItems();
    }
  }

  void _updateManagerItems() {
    List<MapItem> items = [];
    for (var loc in _savedLocations) {
      final onu = widget.onuList.firstWhere(
        (o) => o.id == loc.onuId,
        orElse: () => OnuData(
          id: loc.onuId,
          name: 'Unknown',
          macAddress: '',
          status: '',
          fwVersion: '',
          chipId: '',
          ports: '',
          ctcStatus: '',
          ctcVer: '',
          activate: '',
          rtt: '',
          distance: '',
          temperature: '',
          txPower: '',
          rxPower: '',
          onlineTime: '',
          offlineTime: '',
          offlineReason: '',
          uptime: '',
          deregisterCnt: '',
        ),
      );
      items.add(
        MapItem(
          id: 'onu_${loc.onuId}',
          isOnu: true,
          latLng: LatLng(loc.latitude, loc.longitude),
          data: onu,
          locationData: loc,
        ),
      );
    }
    for (var odp in _savedOdps) {
      items.add(
        MapItem(
          id: 'odp_${odp.id}',
          isOnu: false,
          latLng: LatLng(odp.latitude, odp.longitude),
          data: odp,
        ),
      );
    }
    _manager.setItems(items);
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<Marker> _markerBuilder(Cluster<MapItem> cluster) async {
    if (!cluster.isMultiple) {
      final item = cluster.items.first;
      if (item.isOnu) {
        final onu = item.data as OnuData;
        final loc = item.locationData as OnuLocationData;
        final isOnline = onu.status == "Up";
        final color = _getRxColor(onu.rxPower, isOnline: isOnline);
        
        final iconName = _oltConfig?.onuIcon ?? 'router';
        final iconData = _availableIcons[iconName] ?? Icons.router;
        final customIcon = await _getCachedIconBitmap(iconData, color);

        return Marker(
          markerId: MarkerId('onu_${loc.onuId}'),
          position: cluster.location,
          draggable: true,
          icon: customIcon,
          onTap: () => _showMarkerOptions(onu, loc),
          onDragEnd: (newPosition) async {
            final newLocation = OnuLocationData(
              oltId: widget.oltId,
              onuId: onu.id,
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
              cableName: loc.cableName,
              cableLength: loc.cableLength,
              coreColor: loc.coreColor,
              tubeColor: loc.tubeColor,
            );
            await StorageService.saveOnuLocation(newLocation);
            await _loadSavedLocations();
          },
        );
      } else {
        final odp = item.data as OdpData;
        final color = odp.cachedAvgRxPower != null
            ? _getRxColor('${odp.cachedAvgRxPower} dBm')
            : Colors.purple;
            
        final iconName = _oltConfig?.odpIcon ?? 'device_hub';
        final iconData = _availableIcons[iconName] ?? Icons.device_hub;
        final customIcon = await _getCachedIconBitmap(iconData, color);

        return Marker(
          markerId: MarkerId('odp_${odp.id}'),
          position: cluster.location,
          draggable: true,
          icon: customIcon,
          onTap: () => _showOdpOptions(odp),
          onDragEnd: (newPosition) async {
            final newOdp = OdpData(
              id: odp.id,
              oltId: odp.oltId,
              name: odp.name,
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
              parentId: odp.parentId,
              portCount: odp.portCount,
              cachedAvgRxPower: odp.cachedAvgRxPower,
              cableName: odp.cableName,
              coreColor: odp.coreColor,
              tubeColor: odp.tubeColor,
              onuIds: odp.onuIds,
            );
            await StorageService.saveOdp(newOdp);
            await _loadSavedLocations();
          },
        );
      }
    }

    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            cluster.location,
            _currentLocation != null ? 16.0 : 16.0,
          ), // fallback
        );
      },
      icon: await _getClusterBitmap(
        cluster.isMultiple ? 100 : 50,
        text: cluster.count.toString(),
      ),
    );
  }

  Future<BitmapDescriptor> _getClusterBitmap(int size, {String? text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint1 = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.8);
    final Paint paint2 = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.2, paint2);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.8, paint1);

    if (text != null) {
      TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size / 3,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleMapLongPress(LatLng point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2A43),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_location, color: Colors.white),
                title: const Text(
                  'Add Onu Marker',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAssignOnuDialog(point);
                },
              ),
              ListTile(
                leading: const Icon(Icons.device_hub, color: Colors.white),
                title: const Text(
                  'Add Odp Marker',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateOdpDialog(point);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateOdpDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        return OdpFormDialog(
          oltId: widget.oltId,
          point: point,
          mappedOnus: _savedLocations,
          onuDetails: widget.onuList,
          onSave: (odp) async {
            await StorageService.saveOdp(odp);
            await _loadSavedLocations();
            if (context.mounted) Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showOdpOptions(OdpData odp) {
    final connectedOnus = odp.onuIds
        .map(
          (id) => widget.onuList.firstWhere(
            (o) => o.id == id,
            orElse: () => OnuData(
              id: id,
              name: 'Unknown',
              macAddress: '',
              status: '',
              fwVersion: '',
              chipId: '',
              ports: '',
              ctcStatus: '',
              ctcVer: '',
              activate: '',
              rtt: '',
              distance: '',
              temperature: '',
              txPower: '',
              rxPower: '',
              onlineTime: '',
              offlineTime: '',
              offlineReason: '',
              uptime: '',
              deregisterCnt: '',
            ),
          ),
        )
        .toList();

    final rxValues = connectedOnus
        .map((onu) => double.tryParse(onu.rxPower.replaceAll(' dBm', '')))
        .whereType<double>()
        .toList();
    double? avgRx;
    double? bestRx;
    double? worstRx;
    if (rxValues.isNotEmpty) {
      avgRx = rxValues.reduce((a, b) => a + b) / rxValues.length;
      bestRx = rxValues.reduce((a, b) => a > b ? a : b);
      worstRx = rxValues.reduce((a, b) => a < b ? a : b);
    }

    final portsAvailable = odp.portCount - odp.onuIds.length;
    final isAvailable = portsAvailable > 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                odp.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    'Connected ONUs',
                    '${odp.onuIds.length} / ${odp.portCount}',
                    Colors.purpleAccent,
                  ),
                  _buildStat(
                    'Ports Available',
                    isAvailable ? 'Yes ($portsAvailable)' : 'No (Full)',
                    isAvailable ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (odp.cableName != null ||
                  odp.tubeColor != null ||
                  odp.coreColor != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (odp.cableName != null)
                      _buildStat(
                        'Cable Tag',
                        odp.cableName!,
                        Colors.blueAccent,
                      ),
                    if (odp.tubeColor != null)
                      _buildStat(
                        'Tube',
                        odp.tubeColor!,
                        _getFiberColor(odp.tubeColor!),
                      ),
                    if (odp.coreColor != null)
                      _buildStat(
                        'Core',
                        odp.coreColor!,
                        _getFiberColor(odp.coreColor!),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat(
                    'Avg Rx',
                    avgRx != null ? '${avgRx.toStringAsFixed(1)} dBm' : 'N/A',
                    avgRx != null ? _getRxColor('$avgRx dBm') : Colors.white,
                  ),
                  _buildStat(
                    'Best Rx',
                    bestRx != null ? '${bestRx.toStringAsFixed(1)} dBm' : 'N/A',
                    bestRx != null
                        ? _getRxColor('$bestRx dBm')
                        : Colors.white,
                  ),
                  _buildStat(
                    'Worst Rx',
                    worstRx != null
                        ? '${worstRx.toStringAsFixed(1)} dBm'
                        : 'N/A',
                    worstRx != null
                        ? _getRxColor('$worstRx dBm')
                        : Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) {
                            return OdpFormDialog(
                              oltId: widget.oltId,
                              point: LatLng(odp.latitude, odp.longitude),
                              existingOdp: odp,
                              mappedOnus: _savedLocations,
                              onuDetails: widget.onuList,
                              onSave: (updatedOdp) async {
                                await StorageService.saveOdp(updatedOdp);
                                await _loadSavedLocations();
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await StorageService.deleteOdp(odp.id);
                        await _loadSavedLocations();
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssignOnuDialog(LatLng point, {OnuLocationData? existingLocation}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _AssignOnuDialog(
              point: point,
              onuList: widget.onuList,
              existingLocation: existingLocation,
              onAssign:
                  (onuId, cableName, cableLength, coreColor, tubeColor) async {
                    final location = OnuLocationData(
                      oltId: widget.oltId,
                      onuId: onuId,
                      latitude: point.latitude,
                      longitude: point.longitude,
                      cableName: cableName,
                      cableLength: cableLength,
                      coreColor: coreColor,
                      tubeColor: tubeColor,
                    );
                    await StorageService.saveOnuLocation(location);
                    await _loadSavedLocations();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            ),
          ),
        );
      },
    );
  }

  void _showMarkerOptions(OnuData onu, OnuLocationData loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      builder: (context) {
        final isOnline = onu.status == "Up";
        final statusColor = isOnline
            ? const Color(0xFF10B981)
            : (onu.status == "LoopDetected"
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF94A3B8));

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                onu.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                onu.macAddress,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('Status', onu.status, statusColor),
                  _buildStat(
                    'Rx Power',
                    '${onu.rxPower} dBm',
                    _getRxColor(onu.rxPower, isOnline: isOnline),
                  ),
                  _buildStat('Distance', '${onu.distance} m', Colors.white),
                ],
              ),
              const SizedBox(height: 12),
              if (loc.cableName != null ||
                  loc.tubeColor != null ||
                  loc.coreColor != null ||
                  loc.cableLength != null) ...[
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    if (loc.cableName != null)
                      _buildStat(
                        'Cable Tag',
                        loc.cableName!,
                        Colors.blueAccent,
                      ),
                    if (loc.cableLength != null)
                      _buildStat('Length', '${loc.cableLength}m', Colors.white),
                    if (loc.tubeColor != null)
                      _buildStat(
                        'Tube',
                        loc.tubeColor!,
                        _getFiberColor(loc.tubeColor!),
                      ),
                    if (loc.coreColor != null)
                      _buildStat(
                        'Core',
                        loc.coreColor!,
                        _getFiberColor(loc.coreColor!),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // close popup
                        _showAssignOnuDialog(
                          LatLng(loc.latitude, loc.longitude),
                          existingLocation: loc,
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Edit Marker',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await StorageService.deleteOnuLocation(
                          widget.oltId,
                          onu.id,
                        );
                        await _loadSavedLocations();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        _manager.setMapId(controller.mapId);
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation ?? const LatLng(0, 0),
        zoom: 15.0,
      ),
      onCameraMove: _manager.onCameraMove,
      onCameraIdle: _manager.updateMap,
      onLongPress: _handleMapLongPress,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
    );
  }
}

class _AssignOnuDialog extends StatefulWidget {
  final LatLng point;
  final List<OnuData> onuList;
  final Function(String, String?, String?, String?, String?) onAssign;
  final OnuLocationData? existingLocation;

  const _AssignOnuDialog({
    required this.point,
    required this.onuList,
    required this.onAssign,
    this.existingLocation,
  });

  @override
  State<_AssignOnuDialog> createState() => _AssignOnuDialogState();
}

class _AssignOnuDialogState extends State<_AssignOnuDialog> {
  String _searchQuery = '';
  String? _selectedOnuId;
  late TextEditingController _cableNameController;
  late TextEditingController _cableLengthController;
  String? _selectedCoreColor;
  String? _selectedTubeColor;

  static const List<String> _fiberColors = [
    'Transparent',
    'Blue',
    'Orange',
    'Green',
    'Brown',
    'Slate',
    'White',
    'Red',
    'Black',
    'Yellow',
    'Violet',
    'Rose',
    'Aqua',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOnuId = widget.existingLocation?.onuId;
    _cableNameController = TextEditingController(
      text: widget.existingLocation?.cableName ?? '',
    );
    _cableLengthController = TextEditingController(
      text: widget.existingLocation?.cableLength ?? '',
    );
    _selectedCoreColor = widget.existingLocation?.coreColor;
    _selectedTubeColor = widget.existingLocation?.tubeColor;
  }

  @override
  void dispose() {
    _cableNameController.dispose();
    _cableLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedOnuId != null) {
      final onu = widget.onuList.firstWhere((o) => o.id == _selectedOnuId!);
      return Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Details for ${onu.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cableNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cable Name (Optional)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cableLengthController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Cable Length in meters (Optional)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTubeColor,
                      dropdownColor: const Color(0xFF2D2A43),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tube Color (Optional)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _fiberColors
                          .where((c) => c != 'Transparent')
                          .map(
                            (color) => DropdownMenuItem(
                              value: color,
                              child: Text(color),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedTubeColor = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCoreColor,
                      dropdownColor: const Color(0xFF2D2A43),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Core Color (Optional)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _fiberColors
                          .map(
                            (color) => DropdownMenuItem(
                              value: color,
                              child: Text(color),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCoreColor = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (widget.existingLocation != null) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _selectedOnuId = null);
                      }
                    },
                    child: Text(
                      widget.existingLocation != null ? 'Cancel' : 'Back',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onAssign(
                        _selectedOnuId!,
                        _cableNameController.text.trim().isEmpty
                            ? null
                            : _cableNameController.text.trim(),
                        _cableLengthController.text.trim().isEmpty
                            ? null
                            : _cableLengthController.text.trim(),
                        _selectedCoreColor,
                        _selectedTubeColor,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final filteredList = widget.onuList.where((onu) {
      final query = _searchQuery.toLowerCase();
      return onu.name.toLowerCase().contains(query) ||
          onu.macAddress.toLowerCase().contains(query) ||
          onu.id.toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign Location to ONU',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lat: ${widget.point.latitude.toStringAsFixed(4)}, Lng: ${widget.point.longitude.toStringAsFixed(4)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search ONU...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final onu = filteredList[index];
                return ListTile(
                  title: Text(
                    onu.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    onu.macAddress,
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(
                    Icons.add_location,
                    color: Color(0xFF6366F1),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedOnuId = onu.id;
                      _cableNameController.clear();
                      _cableLengthController.clear();
                      _selectedCoreColor = null;
                      _selectedTubeColor = null;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
