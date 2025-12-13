import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
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
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                      colorScheme.tertiary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Support Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'helpSupport'.tr(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'supportDescription'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              tabs: [
                Tab(text: 'faq'.tr()),
                Tab(text: 'contactTitle'.tr()),
                Tab(text: 'userGuide'.tr()),
              ],
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFAQTab(theme, colorScheme),
                _buildContactTab(theme, colorScheme),
                _buildResourcesTab(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTab(ThemeData theme, ColorScheme colorScheme) {
    final faqs = [
      {'question': 'faqInviteStaff'.tr(), 'answer': 'faqInviteStaffAns'.tr()},
      {
        'question': 'faqFreePlanLimits'.tr(),
        'answer': 'faqFreePlanLimitsAns'.tr(),
      },
      {'question': 'faqExportData'.tr(), 'answer': 'faqExportDataAns'.tr()},
      {'question': 'faqSwitchAI'.tr(), 'answer': 'faqSwitchAIAns'.tr()},
      {'question': 'faqCreateReport'.tr(), 'answer': 'faqCreateReportAns'.tr()},
      {
        'question': 'faqManageSubscription'.tr(),
        'answer': 'faqManageSubscriptionAns'.tr(),
      },
      {'question': 'faqDataBackup'.tr(), 'answer': 'faqDataBackupAns'.tr()},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: faqs
            .map(
              (faq) => _FAQCard(
                question: faq['question'] as String,
                answer: faq['answer'] as String,
                theme: theme,
                colorScheme: colorScheme,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildContactTab(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ContactMethodCard(
            icon: Icons.chat_rounded,
            title: 'supportChat'.tr(),
            subtitle: 'messagingSupport'.tr(),
            color: Colors.blue,
            onTap: () => context.push('/support_chat'),
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _ContactMethodCard(
            icon: Icons.email_rounded,
            title: 'emailUs'.tr(),
            subtitle: 'support@drcopilot.com',
            color: Colors.orange,
            onTap: () {
              final Uri emailLaunchUri = Uri(
                scheme: 'mailto',
                path: 'support@drcopilot.com',
                query: 'subject=Dr. Copilot Support Request',
              );
              _launchUrl(emailLaunchUri);
            },
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 16),
          _ContactMethodCard(
            icon: Icons.language_rounded,
            title: 'visitWebsite'.tr(),
            subtitle: 'www.drcopilot.com',
            color: Colors.green,
            onTap: () {
              final Uri url = Uri.parse('https://drcopilot.com');
              _launchUrl(url);
            },
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            color: colorScheme.primaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'We typically respond within 24 hours during business days.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab(ThemeData theme, ColorScheme colorScheme) {
    final resources = [
      {
        'icon': Icons.book_rounded,
        'title': 'User Documentation',
        'description': 'Complete guide to using Dr. Copilot',
        'color': Colors.blue,
      },
      {
        'icon': Icons.video_library_rounded,
        'title': 'Video Tutorials',
        'description': 'Step-by-step video guides',
        'color': Colors.red,
      },
      {
        'icon': Icons.tips_and_updates_rounded,
        'title': 'Tips & Best Practices',
        'description': 'Get the most out of the platform',
        'color': Colors.amber,
      },
      {
        'icon': Icons.update_rounded,
        'title': 'What\'s New',
        'description': 'Latest features and updates',
        'color': Colors.purple,
      },
      {
        'icon': Icons.security_rounded,
        'title': 'Privacy & Security',
        'description': 'Learn about data protection',
        'color': Colors.green,
      },
      {
        'icon': Icons.api_rounded,
        'title': 'API Documentation',
        'description': 'For advanced integrations',
        'color': Colors.cyan,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ResourceCard(
                icon: resource['icon'] as IconData,
                title: resource['title'] as String,
                description: resource['description'] as String,
                color: resource['color'] as Color,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQCard extends StatelessWidget {
  final String question;
  final String answer;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _FAQCard({
    required this.question,
    required this.answer,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.help_outline_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ContactMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                  color: color.withOpacity(0.1),
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
                      subtitle,
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

class _ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ResourceCard({
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
