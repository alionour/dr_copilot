import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_copilot/src/core/services/paddle_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionPricingPage extends StatefulWidget {
  const SubscriptionPricingPage({super.key});

  @override
  State<SubscriptionPricingPage> createState() =>
      _SubscriptionPricingPageState();
}

class _SubscriptionPricingPageState extends State<SubscriptionPricingPage> {
  bool _isYearly = false;
  bool _isLoading = false;

  Future<void> _handleUpgrade(String planTitle) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('pleaseSignInFirst'.tr())));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final planIds = {'Pro': 'pro', 'Elite': 'elite'};
      // In a real app, map these to your actual Paddle Price IDs
      final planId = planIds[planTitle] ?? 'pro';

      final checkoutUrl = await PaddleService.createCheckoutSession(
        planId: planId,
        clinicId: user.uid,
        period: _isYearly ? 'yearly' : 'monthly',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('couldNotLaunchPaymentUrl'.tr())),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failedToCreateCheckoutSession'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      // Extract meaningful message
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Copy',
            textColor: Colors.white,
            onPressed: () {
              // Copy functionality could be added here
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          // Check subscriptionTier field. Default to 'free' if missing.
          currentPlan =
              (data?['subscriptionTier'] as String?)?.toLowerCase() ?? 'free';
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('subscriptionAndBilling'.tr()),
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
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unlock advanced AI features and manage your clinic effectively.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.8),
                              ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1F3A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2D3458)
                                  : Colors.grey[300]!,
                            ),
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
                              'Core Patient Management',
                              'Standard AI Chat (Gemini Flash)',
                              'Native Speech-to-Text',
                              '5 AI chats/day limit',
                            ],
                            buttonText: currentPlan == 'free'
                                ? 'Current Plan'
                                : 'Downgrade',
                            isPopular: false,
                            isCurrent: currentPlan == 'free',
                            isYearly: _isYearly,
                            onUpgrade: currentPlan == 'free'
                                ? null
                                : () {
                                    // Downgrade logic (usually via portal) or just show message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'To downgrade, please manage your subscription in settings.',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                          _PricingCard(
                            title: 'Pro',
                            monthlyPrice: 9.99,
                            yearlyPrice: 95.90,
                            description: 'Best for individual practitioners',
                            features: const [
                              'Unlimited AI Chat',
                              'GPT-3.5 & Gemini Access',
                              'Deepgram Speech Recognition',
                              'Cloud Backup',
                              'Basic Image Analysis',
                              '50 image analyses/month',
                            ],
                            buttonText: currentPlan == 'pro'
                                ? 'Current Plan'
                                : 'Get Started',
                            isPopular: true,
                            isCurrent: currentPlan == 'pro',
                            isYearly: _isYearly,
                            onUpgrade: currentPlan == 'pro'
                                ? null
                                : () => _handleUpgrade('Pro'),
                          ),
                          _PricingCard(
                            title: 'Elite',
                            monthlyPrice: 24.99,
                            yearlyPrice: 239.90,
                            description: 'For power users & clinics',
                            features: const [
                              'Claude 3.5 Sonnet & GPT-4o',
                              'Unlimited Image Analysis',
                              'Priority Support',
                              'Advanced Exporting',
                              'Multi-clinic Support',
                            ],
                            buttonText: currentPlan == 'elite'
                                ? 'Current Plan'
                                : 'Get Started',
                            isPopular: false,
                            isCurrent: currentPlan == 'elite',
                            isYearly: _isYearly,
                            onUpgrade: currentPlan == 'elite'
                                ? null
                                : () => _handleUpgrade('Elite'),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
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
  final VoidCallback? onUpgrade;

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
    this.onUpgrade,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final price = widget.isYearly ? widget.yearlyPrice : widget.monthlyPrice;
    final priceText = price == 0 ? '\$0' : '\$${price.toStringAsFixed(2)}';
    final period = widget.isYearly ? '/year' : '/month';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isPopular
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isPopular ? null : const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isPopular
                  ? Colors.transparent
                  : const Color(0xFF2D3458),
              width: 1,
            ),
            boxShadow: _isHovered || widget.isPopular
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
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
                if (widget.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (widget.isPopular) const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
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
                        style: const TextStyle(
                          color: Colors.white,
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
                          color: Colors.white.withOpacity(0.7),
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
                              ? Colors.white
                              : const Color(0xFF6366F1),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
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
                    onPressed: widget.isCurrent ? null : widget.onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isPopular
                          ? Colors.white
                          : const Color(0xFF6366F1),
                      foregroundColor: widget.isPopular
                          ? const Color(0xFF6366F1)
                          : Colors.white,
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
