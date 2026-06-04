import 'package:flutter/material.dart';
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
          url: fullUrl,
          username: config.username,
          password: config.password,
          oltId: config.id,
        );

        // Save to local database
        await StorageService.saveOnuList(config.id, onus);
        final updatedConfig = OltConfig(
          id: config.id,
          name: config.name,
          url: config.url,
          username: config.username,
          password: config.password,
          model: config.model,
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
              oltId: config.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            content: Text('Connection Error: $e'),
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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Delete OLT?'),
        content: Text('Are you sure you want to delete ${config.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.deleteOltConfig(config.id);
      _loadConfigs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text(
          'Saved OLTs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _configs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.router_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No OLTs Saved Yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the + button to add a new connection.',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
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
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
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
                                      config.name.isNotEmpty ? config.name : 'Unnamed OLT',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      config.url,
                                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        config.model,
                                        style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
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
