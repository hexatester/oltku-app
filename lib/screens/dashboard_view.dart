import 'package:flutter/material.dart';
import 'package:oltku/models/onu_data.dart';
import 'package:oltku/services/olt_service.dart';

class DashboardView extends StatelessWidget {
  final List<OnuData> onuList;
  final Function(String) onCardTapped;

  const DashboardView({
    super.key,
    required this.onuList,
    required this.onCardTapped,
  });

  @override
  Widget build(BuildContext context) {
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
                        const Text(
                          'OLT Unreachable - Offline Mode',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Showing cached data from the last successful connection. Please check your network.',
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
                      title: 'Total ONUs',
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
                      title: 'Online (Up)',
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
                      title: 'Offline (Down)',
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
                      title: 'Online Ratio',
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
                      title: 'Bad Rx (<= -24)',
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
