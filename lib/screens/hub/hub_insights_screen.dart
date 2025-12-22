import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/services/hub_analytics_service.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/widgets/common/home_logo_button.dart';

/// Hub Insights Dashboard - Analytics for hub managers
class HubInsightsScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubInsightsScreen({
    super.key,
    required this.hubId,
  });

  @override
  ConsumerState<HubInsightsScreen> createState() => _HubInsightsScreenState();
}

class _HubInsightsScreenState extends ConsumerState<HubInsightsScreen> {
  late Future<HubInsights> _insightsFuture;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  void _loadInsights() {
    final analyticsService = ref.read(hubAnalyticsServiceProvider);
    setState(() {
      _insightsFuture = analyticsService.getHubInsights(widget.hubId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final canPop = Navigator.of(context).canPop();

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
          leading: AppBarHomeLogo(showBackButton: canPop),
          title: const Text('Hub Insights'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    // Check permissions - only managers can access
    final roleAsync = ref.watch(hubRoleProvider(widget.hubId));

    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
              leading: AppBarHomeLogo(showBackButton: canPop),
              title: const Text('Hub Insights'),
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only hub managers can view insights',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
            leading: AppBarHomeLogo(showBackButton: canPop),
            title: const Text('Hub Insights'),
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInsights,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: FutureBuilder<HubInsights>(
            future: _insightsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing hub data...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadInsights,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final insights = snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async => _loadInsights(),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Health Status Card
                    _buildHealthStatusCard(insights),
                    const SizedBox(height: 16),

                    // Key Metrics
                    _buildMetricsGrid(insights),
                    const SizedBox(height: 16),

                    // Churn Risk
                    if (insights.churnRisk.atRiskCount > 0)
                      _buildChurnRiskCard(insights.churnRisk),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
          leading: AppBarHomeLogo(showBackButton: canPop),
          title: const Text('Hub Insights'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          leadingWidth: AppBarHomeLogo.leadingWidth(showBackButton: canPop),
          leading: AppBarHomeLogo(showBackButton: canPop),
          title: const Text('Hub Insights'),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildHealthStatusCard(HubInsights insights) {
    final (statusText, statusColor, statusIcon) = switch (insights.healthStatus) {
      HubHealthStatus.excellent => ('Excellent', Colors.green, Icons.check_circle),
      HubHealthStatus.good => ('Good', Colors.blue, Icons.thumb_up),
      HubHealthStatus.needsAttention => ('Needs Attention', Colors.orange, Icons.warning),
      HubHealthStatus.critical => ('Critical', Colors.red, Icons.error),
    };

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hub Health: $statusText',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Engagement Score: ${insights.engagementScore.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: insights.engagementScore / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(HubInsights insights) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Members',
                insights.membershipTrends.totalMembers.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Active Members',
                insights.activeMemberCount.toString(),
                Icons.person_add,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Games/Week',
                insights.gameFrequency.gamesPerWeek.toStringAsFixed(1),
                Icons.sports_soccer,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Attendance',
                insights.gameFrequency.averageAttendance.toStringAsFixed(1),
                Icons.group,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurnRiskCard(ChurnRiskAnalysis churnRisk) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Churn Risk Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${churnRisk.atRiskCount} members haven\'t been active recently',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'Consider reaching out to re-engage these members.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
