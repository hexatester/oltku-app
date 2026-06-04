import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';

class OdpFormDialog extends StatefulWidget {
  final String oltId;
  final LatLng point;
  final OdpData? existingOdp;
  final List<OnuLocationData> mappedOnus;
  final List<OnuData> onuDetails;
  final Function(OdpData) onSave;

  const OdpFormDialog({
    super.key,
    required this.oltId,
    required this.point,
    this.existingOdp,
    required this.mappedOnus,
    required this.onuDetails,
    required this.onSave,
  });

  @override
  State<OdpFormDialog> createState() => _OdpFormDialogState();
}

class _OdpFormDialogState extends State<OdpFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _portController;
  late TextEditingController _cableNameController;
  String? _selectedCoreColor;
  String? _selectedTubeColor;
  List<String> _selectedOnuIds = [];
  List<Map<String, dynamic>> _sortedOnus = [];

  static const List<String> _fiberColors = [
    'Blue', 'Orange', 'Green', 'Brown', 'Slate', 'White',
    'Red', 'Black', 'Yellow', 'Violet', 'Rose', 'Aqua'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingOdp?.name ?? '');
    _portController = TextEditingController(text: widget.existingOdp?.portCount.toString() ?? '8');
    _cableNameController = TextEditingController(text: widget.existingOdp?.cableName ?? '');
    _selectedCoreColor = widget.existingOdp?.coreColor;
    _selectedTubeColor = widget.existingOdp?.tubeColor;
    _selectedOnuIds = List.from(widget.existingOdp?.onuIds ?? []);

    _sortedOnus = widget.mappedOnus.map((loc) {
      final dist = Geolocator.distanceBetween(
        widget.point.latitude, 
        widget.point.longitude, 
        loc.latitude, 
        loc.longitude,
      );
      final onuName = widget.onuDetails.firstWhere(
        (o) => o.id == loc.onuId, 
        orElse: () => OnuData(id: loc.onuId, name: 'Unknown', macAddress: '', status: '', fwVersion: '', chipId: '', ports: '', ctcStatus: '', ctcVer: '', activate: '', rtt: '', distance: '', temperature: '', txPower: '', rxPower: '', onlineTime: '', offlineTime: '', offlineReason: '', uptime: '', deregisterCnt: ''),
      ).name;
      return {
        'id': loc.onuId,
        'name': onuName,
        'distance': dist,
      };
    }).toList();

    _sortedOnus.sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portController.dispose();
    _cableNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2A43),
      title: Text(widget.existingOdp == null ? 'New ODP' : 'Edit ODP', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ODP Name',
                labelStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Port Count (e.g. 8)',
                labelStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cableNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Cable Name / Tag (Optional)',
                labelStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTubeColor,
                    dropdownColor: const Color(0xFF2D2A43),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Tube Color (Optional)',
                      labelStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    items: _fiberColors.map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                    onChanged: (val) => setState(() => _selectedTubeColor = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCoreColor,
                    dropdownColor: const Color(0xFF2D2A43),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Core Color (Optional)',
                      labelStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black26,
                    ),
                    items: _fiberColors.map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                    onChanged: (val) => setState(() => _selectedCoreColor = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Assign ONUs (Sorted by nearest)', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _sortedOnus.length,
                itemBuilder: (context, index) {
                  final onuInfo = _sortedOnus[index];
                  final isSelected = _selectedOnuIds.contains(onuInfo['id']);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedOnuIds.add(onuInfo['id']);
                        } else {
                          _selectedOnuIds.remove(onuInfo['id']);
                        }
                      });
                    },
                    title: Text('${onuInfo['name']}', style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${(onuInfo['distance'] as num).toStringAsFixed(1)}m away', style: const TextStyle(color: Colors.white54)),
                    activeColor: const Color(0xFF6366F1),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          onPressed: () {
            final name = _nameController.text.trim();
            final ports = int.tryParse(_portController.text.trim()) ?? 8;
            if (name.isNotEmpty) {
              double? avgRx;
              final selectedOnuDetails = _selectedOnuIds.map((id) => widget.onuDetails.firstWhere(
                (o) => o.id == id, 
                orElse: () => OnuData(id: id, name: 'Unknown', macAddress: '', status: '', fwVersion: '', chipId: '', ports: '', ctcStatus: '', ctcVer: '', activate: '', rtt: '', distance: '', temperature: '', txPower: '', rxPower: '', onlineTime: '', offlineTime: '', offlineReason: '', uptime: '', deregisterCnt: '')
              )).toList();
              
              final rxValues = selectedOnuDetails
                  .map((onu) => double.tryParse(onu.rxPower.replaceAll(' dBm', '')))
                  .whereType<double>()
                  .toList();
                  
              if (rxValues.isNotEmpty) {
                avgRx = rxValues.reduce((a, b) => a + b) / rxValues.length;
              }

              final odp = OdpData(
                id: widget.existingOdp?.id ?? 'odp_${DateTime.now().millisecondsSinceEpoch}',
                oltId: widget.oltId,
                name: name,
                latitude: widget.point.latitude,
                longitude: widget.point.longitude,
                parentId: widget.existingOdp?.parentId,
                portCount: ports,
                cachedAvgRxPower: avgRx,
                cableName: _cableNameController.text.trim().isEmpty ? null : _cableNameController.text.trim(),
                coreColor: _selectedCoreColor,
                tubeColor: _selectedTubeColor,
                onuIds: _selectedOnuIds,
              );
              widget.onSave(odp);
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
