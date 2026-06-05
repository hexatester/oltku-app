import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/services/kmz_service.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/models/onu_data.dart';

class KmzImportExportView extends StatefulWidget {
  final String oltId;
  final List<OnuData> onuList;

  const KmzImportExportView({
    super.key,
    required this.oltId,
    required this.onuList,
  });

  @override
  State<KmzImportExportView> createState() => _KmzImportExportViewState();
}

class _KmzImportExportViewState extends State<KmzImportExportView> {
  bool _isLoading = false;

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        String filePath = result.files.single.path!;

        final counts = await KmzService.importKmz(filePath, widget.oltId);

        if (mounted) {
          final onu = counts['onu'] ?? 0;
          final odp = counts['odp'] ?? 0;
          final unknown = counts['unknown'] ?? 0;
          final total = onu + odp + unknown;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported $total items: $onu ONU markers, $odp ODPs, $unknown unknown markers.',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.importFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    try {
      final onus = await StorageService.getOnuLocations(widget.oltId);
      final odps = await StorageService.getOdps(widget.oltId);
      final unknowns = await StorageService.getUnknownMarkers(widget.oltId);

      await KmzService.exportToKmz(
        onus, odps, widget.onuList, widget.oltId,
        unknownMarkers: unknowns,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportCompleted),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kmzImportExport),
        backgroundColor: const Color(0xFF1E1B2E),
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: const Color(0xFF2D2A43),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.upload_file, size: 48, color: Color(0xFF06B6D4)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.importKmzTitle,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.importKmzHint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _handleImport,
                              icon: const Icon(Icons.file_upload),
                              label: Text(l10n.selectFile),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF06B6D4),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: const Color(0xFF2D2A43),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Icon(Icons.download, size: 48, color: Color(0xFF10B981)),
                            const SizedBox(height: 16),
                            Text(
                              l10n.exportKmzTitle,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.exportKmzHint,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _handleExport,
                              icon: const Icon(Icons.download),
                              label: Text(l10n.exportNow),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
