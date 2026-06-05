import 'package:flutter/material.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/olt_service.dart';
import 'package:oltku/screens/olt_list_view.dart';
import 'package:oltku/screens/dashboard_view.dart';
import 'package:oltku/screens/onu_list_view.dart';
import 'package:oltku/screens/map_view.dart';
import 'package:oltku/models/olt_config.dart';
import 'package:oltku/services/storage_service.dart';

class MainLayout extends StatefulWidget {
  final List<OnuData> onuList;
  final String username;
  final String password;
  final String oltUrl;
  final String oltModel;
  final String oltId;

  const MainLayout({
    super.key,
    required this.onuList,
    required this.username,
    required this.password,
    required this.oltUrl,
    required this.oltModel,
    required this.oltId,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late List<OnuData> _fullList;
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _currentFilter = "All";

  @override
  void initState() {
    super.initState();
    _fullList = List.from(widget.onuList);
  }

  Future<void> _refreshStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<OnuData> refreshed;
      refreshed = await OltService.fetchOnuList(
        model: widget.oltModel,
        url: widget.oltUrl,
        username: widget.username,
        password: widget.password,
        oltId: widget.oltId,
      );

      setState(() {
        _fullList = refreshed;
        _isLoading = false;
      });

      await StorageService.saveOnuList(widget.oltId, refreshed);

      final configs = await StorageService.getOltConfigs();
      final configIndex = configs.indexWhere((c) => c.id == widget.oltId);
      if (configIndex != -1) {
        final config = configs[configIndex];
        final updatedConfig = OltConfig(
          id: config.id,
          name: config.name,
          url: config.url,
          username: config.username,
          password: config.password,
          model: config.model,
          refreshTimeMinutes: config.refreshTimeMinutes,
          lastRefreshTime: DateTime.now().millisecondsSinceEpoch,
        );
        await StorageService.saveOltConfig(updatedConfig);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.onuUpdated),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.refreshFailed}: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Icon(Icons.dashboard_outlined, color: Color(0xFF06B6D4)),
        actions: [
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: OltService.isLastLoadFromCache
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: OltService.isLastLoadFromCache
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OltService.isLastLoadFromCache
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    OltService.isLastLoadFromCache
                        ? l10n.cachedOffline
                        : '${widget.oltModel}: ${widget.oltUrl.replaceFirst('http://', '').replaceFirst('https://', '')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: OltService.isLastLoadFromCache
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStats,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const OltListView()),
              );
            },
            tooltip: l10n.logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1B2E),
        selectedItemColor: const Color(0xFF06B6D4),
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list),
            label: l10n.onuList,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n.map,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardView(
                  onuList: _fullList,
                  oltId: widget.oltId,
                  onCardTapped: (filter) {
                    setState(() {
                      _currentFilter = filter;
                      _selectedIndex = 1;
                    });
                  },
                ),
                OnuListView(
                  onuList: _fullList,
                  oltUrl: widget.oltUrl,
                  username: widget.username,
                  password: widget.password,
                  oltModel: widget.oltModel,
                  currentFilter: _currentFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _currentFilter = filter;
                    });
                  },
                ),
                MapView(
                  oltId: widget.oltId,
                  onuList: _fullList,
                ),
              ],
            ),
    );
  }
}
