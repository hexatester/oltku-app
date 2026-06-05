import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oltku/models/odp_data.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/models/onu_location.dart';
import 'package:oltku/widgets/odp_form_dialog.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/screens/map/onu_marker_options.dart'; // For the helpers
import 'package:oltku/l10n/app_localizations.dart';

void showOdpMarkerOptions(
  BuildContext context,
  String oltId,
  OdpData odp,
  List<OnuData> onuList,
  List<OnuLocationData> savedLocations,
  VoidCallback onRefresh,
) {
  final connectedOnus = onuList
      .where(
        (onu) =>
            odp.onuIds.contains(onu.id) ||
            savedLocations.any((loc) => loc.onuId == onu.id && loc.odpId == odp.id),
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

  showDialog(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);

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
                buildStat(
                  l10n.connectedOnus,
                  '${odp.onuIds.length} / ${odp.portCount}',
                  Colors.purpleAccent,
                ),
                buildStat(
                  l10n.portsAvailable,
                  isAvailable ? l10n.yesPorts(portsAvailable) : l10n.noFull,
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
                    buildStat(
                      l10n.cableTag,
                      odp.cableName!,
                      Colors.blueAccent,
                    ),
                  if (odp.tubeColor != null)
                    buildStat(
                      l10n.tube,
                      odp.tubeColor!,
                      getFiberColor(odp.tubeColor!),
                    ),
                  if (odp.coreColor != null)
                    buildStat(
                      l10n.core,
                      odp.coreColor!,
                      getFiberColor(odp.coreColor!),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildStat(
                  l10n.avgRx,
                  avgRx != null ? '${avgRx.toStringAsFixed(1)} dBm' : 'N/A',
                  avgRx != null ? getRxColor('$avgRx dBm') : Colors.white,
                ),
                buildStat(
                  l10n.bestRx,
                  bestRx != null ? '${bestRx.toStringAsFixed(1)} dBm' : 'N/A',
                  bestRx != null ? getRxColor('$bestRx dBm') : Colors.white,
                ),
                buildStat(
                  l10n.worstRx,
                  worstRx != null
                      ? '${worstRx.toStringAsFixed(1)} dBm'
                      : 'N/A',
                  worstRx != null
                      ? getRxColor('$worstRx dBm')
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
                            oltId: oltId,
                            point: LatLng(odp.latitude, odp.longitude),
                            existingOdp: odp,
                            mappedOnus: savedLocations,
                            onuDetails: onuList,
                            onSave: (updatedOdp) async {
                              await StorageService.saveOdp(updatedOdp);
                              onRefresh();
                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      l10n.edit,
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
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await StorageService.deleteOdp(odp.id);
                      onRefresh();
                      if (context.mounted) Navigator.pop(context);
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
          ],
        ),
        ),
      );
    },
  );
}
