import 'package:flutter/material.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/widgets/onu_details_dialog.dart';
import 'package:oltku/models/onu_location.dart';

class OnuListView extends StatefulWidget {
  final List<OnuData> onuList;
  final String oltUrl;
  final String username;
  final String password;
  final String oltModel;
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;
  final String oltId;
  final ValueChanged<OnuLocationData>? onLocateOnu;

  const OnuListView({
    super.key,
    required this.onuList,
    required this.oltUrl,
    required this.username,
    required this.password,
    required this.oltModel,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.oltId,
    this.onLocateOnu,
  });

  @override
  State<OnuListView> createState() => _OnuListViewState();
}

class _OnuListViewState extends State<OnuListView> {
  List<OnuData> _filteredList = [];
  String _searchQuery = "";

  int? _sortColumnIndex;
  bool _sortAscending = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _displayCount = 50;

  @override
  void initState() {
    super.initState();
    _applyFilters();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  void _loadMore() {
    if (_displayCount < _filteredList.length) {
      setState(() {
        _displayCount += 50;
      });
    }
  }

  @override
  void didUpdateWidget(covariant OnuListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onuList != oldWidget.onuList ||
        widget.currentFilter != oldWidget.currentFilter) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<OnuData> get _displayedList {
    return _filteredList.take(_displayCount).toList();
  }

  void _applyFilters() {
    setState(() {
      _filteredList = widget.onuList.where((onu) {
        if (widget.currentFilter == "Online" && onu.status != "Up") {
          return false;
        }
        if (widget.currentFilter == "Offline" && onu.status == "Up") {
          return false;
        }
        if (widget.currentFilter == "Bad Rx") {
          if (onu.status != "Up") return false;
          final rx = double.tryParse(onu.rxPower);
          if (rx == null || rx > -24.0) return false;
        }

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final idMatches = onu.id.toLowerCase().contains(query);
          final nameMatches = onu.name.toLowerCase().contains(query);
          final macMatches = onu.macAddress.toLowerCase().contains(query);
          return idMatches || nameMatches || macMatches;
        }

        return true;
      }).toList();

      if (_sortColumnIndex != null) {
        _sort(_sortColumnIndex!, _sortAscending, updateState: false);
      }
      _displayCount = 50;
    });
  }

  void _sort<T>(int columnIndex, bool ascending, {bool updateState = true}) {
    int compare(OnuData a, OnuData b) {
      switch (columnIndex) {
        case 0:
          return _compareIds(a.id, b.id);
        case 1:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 2:
          return a.macAddress.compareTo(b.macAddress);
        case 3:
          return a.status.compareTo(b.status);
        case 4:
          double rxA = double.tryParse(a.rxPower) ?? -999.0;
          double rxB = double.tryParse(b.rxPower) ?? -999.0;
          return rxA.compareTo(rxB);
        case 5:
          int distA = int.tryParse(a.distance) ?? 0;
          int distB = int.tryParse(b.distance) ?? 0;
          return distA.compareTo(distB);
        case 6:
          return a.uptime.compareTo(b.uptime);
        default:
          return 0;
      }
    }

    _filteredList.sort((a, b) => ascending ? compare(a, b) : compare(b, a));

    if (updateState) {
      setState(() {
        _sortColumnIndex = columnIndex;
        _sortAscending = ascending;
      });
    }
  }

  Color _getRxColor(String rxStr, {bool isOnline = true}) {
    if (!isOnline) return Colors.white.withValues(alpha: 0.3);
    final rx = double.tryParse(rxStr);
    if (rx == null) return Colors.white;
    if (rx < -27) return Colors.red[900]!;
    if (rx <= -24) return Colors.red;
    if (rx <= -8) return Colors.green;
    return Colors.blue;
  }

  int _compareIds(String idA, String idB) {
    try {
      final partsA = idA.split('/');
      final partsB = idB.split('/');
      if (partsA.length < 2 || partsB.length < 2) return idA.compareTo(idB);

      final ponA = int.parse(partsA[0]);
      final ponB = int.parse(partsB[0]);
      if (ponA != ponB) return ponA.compareTo(ponB);

      final splitA = partsA[1].split(':');
      final splitB = partsB[1].split(':');
      if (splitA.length < 2 || splitB.length < 2) {
        return partsA[1].compareTo(partsB[1]);
      }

      final portA = int.parse(splitA[0]);
      final portB = int.parse(splitB[0]);
      if (portA != portB) return portA.compareTo(portB);

      final indexA = int.parse(splitA[1]);
      final indexB = int.parse(splitB[1]);
      return indexA.compareTo(indexB);
    } catch (_) {
      return idA.compareTo(idB);
    }
  }

