import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/core/services/paddle_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanDetailsPage extends StatefulWidget {
  final String title;
  final double price;
  final bool isYearly;
  final String description;
  final List<String> features; // Summary features passed from card
  final bool isCurrent;
  final bool
  isUpgrade; // True if this is an upgrade/downgrade action (not current plan)

  const PlanDetailsPage({
    super.key,
    required this.title,
    required this.price,
    required this.isYearly,
    required this.description,
    required this.features,
    required this.isCurrent,
    required this.isUpgrade,
  });

  @override
  State<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends State<PlanDetailsPage> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    if (widget.isCurrent) return;

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
      final planId = planIds[widget.title] ?? 'pro';

      final checkoutUrl = await PaddleService.createCheckoutSession(
        planId: planId,
        clinicId: user.uid,
        period: widget.isYearly ? 'yearly' : 'monthly',
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priceText = widget.price == 0
        ? '\$0'
        : '\$${widget.price.toStringAsFixed(2)}';
    final period = widget.isYearly ? '/year' : '/month';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${widget.title} Plan Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          priceText,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          period,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Detailed Features Section
              Text(
                'What\'s Included',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ...widget.features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                feature,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Add more detailed generic features here if needed,
                    // or rely on the passed list which is now quite detailed.
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.isCurrent
                      ? null
                      : (widget.isUpgrade
                            ? _handleSubscribe
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'To downgrade, please manage your subscription in settings.',
                                    ),
                                  ),
                                );
                              }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.isCurrent
                              ? 'Current Plan'
                              : (widget.title == 'Free'
                                    ? 'Downgrade'
                                    : 'Subscribe Now'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (widget.isCurrent)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Text(
                      "You are currently subscribed to this plan.",
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

