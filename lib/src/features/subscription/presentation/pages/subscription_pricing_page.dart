import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionPricingPage extends StatefulWidget {
  const SubscriptionPricingPage({super.key});

  @override
  State<SubscriptionPricingPage> createState() =>
      _SubscriptionPricingPageState();
}

class _SubscriptionPricingPageState extends State<SubscriptionPricingPage> {
  bool _isYearly = false;

  Future<void> _handleUpgrade(String planTitle) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectionArea(child: Text('planPleaseSignIn'.tr()))));
        return;
      }

      // Map plan names to IDs
      final planIds = {'Pro': 'pro', 'Elite': 'elite'};

      // Construct Paymob Checkout URL
      final baseUrl = BackendService.baseUrl;
      final checkoutUrl = '$baseUrl/subscription_checkout.html'
          '?plan=${planIds[planTitle] ?? 'pro'}'
          '&period=${_isYearly ? 'yearly' : 'monthly'}'
          '&userId=${user.uid}'
          '&email=${user.email ?? ''}'
          '&clinicId=${user.uid}';

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text('planPaymentOpened'.tr()))),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text('planCouldNotOpenPayment'.tr()))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('Error: $e')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('subscriptionAndBilling'.tr()),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text(
                    'planHeaderTitle'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'planSubHeader'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'planDescription'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 32),

                  // Billing Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2D3458)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleButton('planMonthly'.tr(), !_isYearly, () {
                          setState(() => _isYearly = false);
                        }),
                        _buildToggleButton('planYearly'.tr(), _isYearly, () {
                          setState(() => _isYearly = true);
                        }, badge: 'planSavePercent'.tr()),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pricing Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    _PricingCard(
                      title: 'planFree'.tr(),
                      monthlyPrice: 0,
                      yearlyPrice: 0,
                      description: 'planFreeDesc'.tr(),
                      features: [
                        'planFreeFeature1'.tr(),
                        'planFreeFeature2'.tr(),
                        'planFreeFeature3'.tr(),
                        'planFreeFeature4'.tr(),
                      ],
                      buttonText: 'planCurrentPlan'.tr(),
                      isPopular: false,
                      isCurrent: true,
                      isYearly: _isYearly,
                      onUpgrade: null,
                    ),
                    _PricingCard(
                      title: 'planPro'.tr(),
                      monthlyPrice: 9.99,
                      yearlyPrice: 95.90,
                      description: 'planProDesc'.tr(),
                      features: [
                        'planProFeature1'.tr(),
                        'planProFeature2'.tr(),
                        'planProFeature3'.tr(),
                        'planProFeature4'.tr(),
                        'planProFeature5'.tr(),
                        'planProFeature6'.tr(),
                      ],
                      buttonText: 'planGetStarted'.tr(),
                      isPopular: true,
                      isYearly: _isYearly,
                      onUpgrade: () => _handleUpgrade('Pro'),
                    ),
                    _PricingCard(
                      title: 'planElite'.tr(),
                      monthlyPrice: 24.99,
                      yearlyPrice: 239.90,
                      description: 'planEliteDesc'.tr(),
                      features: [
                        'planEliteFeature1'.tr(),
                        'planEliteFeature2'.tr(),
                        'planEliteFeature3'.tr(),
                        'planEliteFeature4'.tr(),
                        'planEliteFeature5'.tr(),
                      ],
                      buttonText: 'planGetStarted'.tr(),
                      isPopular: false,
                      isYearly: _isYearly,
                      onUpgrade: () => _handleUpgrade('Elite'),
                    ),
                  ];

                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 16),
                        ],
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          cards[i],
                          if (i < cards.length - 1) const SizedBox(height: 16),
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
    );
  }

  Widget _buildToggleButton(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    String? badge,
  }) {
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
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (badge != null && isSelected) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
    final priceText = price == 0 ? 'planPriceFree'.tr() : '\$${price.toStringAsFixed(2)}';
    final period = widget.isYearly ? 'planPerYear'.tr() : 'planPerMonth'.tr();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.diagonal3Values(_isHovered ? 1.02 : 1.0,
            _isHovered ? 1.02 : 1.0, _isHovered ? 1.02 : 1.0),
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'planRecommended'.tr(),
                      style: const TextStyle(
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                          color: Colors.white.withValues(alpha: 0.7),
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
                              color: Colors.white.withValues(alpha: 0.9),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