  void _showOnuDetails(OnuData onu) {
    showDialog(
      context: context,
      builder: (context) => OnuDetailsDialog(
        onu: onu,
        url: widget.oltUrl,
        username: widget.username,
        password: widget.password,
        oltModel: widget.oltModel,
        oltId: widget.oltId,
        onLocate: widget.onLocateOnu,
      ),
    );
  }

  Widget _buildFilterTabs() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterChip('All', l10n.filterAll),
            _buildFilterChip('Online', l10n.filterOnline),
            _buildFilterChip('Offline', l10n.filterOffline),
            _buildFilterChip('Bad Rx', l10n.filterBadRx),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterValue, String label) {
    final isSelected = widget.currentFilter == filterValue;
    return GestureDetector(
      onTap: () {
        widget.onFilterChanged(filterValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).searchOnu,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF06B6D4),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                      _applyFilters();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    if (isWideScreen) ...[
                      const SizedBox(width: 16),
                      _buildFilterTabs(),
                    ],
                  ],
                ),
                if (!isWideScreen) ...[
                  const SizedBox(height: 12),
                  _buildFilterTabs(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${_filteredList.length} records',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isWideScreen)
                DropdownButton<int>(
                  value: _sortColumnIndex ?? 0,
                  dropdownColor: const Color(0xFF1E1B2E),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Color(0xFF06B6D4)),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Sort by ID')),
                    DropdownMenuItem(value: 1, child: Text('Sort by Name')),
                    DropdownMenuItem(value: 3, child: Text('Sort by Status')),
                    DropdownMenuItem(value: 4, child: Text('Sort by Rx Power')),
                    DropdownMenuItem(value: 5, child: Text('Sort by Distance')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _sort(val, !_sortAscending);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          isWideScreen ? _buildWideTable() : _buildMobileList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWideTable() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            showCheckboxColumn: false,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF06B6D4),
            ),
            columns: [
              DataColumn(
                label: const Text('ID/Port'),
                onSort: (index, asc) => _sort(0, asc),
              ),
              DataColumn(
                label: const Text('Name'),
                onSort: (index, asc) => _sort(1, asc),
              ),
              DataColumn(
                label: const Text('MAC Address'),
                onSort: (index, asc) => _sort(2, asc),
              ),
              DataColumn(
                label: const Text('Status'),
                onSort: (index, asc) => _sort(3, asc),
              ),
              DataColumn(
                label: const Text('Rx Power (dBm)'),
                numeric: true,
                onSort: (index, asc) => _sort(4, asc),
              ),
              DataColumn(
                label: const Text('Distance (m)'),
                numeric: true,
                onSort: (index, asc) => _sort(5, asc),
              ),
              DataColumn(
                label: const Text('Uptime'),
                onSort: (index, asc) => _sort(6, asc),
              ),
              const DataColumn(label: Text('Actions')),
            ],
            rows: _displayedList.map((onu) {
              final isOnline = onu.status == "Up";
              final statusColor = isOnline
                  ? const Color(0xFF10B981)
                  : (onu.status == "LoopDetected"
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF94A3B8));

              return DataRow(
                onSelectChanged: (_) => _showOnuDetails(onu),
                cells: [
                  DataCell(
                    Text(
                      onu.id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(onu.name)),
                  DataCell(
                    Text(
                      onu.macAddress,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        onu.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${onu.rxPower} dBm',
                      style: TextStyle(
                        color: _getRxColor(onu.rxPower, isOnline: isOnline),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text(onu.distance)),
                  DataCell(
                    Text(onu.uptime, style: const TextStyle(fontSize: 12)),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: Color(0xFF06B6D4),
                      ),
                      onPressed: () => _showOnuDetails(onu),
                      tooltip: 'View Stats',
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
          if (_displayCount < _filteredList.length)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    if (_filteredList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No records match filters',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _displayedList.length,
          itemBuilder: (context, index) {
            final onu = _displayedList[index];
            final isOnline = onu.status == "Up";
        final statusColor = isOnline
            ? const Color(0xFF10B981)
            : (onu.status == "LoopDetected"
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF94A3B8));

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _showOnuDetails(onu),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        onu.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          onu.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ID: ${onu.id}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        onu.macAddress,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(
                        'Rx Power',
                        '${onu.rxPower} dBm',
                        _getRxColor(onu.rxPower, isOnline: isOnline),
                      ),
                      _buildMiniStat(
                        'Distance',
                        '${onu.distance} m',
                        Colors.white,
                      ),
                      _buildMiniStat('Uptime', onu.uptime, Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
        if (_displayCount < _filteredList.length)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
