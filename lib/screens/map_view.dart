import 'package:flutter/material.dart';
import 'package:oltku/screens/map/onu_marker_options.dart';
import 'package:oltku/screens/map/odp_marker_options.dart';
import 'package:oltku/screens/map/cable_edit_overlay.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/widgets/odp_form_dialog.dart';
import 'package:oltku/models/unknown_marker_data.dart';
import 'package:oltku/l10n/app_localizations.dart';

class MapView extends StatefulWidget {
  final String oltId;
  final List<OnuData> onuList;
  final OnuLocationData? focusLocation;

  const MapView({super.key, required this.oltId, required this.onuList, this.focusLocation});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  List<OnuLocationData> _savedLocations = [];
  List<OdpData> _savedOdps = [];
  List<UnknownMarkerData> _unknownMarkers = [];
  bool _isLoading = true;
  OltConfig? _oltConfig;
  MapType _mapType = MapType.normal;
  CameraPosition? _lastCameraPosition;

  bool _isEditingCable = false;
  OnuLocationData? _editingOnuLocation;
  List<LatLng> _editingCablePoints = [];

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

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  @override
  void didUpdateWidget(covariant MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusLocation != oldWidget.focusLocation && widget.focusLocation != null) {
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(widget.focusLocation!.latitude, widget.focusLocation!.longitude),
            18.0,
          ),
        );
      }
    }
  }

  Future<void> _initMap() async {
    _oltConfig = await StorageService.getOltConfig(widget.oltId);
    await _loadSavedLocations();
    
    if (_oltConfig?.lastMapLatitude != null && _oltConfig?.lastMapLongitude != null) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(_oltConfig!.lastMapLatitude!, _oltConfig!.lastMapLongitude!);
          _isLoading = false;
        });
      }
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _saveCurrentMapPosition(CameraPosition position) async {
    if (_oltConfig == null) return;
    
    final updatedConfig = OltConfig(
      id: _oltConfig!.id,
      name: _oltConfig!.name,
      url: _oltConfig!.url,
      username: _oltConfig!.username,
      password: _oltConfig!.password,
      model: _oltConfig!.model,
      refreshTimeMinutes: _oltConfig!.refreshTimeMinutes,
      lastRefreshTime: _oltConfig!.lastRefreshTime,
      onuIcon: _oltConfig!.onuIcon,
      odpIcon: _oltConfig!.odpIcon,
      markerSize: _oltConfig!.markerSize,
      lastMapLatitude: position.target.latitude,
      lastMapLongitude: position.target.longitude,
      lastMapZoom: position.zoom,
    );
    
    await StorageService.saveOltConfig(updatedConfig);
    _oltConfig = updatedConfig;
  }

  Future<BitmapDescriptor> _getCachedIconBitmap(
    IconData iconData,
    Color color, {
    double size = 100.0,
    String? label,
  }) async {
    final String cacheKey = '${iconData.codePoint}_${color.toARGB32()}_$label';
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final TextPainter shadowPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
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

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
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

    TextPainter? labelPainter;
    TextPainter? labelShadowPainter;
    double labelHeight = 0;
    double labelWidth = 0;

    if (label != null && label.isNotEmpty) {
      labelShadowPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      labelShadowPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: size * 0.4,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      );
      labelShadowPainter.layout();

      labelPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );
      labelPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: size * 0.4,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      labelPainter.layout();

      labelHeight = labelPainter.height;
      labelWidth = labelPainter.width;
    }

    final double width = (size > labelWidth ? size : labelWidth) + 4;
    final double height = size + labelHeight * 2 + 4;

    final double iconX = (width - size) / 2;
    shadowPainter.paint(canvas, Offset(iconX + 2.0, labelHeight + 2.0));
    textPainter.paint(canvas, Offset(iconX, labelHeight));

    if (label != null && label.isNotEmpty) {
      final double labelX = (width - labelWidth) / 2;
      labelShadowPainter!.paint(canvas, Offset(labelX + 1.0, labelHeight + size + 1.0));
      labelPainter!.paint(canvas, Offset(labelX, labelHeight + size));
    }

    final img = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bitmap = BitmapDescriptor.bytes(data!.buffer.asUint8List());

    _iconCache[cacheKey] = bitmap;
    return bitmap;
  }

  Future<void> _loadSavedLocations() async {
    final locations = await StorageService.getOnuLocations(widget.oltId);
    final odps = await StorageService.getOdps(widget.oltId);
    final unknowns = await StorageService.getUnknownMarkers(widget.oltId);
    if (mounted) {
      setState(() {
        _savedLocations = locations;
        _savedOdps = odps;
        _unknownMarkers = unknowns;
      });
      await _updateMarkersDirectly();
    }
  }

  Future<void> _updateMarkersDirectly() async {
    Set<Marker> newMarkers = {};

    Set<Polyline> newPolylines = {};

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

      final isOnline = onu.status == "Up";
      final color = _getRxColor(onu.rxPower, isOnline: isOnline);

      final iconName = loc.icon ?? _oltConfig?.onuIcon ?? 'router';
      final iconData = _availableIcons[iconName] ?? Icons.router;
      final customIcon = await _getCachedIconBitmap(
        iconData,
        color,
        size: _oltConfig?.markerSize ?? 20.0,
        label: onu.name,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId('onu_${loc.onuId}'),
          position: LatLng(loc.latitude, loc.longitude),
          anchor: const Offset(0.5, 0.5),
          draggable: true,
          icon: customIcon,
          onTap: () => showOnuMarkerOptions(context, widget.oltId, onu, loc, _savedOdps, _loadSavedLocations, _enterCableEditMode, widget.onuList, _savedLocations),
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
              odpId: loc.odpId,
              cablePath: loc.cablePath,
            );
            await StorageService.saveOnuLocation(newLocation);
            await _loadSavedLocations();
          },
        ),
      );

      // Create polyline if assigned to an ODP
      if (_isEditingCable && _editingOnuLocation?.onuId == loc.onuId) {
        // Render draggable anchor points
        for (int i = 0; i < _editingCablePoints.length; i++) {
          newMarkers.add(Marker(
            markerId: MarkerId('edit_anchor_$i'),
            position: _editingCablePoints[i],
            draggable: true,
            anchor: const Offset(0.5, 0.5),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            onTap: () {
              setState(() {
                _editingCablePoints.removeAt(i);
              });
              _updateMarkersDirectly();
            },
            onDragEnd: (newPosition) {
              setState(() {
                _editingCablePoints[i] = newPosition;
              });
              _updateMarkersDirectly();
            },
          ));
        }

        // Generate polyline based on _editingCablePoints
        OdpData? assignedOdp;
        if (loc.odpId != null) {
          assignedOdp = _savedOdps.where((o) => o.id == loc.odpId).firstOrNull;
        } else {
          assignedOdp = _savedOdps.where((o) => o.onuIds.contains(loc.onuId)).firstOrNull;
        }
        
        if (assignedOdp != null) {
          List<LatLng> points = [
            LatLng(loc.latitude, loc.longitude),
            ..._editingCablePoints,
            LatLng(assignedOdp.latitude, assignedOdp.longitude),
          ];

          newPolylines.add(Polyline(
            polylineId: PolylineId('line_${loc.onuId}_${assignedOdp.id}'),
            points: points,
            color: color,
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
          ));
        }
      } else {
        OdpData? assignedOdp;
        if (loc.odpId != null) {
          assignedOdp = _savedOdps.where((o) => o.id == loc.odpId).firstOrNull;
        } else {
          assignedOdp = _savedOdps.where((o) => o.onuIds.contains(loc.onuId)).firstOrNull;
        }
        
        if (assignedOdp != null) {
          List<LatLng> points = [];
          if (loc.cablePath != null && loc.cablePath!.isNotEmpty) {
            points.add(LatLng(loc.latitude, loc.longitude));
            for (var pt in loc.cablePath!) {
              points.add(LatLng(pt['latitude']!, pt['longitude']!));
            }
            points.add(LatLng(assignedOdp.latitude, assignedOdp.longitude));
          } else {
            points = [
              LatLng(loc.latitude, loc.longitude),
              LatLng(assignedOdp.latitude, assignedOdp.longitude),
            ];
          }

          newPolylines.add(Polyline(
            polylineId: PolylineId('line_${loc.onuId}_${assignedOdp.id}'),
            points: points,
            color: color,
            width: 3,
            patterns: [PatternItem.dash(10), PatternItem.gap(10)],
          ));
        }
      }
    }

    for (var odp in _savedOdps) {
      final color = odp.cachedAvgRxPower != null
          ? _getRxColor('${odp.cachedAvgRxPower} dBm')
          : Colors.purple;

      final iconName = _oltConfig?.odpIcon ?? 'device_hub';
      final iconData = _availableIcons[iconName] ?? Icons.device_hub;
      final customIcon = await _getCachedIconBitmap(
        iconData,
        color,
        size: _oltConfig?.markerSize ?? 25.0,
        label: odp.name,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId('odp_${odp.id}'),
          position: LatLng(odp.latitude, odp.longitude),
          anchor: const Offset(0.5, 0.5),
          draggable: true,
          icon: customIcon,
          onTap: () => showOdpMarkerOptions(context, widget.oltId, odp, widget.onuList, _savedLocations, _loadSavedLocations),
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
        ),
      );
    }

    for (var unknown in _unknownMarkers) {
      newMarkers.add(
        Marker(
          markerId: MarkerId('unknown_${unknown.id}'),
          position: LatLng(unknown.latitude, unknown.longitude),
          anchor: const Offset(0.5, 0.5),
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
          onTap: () => _showUnknownMarkerOptions(unknown),
          onDragEnd: (newPosition) async {
            final updatedMarker = UnknownMarkerData(
              id: unknown.id,
              oltId: unknown.oltId,
              name: unknown.name,
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
              description: unknown.description,
            );
            await StorageService.saveUnknownMarker(updatedMarker);
            await _loadSavedLocations();
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _polylines = newPolylines;
      });
    }
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
                title: Text(
                  AppLocalizations.of(context).addOnuMarker,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showAssignOnuDialog(context, widget.oltId, point, widget.onuList, _savedLocations, _loadSavedLocations);
                },
              ),
              ListTile(
                leading: const Icon(Icons.device_hub, color: Colors.white),
                title: Text(
                  AppLocalizations.of(context).addOdpMarker,
                  style: const TextStyle(color: Colors.white),
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

  void _showUnknownMarkerOptions(UnknownMarkerData unknown) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2A43),
          title: Text(unknown.name, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unknown.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(unknown.description!, style: const TextStyle(color: Colors.white70)),
                ),
              ListTile(
                leading: const Icon(Icons.router, color: Colors.blue),
                title: Text(AppLocalizations.of(context).assignAsOnu, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  showAssignOnuDialog(context, widget.oltId, LatLng(unknown.latitude, unknown.longitude), widget.onuList, _savedLocations, () async {
                    await StorageService.deleteUnknownMarker(unknown.id);
                    await _loadSavedLocations();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.device_hub, color: Colors.purple),
                title: Text(AppLocalizations.of(context).assignAsOdp, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return OdpFormDialog(
                        oltId: widget.oltId,
                        point: LatLng(unknown.latitude, unknown.longitude),
                        mappedOnus: _savedLocations,
                        onuDetails: widget.onuList,
                        onSave: (odp) async {
                          final updatedOdp = OdpData(
                            id: odp.id, oltId: odp.oltId, name: unknown.name, // Use the marker's name
                            latitude: odp.latitude, longitude: odp.longitude,
                            parentId: odp.parentId, portCount: odp.portCount,
                            cableName: odp.cableName, coreColor: odp.coreColor, tubeColor: odp.tubeColor, onuIds: odp.onuIds,
                          );
                          await StorageService.saveOdp(updatedOdp);
                          await StorageService.deleteUnknownMarker(unknown.id);
                          await _loadSavedLocations();
                          if (context.mounted) Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(AppLocalizations.of(context).deleteMarker, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await StorageService.deleteUnknownMarker(unknown.id);
                  await _loadSavedLocations();
                },
              ),
            ],
          ),
        );
      },
    );
  }





  void _enterCableEditMode(OnuLocationData loc) {
    setState(() {
      _isEditingCable = true;
      _editingOnuLocation = loc;
      _editingCablePoints = [];
      if (loc.cablePath != null && loc.cablePath!.isNotEmpty) {
        for (var pt in loc.cablePath!) {
          _editingCablePoints.add(LatLng(pt['latitude']!, pt['longitude']!));
        }
      } else {
        // Find assigned ODP to create a midpoint
        OdpData? assignedOdp;
        if (loc.odpId != null) {
          assignedOdp = _savedOdps.where((o) => o.id == loc.odpId).firstOrNull;
        } else {
          assignedOdp = _savedOdps.where((o) => o.onuIds.contains(loc.onuId)).firstOrNull;
        }
        if (assignedOdp != null) {
          _editingCablePoints.add(LatLng(
            (loc.latitude + assignedOdp.latitude) / 2,
            (loc.longitude + assignedOdp.longitude) / 2,
          ));
        }
      }
    });
    _updateMarkersDirectly();
  }

  Future<void> _saveCableRoute() async {
    if (_editingOnuLocation != null) {
      final updatedLocation = OnuLocationData(
        oltId: _editingOnuLocation!.oltId,
        onuId: _editingOnuLocation!.onuId,
        latitude: _editingOnuLocation!.latitude,
        longitude: _editingOnuLocation!.longitude,
        cableName: _editingOnuLocation!.cableName,
        cableLength: _editingOnuLocation!.cableLength,
        coreColor: _editingOnuLocation!.coreColor,
        tubeColor: _editingOnuLocation!.tubeColor,
        odpId: _editingOnuLocation!.odpId,
        cablePath: _editingCablePoints
            .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
            .toList(),
      );
      await StorageService.saveOnuLocation(updatedLocation);
    }
    _cancelCableEdit();
    await _loadSavedLocations();
  }

  void _cancelCableEdit() {
    setState(() {
      _isEditingCable = false;
      _editingOnuLocation = null;
      _editingCablePoints = [];
    });
    _updateMarkersDirectly();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _mapType,
            onMapCreated: (controller) {
              _mapController = controller;
              if (widget.focusLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(widget.focusLocation!.latitude, widget.focusLocation!.longitude),
                    18.0,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: _oltConfig?.lastMapZoom ?? 15.0,
            ),
            onCameraMove: (position) {
              _lastCameraPosition = position;
            },
            onCameraIdle: () {
              if (_lastCameraPosition != null) {
                _saveCurrentMapPosition(_lastCameraPosition!);
              }
            },
            onTap: (point) {
              if (_isEditingCable) {
                setState(() {
                  _editingCablePoints.add(point);
                });
                _updateMarkersDirectly();
              }
            },
            onLongPress: _handleMapLongPress,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 32,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D2A43),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Toggle Map Type',
                    onPressed: () {
                      setState(() {
                        _mapType = _mapType == MapType.normal
                            ? MapType.satellite
                            : MapType.normal;
                      });
                    },
                    icon: Icon(
                      _mapType == MapType.normal ? Icons.satellite : Icons.map,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white24,
                  ),
                  IconButton(
                    tooltip: 'Reload',
                    onPressed: () async {
                      await _loadSavedLocations();
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isEditingCable)
            CableEditOverlay(onCancel: _cancelCableEdit, onSave: _saveCableRoute),
        ],
      ),
    );
  }
}

