import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentResultPage extends StatefulWidget {
  final String? status;
  final String? planId;

  const PaymentResultPage({super.key, this.status, this.planId});

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate back to settings after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/settings');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.status == 'success';

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Cancelled',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess
                    ? 'Your subscription has been activated. You now have access to all ${widget.planId ?? 'premium'} features!'
                    : 'Your payment was cancelled. You can try again anytime.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (isSuccess)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () => context.go('/settings/subscription'),
                  child: const Text('Try Again'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/settings'),
                child: Text(
                  isSuccess ? 'Redirecting to settings...' : 'Back to Settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
