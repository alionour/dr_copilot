import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:dr_copilot/src/features/subscription/presentation/pages/plan_details_page.dart';

class SubscriptionPricingPage extends StatefulWidget {
  const SubscriptionPricingPage({super.key});

  @override
  State<SubscriptionPricingPage> createState() =>
      _SubscriptionPricingPageState();
}

class _SubscriptionPricingPageState extends State<SubscriptionPricingPage> {
  bool _isYearly = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    // Stream the clinic document to get real-time subscription status
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
                .collection('clinics')
                .doc(user.uid)
                .snapshots()
          : null,
      builder: (context, snapshot) {
        // Determine current plan from Firestore data
        String currentPlan = 'free';
        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final tierStr = data?['subscriptionTier'] as String?;
          currentPlan = SubscriptionTier.fromString(tierStr).name;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'subscriptionAndBilling'.tr(),
              style: TextStyle(color: colorScheme.onSurface),
            ),
            iconTheme: IconThemeData(color: colorScheme.onSurface),
            bottom: _isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4.0),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: SingleChildScrollView(
            child: IgnorePointer(
              ignoring: _isLoading,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Text(
                          'All-In-One Price, Zero Hassle.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock advanced AI features and manage your clinic effectively.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleButton('Monthly', !_isYearly, () {
                                setState(() => _isYearly = false);
                              }),
                              _buildToggleButton('Yearly', _isYearly, () {
                                setState(() => _isYearly = true);
                              }, badge: 'Save 20%'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _PricingCard(
                            title: 'Free',
                            monthlyPrice: 0,
                            yearlyPrice: 0,
                            description: 'Perfect for trying out Dr. Copilot',
                            features: const [
                              '50 Patients Total',
                              '50 Sessions / Month',
                              '50 Evaluations / Month',
                              '5 AI Chats / Day (Gemini Flash)',
                              '1 User (No Team Access)',
                              'No Data Export',
                            ],
                            buttonText: 'Read More',
                            isPopular: false,
                            isCurrent: currentPlan == 'free',
                            isYearly: _isYearly,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanDetailsPage(
                                    title: 'Free',
                                    price: 0,
                                    isYearly: _isYearly,
                                    description:
                                        'Perfect for trying out Dr. Copilot',
                                    features: const [
                                      '50 Patients Total',
                                      '50 Sessions / Month',
                                      '50 Evaluations / Month',
                                      '5 AI Chats / Day (Gemini Flash)',
                                      '1 User (No Team Access)',
                                      'No Data Export',
                                    ],
                                    isCurrent: currentPlan == 'free',
                                    isUpgrade: false,
                                  ),
                                ),
                              );
                            },
                          ),
                          _PricingCard(
                            title: 'Pro',
                            monthlyPrice: 9.99,
                            yearlyPrice: 95.90,
                            description: 'Best for growing clinics',
                            features: const [
                              '1,000 Patients',
                              '3,000 Sessions / Month',
                              '1,500 Evaluations / Month',
                              'Team: 3 Doctors, 5 Staff',
                              '100 AI Chats / Day (GPT-4o Mini)',
                              '50 Image Analyses / Month',
                            ],
                            buttonText: 'Read More',
                            isPopular: true,
                            isCurrent: currentPlan == 'pro',
                            isYearly: _isYearly,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanDetailsPage(
                                    title: 'Pro',
                                    price: _isYearly ? 95.90 : 9.99,
                                    isYearly: _isYearly,
                                    description: 'Best for growing clinics',
                                    features: const [
                                      '1,000 Patients',
                                      '3,000 Sessions / Month',
                                      '1,500 Evaluations / Month',
                                      'Team: 3 Doctors, 5 Staff',
                                      '100 AI Chats / Day (GPT-4o Mini)',
                                      '50 Image Analyses / Month',
                                    ],
                                    isCurrent: currentPlan == 'pro',
                                    isUpgrade: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _PricingCard(
                            title: 'Elite',
                            monthlyPrice: 24.99,
                            yearlyPrice: 239.90,
                            description: 'For power users & large clinics',
                            features: const [
                              '10,000 Patients',
                              '50,000 Sessions / Month',
                              '25,000 Evaluations / Month',
                              'Team: 15 Doctors, 30 Staff',
                              '500 AI Chats / Day (Claude 3.5)',
                              '500 Image Analyses / Month',
                            ],
                            buttonText: 'Read More',
                            isPopular: false,
                            isCurrent: currentPlan == 'elite',
                            isYearly: _isYearly,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlanDetailsPage(
                                    title: 'Elite',
                                    price: _isYearly ? 239.90 : 24.99,
                                    isYearly: _isYearly,
                                    description:
                                        'For power users & large clinics',
                                    features: const [
                                      '10,000 Patients',
                                      '50,000 Sessions / Month',
                                      '25,000 Evaluations / Month',
                                      'Team: 15 Doctors, 30 Staff',
                                      '500 AI Chats / Day (Claude 3.5)',
                                      '500 Image Analyses / Month',
                                    ],
                                    isCurrent: currentPlan == 'elite',
                                    isUpgrade: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ];

                        if (constraints.maxWidth > 900) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                Expanded(child: cards[i]),
                                if (i < cards.length - 1)
                                  const SizedBox(width: 16),
                              ],
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                cards[i],
                                if (i < cards.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    String? badge,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PricingCard extends StatefulWidget {
  final String title;
  final double monthlyPrice;
  final double yearlyPrice;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool isPopular;
  final bool isCurrent;
  final bool isYearly;
  final VoidCallback? onPressed;

  const _PricingCard({
    required this.title,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.isPopular,
    this.isCurrent = false,
    required this.isYearly,
    this.onPressed,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final price = widget.isYearly ? widget.yearlyPrice : widget.monthlyPrice;
    final priceText = price == 0 ? '\$0' : '\$${price.toStringAsFixed(2)}';
    final period = widget.isYearly ? '/year' : '/month';

    // Theme-based colors
    final popularGradient = LinearGradient(
      colors: [colorScheme.primary, colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Using tertiary for "Current Plan" to distinguish from "Popular" (Primary)
    final currentPlanColor = colorScheme.tertiary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isPopular ? popularGradient : null,
            color: widget.isPopular
                ? null
                : colorScheme.surfaceContainer, // Darker card background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isCurrent
                  ? currentPlanColor
                  : (widget.isPopular
                        ? Colors.transparent
                        : theme.dividerColor),
              width: widget.isCurrent ? 2 : 1,
            ),
            boxShadow: _isHovered || widget.isPopular || widget.isCurrent
                ? [
                    BoxShadow(
                      color: widget.isCurrent
                          ? currentPlanColor.withOpacity(0.3)
                          : (widget.isPopular
                                ? colorScheme.primary.withOpacity(0.4)
                                : Colors.black.withOpacity(0.1)),
                      blurRadius: _isHovered ? 30 : 20,
                      offset: Offset(0, _isHovered ? 15 : 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isCurrent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: currentPlanColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: currentPlanColor),
                    ),
                    child: Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        color: currentPlanColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else if (widget.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (widget.isPopular || widget.isCurrent)
                  const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isPopular
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: widget.isPopular
                        ? colorScheme.onPrimary.withOpacity(0.7)
                        : colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        priceText,
                        key: ValueKey(priceText),
                        style: TextStyle(
                          color: widget.isPopular
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: widget.isPopular
                              ? colorScheme.onPrimary.withOpacity(0.7)
                              : colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...widget.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: widget.isPopular
                              ? colorScheme.onPrimary
                              : (widget.isCurrent
                                    ? currentPlanColor
                                    : colorScheme.primary),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: widget.isPopular
                                  ? colorScheme.onPrimary.withOpacity(0.9)
                                  : colorScheme.onSurface.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isPopular
                          ? colorScheme.surface
                          : (widget.isCurrent
                                ? currentPlanColor.withOpacity(0.2)
                                : colorScheme.primary),
                      foregroundColor: widget.isPopular
                          ? colorScheme.primary
                          : colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isHovered ? 8 : 0,
                    ),
                    child: Text(
                      widget.buttonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
