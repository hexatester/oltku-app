import 'package:flutter/material.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/olt_service.dart';

/// A dialog showing all 20 stats of the selected ONU, fetched dynamically from OLT configuration endpoint.
class OnuDetailsDialog extends StatefulWidget {
  final OnuData onu;
  final String url;
  final String username;
  final String password;
  final String oltModel;

  const OnuDetailsDialog({
    super.key,
    required this.onu,
    required this.url,
    required this.username,
    required this.password,
    required this.oltModel,
  });

  @override
  State<OnuDetailsDialog> createState() => _OnuDetailsDialogState();
}

class _OnuDetailsDialogState extends State<OnuDetailsDialog> {
  late Future<OnuData> _configFuture;
  bool _isRebooting = false;

  Future<void> _handleReboot(OnuData onu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Reboot ONU?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to reboot ${onu.name} (${onu.id})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Reboot', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRebooting = true);
    try {
      await OltService.rebootOnu(
        model: widget.oltModel,
        onu: onu,
        url: widget.url,
        username: widget.username,
        password: widget.password,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ONU Reboot command sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close details dialog
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reboot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRebooting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _configFuture = OltService.fetchOnuConfig(
      model: widget.oltModel,
      original: widget.onu,
      url: widget.url,
      username: widget.username,
      password: widget.password,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: FutureBuilder<OnuData>(
          future: _configFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Fetching detailed ONU stats...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 300,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load details:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final onu = snapshot.data!;
            final isOnline = onu.status == "Up";
            final statusColor = isOnline
                ? const Color(0xFF10B981)
                : (onu.status == "LoopDetected"
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF94A3B8));

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Header with name
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.router, color: statusColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              onu.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${onu.id} • MAC: ${onu.macAddress}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Details list body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Connection Health'),
                        _buildDetailsGrid([
                          _buildDetailItem(
                            'Status',
                            onu.status,
                            Icons.info_outline,
                            valueColor: statusColor,
                          ),
                          _buildDetailItem(
                            'Rx Power',
                            '${onu.rxPower} dBm',
                            Icons.settings_input_antenna,
                            valueColor: const Color(0xFF06B6D4),
                          ),
                          _buildDetailItem(
                            'Tx Power',
                            '${onu.txPower} dBm',
                            Icons.settings_input_antenna,
                          ),
                          _buildDetailItem(
                            'Temperature',
                            '${onu.temperature} °C',
                            Icons.thermostat,
                          ),
                          _buildDetailItem(
                            'Voltage',
                            onu.voltage != "--" ? '${onu.voltage} V' : '--',
                            Icons.flash_on,
                          ),
                          _buildDetailItem(
                            'Bias Current',
                            onu.biasCurrent != "--"
                                ? '${onu.biasCurrent} mA'
                                : '--',
                            Icons.waves,
                          ),
                          _buildDetailItem(
                            'Distance',
                            '${onu.distance} m',
                            Icons.straighten,
                          ),
                          _buildDetailItem('RTT', onu.rtt, Icons.timer),
                        ]),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Time & Activity'),
                        _buildDetailsGrid([
                          _buildDetailItem(
                            'Uptime',
                            onu.uptime,
                            Icons.hourglass_empty,
                          ),
                          _buildDetailItem(
                            'Deregisters',
                            onu.deregisterCnt,
                            Icons.refresh,
                          ),
                          _buildDetailItem(
                            'First UpTime',
                            onu.firstUpTime,
                            Icons.calendar_today,
                          ),
                          _buildDetailItem(
                            'Online Time',
                            onu.onlineTime,
                            Icons.login,
                          ),
                          _buildDetailItem(
                            'Offline Time',
                            onu.offlineTime,
                            Icons.logout,
                          ),
                          _buildDetailItem(
                            'Offline Reason',
                            onu.offlineReason,
                            Icons.warning_amber_rounded,
                            valueColor: onu.offlineReason == "Dying_gasp"
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Hardware & CTC Configuration'),
                        _buildDetailsGrid([
                          _buildDetailItem(
                            'FW Version',
                            onu.fwVersion,
                            Icons.code,
                          ),
                          _buildDetailItem('Chip ID', onu.chipId, Icons.memory),
                          _buildDetailItem(
                            'Ports',
                            onu.ports,
                            Icons.settings_ethernet,
                          ),
                          _buildDetailItem(
                            'CTC Status',
                            onu.ctcStatus,
                            Icons.sync,
                          ),
                          _buildDetailItem(
                            'CTC Version',
                            onu.ctcVer,
                            Icons.category,
                          ),
                          _buildDetailItem(
                            'Activation',
                            onu.activate,
                            Icons.check_circle_outline,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Footer close button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.01),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRebooting
                            ? null
                            : () => _handleReboot(onu),
                        icon: _isRebooting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.restart_alt, size: 18),
                        label: Text(_isRebooting ? 'Rebooting...' : 'Reboot'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.2),
                          foregroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          side: BorderSide(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                        ),
                        child: const Text(
                          'Close Details',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF06B6D4),
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 450 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2.2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: children,
        );
      },
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '--' : value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
