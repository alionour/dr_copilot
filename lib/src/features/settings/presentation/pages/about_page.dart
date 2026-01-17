import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  PackageInfo? _packageInfo;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPackageInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                      colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // App Logo with shadow
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/icon.svg',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // App Name
                      Text(
                        'drCopilot'.tr(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Tagline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'aboutAppTagline'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_packageInfo != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'v${_packageInfo!.version}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              tabs: [
                Tab(text: 'featuresTitle'.tr()),
                Tab(text: 'creditsTitle'.tr()),
                Tab(text: 'contactTitle'.tr()),
                Tab(text: 'systemInfoTitle'.tr()),
              ],
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFeaturesTab(theme, colorScheme),
                _buildCreditsTab(theme, colorScheme),
                _buildContactTab(theme, colorScheme),
                _buildSystemTab(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(ThemeData theme, ColorScheme colorScheme) {
    final features = [
      {
        'icon': Icons.people_outline,
        'title': 'featurePatientManagement'.tr(),
        'description': 'featurePatientManagementDesc'.tr(),
        'color': Colors.blue,
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'featureAppointments'.tr(),
        'description': 'featureAppointmentsDesc'.tr(),
        'color': Colors.purple,
      },
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'featureBilling'.tr(),
        'description': 'featureBillingDesc'.tr(),
        'color': Colors.green,
      },
      {
        'icon': Icons.description_outlined,
        'title': 'featureClinicalReports'.tr(),
        'description': 'featureClinicalReportsDesc'.tr(),
        'color': Colors.orange,
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'featureAiAssistant'.tr(),
        'description': 'featureAiAssistantDesc'.tr(),
        'color': Colors.pink,
      },
      {
        'icon': Icons.chat_outlined,
        'title': 'featureTeamChat'.tr(),
        'description': 'featureTeamChatDesc'.tr(),
        'color': Colors.teal,
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'featureFinancials'.tr(),
        'description': 'featureFinancialsDesc'.tr(),
        'color': Colors.indigo,
      },
      {
        'icon': Icons.cloud_outlined,
        'title': 'featureIntegrations'.tr(),
        'description': 'featureIntegrationsDesc'.tr(),
        'color': Colors.cyan,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mission Card
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'aboutMission'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Features Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _FeatureCard(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                color: feature['color'] as Color,
                theme: theme,
                colorScheme: colorScheme,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Development Team
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.code,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'developedBy'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'developmentTeam'.tr(),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technologies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'technologiesUsed'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...[
                    {
                      'icon': Icons.flutter_dash,
                      'text': 'technologyFlutter'.tr(),
                      'color': Colors.blue,
                    },
                    {
                      'icon': Icons.whatshot,
                      'text': 'technologyFirebase'.tr(),
                      'color': Colors.orange,
                    },
                    {
                      'icon': Icons.stars,
                      'text': 'technologyGemini'.tr(),
                      'color': Colors.purple,
                    },
                    {
                      'icon': Icons.auto_awesome_outlined,
                      'text': 'technologyOpenAI'.tr(),
                      'color': Colors.green,
                    },
                    {
                      'icon': Icons.get_app_outlined,
                      'text': 'technologyClaude'.tr(),
                      'color': Colors.pink,
                    },
                    {
                      'icon': Icons.cloud_queue,
                      'text': 'technologyGoogleCloud'.tr(),
                      'color': Colors.cyan,
                    },
                  ].map(
                    (tech) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (tech['color'] as Color)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              tech['icon'] as IconData,
                              color: tech['color'] as Color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              tech['text'] as String,
                              style: theme.textTheme.bodyLarge,
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

          const SizedBox(height: 16),

          // Legal Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text('viewPrivacyPolicy'.tr()),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => context.push('/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.gavel_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text('viewTermsOfService'.tr()),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () {
                    // Add terms route if needed
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'contactEmailLabel'.tr(),
            value: 'contactEmailValue'.tr(),
            color: Colors.red,
            onTap: () async {
              final uri = Uri.parse('mailto:support@drcopilot.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _ContactCard(
            icon: Icons.language_outlined,
            title: 'contactWebsiteLabel'.tr(),
            value: 'contactWebsiteValue'.tr(),
            color: Colors.blue,
            onTap: () async {
              final uri = Uri.parse('https://www.drcopilot.com');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _ContactCard(
            icon: Icons.support_agent,
            title: 'contactSupportChat'.tr(),
            value: 'messagingSupport'.tr(),
            color: Colors.green,
            onTap: () => context.push('/support_chat'),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab(ThemeData theme, ColorScheme colorScheme) {
    if (_packageInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _SystemInfoRow(
                icon: Icons.info_outline,
                label: 'appVersionLabel'.tr(),
                value: _packageInfo!.version,
                color: Colors.blue,
                theme: theme,
              ),
              const Divider(height: 32),
              _SystemInfoRow(
                icon: Icons.tag,
                label: 'buildNumberLabel'.tr(),
                value: _packageInfo!.buildNumber,
                color: Colors.purple,
                theme: theme,
              ),
              const Divider(height: 32),
              _SystemInfoRow(
                icon: Icons.devices_other_outlined,
                label: 'platformLabel'.tr(),
                value: defaultTargetPlatform.name,
                color: Colors.orange,
                theme: theme,
              ),
              const Divider(height: 32),
              _SystemInfoRow(
                icon: Icons.vpn_key_outlined,
                label: 'App ID',
                value: _packageInfo!.packageName,
                color: Colors.green,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _SystemInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
