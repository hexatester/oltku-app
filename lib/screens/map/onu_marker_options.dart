import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/l10n/app_localizations.dart';

Widget buildStat(String label, String value, Color valueColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

Color getFiberColor(String colorName) {
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
      return Colors.grey;
    case 'white':
      return Colors.white;
    case 'red':
      return Colors.red;
    case 'black':
      return Colors.black;
    case 'yellow':
      return Colors.yellow;
    case 'violet':
      return Colors.purple;
    case 'rose':
      return Colors.pink;
    case 'aqua':
      return Colors.cyan;
    default:
      return Colors.white;
  }
}

Color getRxColor(String rxPowerStr, {bool isOnline = true}) {
  if (!isOnline) return Colors.grey;
  try {
    final parts = rxPowerStr.split(' ');
    if (parts.isEmpty) return Colors.green;
    final power = double.parse(parts[0]);
    if (power < -27.0) return Colors.red;
    if (power < -25.0) return Colors.orange;
    return Colors.green;
  } catch (e) {
    return Colors.green;
  }
}

void showAssignOnuDialog(
  BuildContext context,
  String oltId,
  LatLng point,
  List<OnuData> onuList,
  List<OnuLocationData> savedLocations,
  VoidCallback onSaved, {
  OnuLocationData? existingLocation,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: AssignOnuDialogWidget(
              point: point,
              onuList: onuList,
              savedLocations: savedLocations,
              existingLocation: existingLocation,
              onAssign:
                  (onuId, cableName, cableLength, coreColor, tubeColor) async {
                    final location = OnuLocationData(
                      oltId: oltId,
                      onuId: onuId,
                      latitude: point.latitude,
                      longitude: point.longitude,
                      cableName: cableName,
                      cableLength: cableLength,
                      coreColor: coreColor,
                      tubeColor: tubeColor,
                      odpId: existingLocation?.odpId,
                      cablePath: existingLocation?.cablePath,
                    );
                    await StorageService.saveOnuLocation(location);
                    onSaved();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            ),
          ),
        ),
      );
    },
  );
}

void showOnuMarkerOptions(
  BuildContext context,
  String oltId,
  OnuData onu,
  OnuLocationData loc,
  List<OdpData> savedOdps,
  VoidCallback onRefresh,
  Function(OnuLocationData) onEditCable,
  List<OnuData> onuList,
  List<OnuLocationData> savedLocations,
) {
  showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);

      final isOnline = onu.status == "Up";
      final statusColor = isOnline
          ? const Color(0xFF10B981)
          : (onu.status == "LoopDetected"
                ? const Color(0xFFF59E0B)
                : const Color(0xFF94A3B8));

      return Dialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
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
                  buildStat(l10n.status, onu.status, statusColor),
                  buildStat(
                    l10n.rxPower,
                    '${onu.rxPower} dBm',
                    getRxColor(onu.rxPower, isOnline: isOnline),
                  ),
                  buildStat(l10n.distance, '${onu.distance} m', Colors.white),
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
                      buildStat(
                        l10n.cableTag,
                        loc.cableName!,
                        Colors.blueAccent,
                      ),
                    if (loc.cableLength != null)
                      buildStat(
                        l10n.length,
                        '${loc.cableLength}m',
                        Colors.white,
                      ),
                    if (loc.tubeColor != null)
                      buildStat(
                        l10n.tube,
                        loc.tubeColor!,
                        getFiberColor(loc.tubeColor!),
                      ),
                    if (loc.coreColor != null)
                      buildStat(
                        l10n.core,
                        loc.coreColor!,
                        getFiberColor(loc.coreColor!),
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
                        showAssignOnuDialog(
                          context,
                          oltId,
                          LatLng(loc.latitude, loc.longitude),
                          onuList,
                          savedLocations,
                          onRefresh,
                          existingLocation: loc,
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        l10n.editMarker,
                        style: const TextStyle(
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
                        await StorageService.deleteOnuLocation(oltId, onu.id);
                        onRefresh();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        l10n.delete,
                        style: const TextStyle(
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
              if (loc.odpId != null ||
                  savedOdps.any((o) => o.onuIds.contains(onu.id))) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEditCable(loc);
                    },
                    icon: const Icon(Icons.route, color: Colors.white),
                    label: Text(
                      l10n.editCableRoute,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class AssignOnuDialogWidget extends StatefulWidget {
  final LatLng point;
  final List<OnuData> onuList;
  final List<OnuLocationData> savedLocations;
  final Function(String, String?, String?, String?, String?) onAssign;
  final OnuLocationData? existingLocation;

  const AssignOnuDialogWidget({
    super.key,
    required this.point,
    required this.onuList,
    required this.savedLocations,
    required this.onAssign,
    this.existingLocation,
  });

  @override
  State<AssignOnuDialogWidget> createState() => _AssignOnuDialogWidgetState();
}

class _AssignOnuDialogWidgetState extends State<AssignOnuDialogWidget> {
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
    final l10n = AppLocalizations.of(context);

    if (_selectedOnuId != null) {
      final onu = widget.onuList.firstWhere((o) => o.id == _selectedOnuId!);
      return Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.detailsFor(onu.name),
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
                  labelText: l10n.cableNameOptional,
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
                  labelText: l10n.cableLengthOptional,
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
                        labelText: l10n.tubeColorOptional,
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
                        labelText: l10n.coreColorOptional,
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
                      widget.existingLocation != null ? l10n.cancel : l10n.back,
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
                    child: Text(
                      l10n.save,
                      style: const TextStyle(color: Colors.white),
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

    filteredList.sort((a, b) {
      final aHasLoc = widget.savedLocations.any((loc) => loc.onuId == a.id);
      final bHasLoc = widget.savedLocations.any((loc) => loc.onuId == b.id);
      if (aHasLoc && !bHasLoc) return 1;
      if (!aHasLoc && bHasLoc) return -1;
      return 0; // maintain original order for same category
    });

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.assignLocationToOnu,
            style: const TextStyle(
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
              hintText: l10n.searchOnu,
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
                  trailing: Icon(
                    Icons.add_location,
                    color:
                        widget.savedLocations.any((loc) => loc.onuId == onu.id)
                        ? Colors.grey
                        : const Color(0xFF6366F1),
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
