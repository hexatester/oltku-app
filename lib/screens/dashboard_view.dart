import 'package:flutter/material.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/olt_service.dart';
import 'package:oltku/screens/kmz_import_export_view.dart';
import 'package:oltku/screens/activation_view.dart';

class DashboardView extends StatelessWidget {
  final List<OnuData> onuList;
  final Function(String) onCardTapped;
  final String oltId;
  final String oltModel;
  final String? oltSubmodel;

  const DashboardView({
    super.key,
    required this.onuList,
    required this.onCardTapped,
    required this.oltId,
    required this.oltModel,
    this.oltSubmodel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final int totalOnus = onuList.length;
    final int onlineOnus = onuList.where((onu) => onu.status == "Up").length;
    final int offlineOnus = totalOnus - onlineOnus;
    final int badRxOnus = onuList.where((onu) {
      if (onu.status != "Up") return false;
      final rx = double.tryParse(onu.rxPower);
      return rx != null && rx <= -24.0;
    }).length;
    final double onlineRatio = totalOnus > 0
        ? (onlineOnus / totalOnus) * 100
        : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (OltService.isLastLoadFromCache) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.oltUnreachable,
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.cachedDataHint,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Stats Metrics row
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth =
                  (constraints.maxWidth - 40) /
                  (constraints.maxWidth > 1000
                      ? 5
                      : constraints.maxWidth > 800
                      ? 3
                      : 2);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  GestureDetector(
                    onTap: () => onCardTapped('All'),
                    child: _buildMetricCard(
                      title: l10n.totalOnus,
                      value: '$totalOnus',
                      icon: Icons.router,
                      gradientColors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF4F46E5),
                      ],
                      width: cardWidth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onCardTapped('Online'),
                    child: _buildMetricCard(
                      title: l10n.onlineOnus,
                      value: '$onlineOnus',
                      icon: Icons.wifi_tethering,
                      gradientColors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                      width: cardWidth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onCardTapped('Offline'),
                    child: _buildMetricCard(
                      title: l10n.offlineOnus,
                      value: '$offlineOnus',
                      icon: Icons.wifi_tethering_off,
                      gradientColors: [
                        const Color(0xFFEF4444),
                        const Color(0xFFDC2626),
                      ],
                      width: cardWidth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onCardTapped('Online'),
                    child: _buildMetricCard(
                      title: l10n.onlineRatio,
                      value: '${onlineRatio.toStringAsFixed(1)}%',
                      icon: Icons.percent,
                      gradientColors: [
                        const Color(0xFF06B6D4),
                        const Color(0xFF0891B2),
                      ],
                      width: cardWidth,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onCardTapped('Bad Rx'),
                    child: _buildMetricCard(
                      title: l10n.badRx,
                      value: '$badRxOnus',
                      icon: Icons.warning_amber_rounded,
                      gradientColors: [
                        const Color(0xFFF59E0B),
                        const Color(0xFFD97706),
                      ],
                      width: cardWidth,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Activate ONU Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivationView(
                    oltModel: oltModel,
                    oltSubmodel: oltSubmodel,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activate ONU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Register and provision a new ONU device on this OLT.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // KMZ Import/Export Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KmzImportExportView(
                    oltId: oltId,
                    onuList: onuList,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.import_export, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.kmzImportExport,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.kmzImportExportHint,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 70,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
