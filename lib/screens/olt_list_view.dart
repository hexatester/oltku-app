import 'package:flutter/material.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/main.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/services/storage_service.dart';
import 'package:oltku/services/olt_service.dart';
import 'package:oltku/screens/olt_edit_view.dart';
import 'package:oltku/screens/main_layout.dart';
import 'package:oltku/models/onu_data.dart';

class OltListView extends StatefulWidget {
  const OltListView({super.key});

  @override
  State<OltListView> createState() => _OltListViewState();
}

class _OltListViewState extends State<OltListView> {
  List<OltConfig> _configs = [];
  bool _isLoading = true;
  String? _connectingId;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await StorageService.getOltConfigs();
    setState(() {
      _configs = configs;
      _isLoading = false;
    });
  }

  Future<void> _connectToOlt(OltConfig config) async {
    setState(() {
      _connectingId = config.id;
    });

    try {
      String fullUrl = config.url.trim();
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        fullUrl = 'http://$fullUrl';
      }
      if (fullUrl.endsWith('/')) {
        fullUrl = fullUrl.substring(0, fullUrl.length - 1);
      }

      final savedOnus = await StorageService.getOnuList(config.id);
      final int refreshTimeMs = config.refreshTimeMinutes * 60 * 1000;
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      bool isCacheValid = false;
      if (config.lastRefreshTime != null && savedOnus.isNotEmpty) {
        if (now - config.lastRefreshTime! < refreshTimeMs) {
          isCacheValid = true;
        }
      }

      List<OnuData> onus = [];
      if (isCacheValid) {
        onus = savedOnus;
      } else {
        onus = await OltService.fetchOnuList(
          model: config.model,
          submodel: config.submodel,
          url: fullUrl,
          username: config.username,
          password: config.password,
          oltId: config.id,
        );

        await StorageService.saveOnuList(config.id, onus);
        final updatedConfig = OltConfig(
          id: config.id,
          name: config.name,
          url: config.url,
          username: config.username,
          password: config.password,
          model: config.model,
          submodel: config.submodel,
          refreshTimeMinutes: config.refreshTimeMinutes,
          lastRefreshTime: now,
        );
        await StorageService.saveOltConfig(updatedConfig);
        _loadConfigs();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainLayout(
              onuList: onus,
              username: config.username,
              password: config.password,
              oltUrl: fullUrl,
              oltModel: config.model,
              oltSubmodel: config.submodel,
              oltId: config.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            content: Text('${l10n.connectionError}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _connectingId = null;
        });
      }
    }
  }

  Future<void> _deleteConfig(OltConfig config) async {
    final l10n = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: Text(l10n.deleteOltTitle),
        content: Text(l10n.deleteOltConfirm(config.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteOltConfig(config.id);
      _loadConfigs();
    }
  }

  void _showLanguageMenu() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.languageLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                _LanguageOption(
                  flag: '🇮🇩',
                  label: 'Bahasa Indonesia',
                  locale: const Locale('id'),
                ),
                _LanguageOption(
                  flag: '🇬🇧',
                  label: 'English',
                  locale: const Locale('en'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.languageLabel,
          onPressed: _showLanguageMenu,
          icon: const Icon(Icons.language, color: Colors.white),
        ),
        title: Text(
          l10n.savedOlts,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _configs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.router_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noOltSaved,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noOltHint,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _configs.length,
                  itemBuilder: (context, index) {
                    final config = _configs[index];
                    final isConnecting = _connectingId == config.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: isConnecting ? null : () => _connectToOlt(config),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.router, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.name.isNotEmpty ? config.name : l10n.unnamedOlt,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      config.url,
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        config.submodel != null
                                            ? '${config.model} · ${config.submodel}'
                                            : config.model,
                                        style: const TextStyle(
                                          color: Color(0xFF06B6D4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              if (isConnecting)
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white54),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => OltEditView(existingConfig: config)),
                                        ).then((_) => _loadConfigs());
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                      onPressed: () => _deleteConfig(config),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OltEditView()),
          ).then((_) => _loadConfigs());
        },
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// A single language option tile in the language picker bottom sheet.
class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final Locale locale;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = appLocale.value.languageCode == locale.languageCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF06B6D4))
          : null,
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
    );
  }
}
