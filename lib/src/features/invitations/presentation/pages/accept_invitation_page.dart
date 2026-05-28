import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:go_router/go_router.dart';

class AcceptInvitationPage extends StatefulWidget {
  final String token;

  const AcceptInvitationPage({super.key, required this.token});

  @override
  State<AcceptInvitationPage> createState() => _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends State<AcceptInvitationPage> {
  bool _loading = true;
  bool _valid = false;
  Map<String, dynamic>? _invitation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verifyInvitation();
  }

  Future<void> _verifyInvitation() async {
    final result = await BackendService.verifyInvitation(widget.token);

    if (mounted) {
      setState(() {
        _loading = false;
        _valid = result['valid'] ?? false;
        _invitation = result['invitation'];
        _error = result['error'];
      });
    }
  }

  void _acceptInvitation() {
    // Navigate to signup page with invitation data
    context.go('/signup', extra: {
      'invitationToken': widget.token,
      'email': _invitation!['recipientEmail'],
      'name': _invitation!['recipientName'],
      'clinicName': _invitation!['clinicName'],
      'clinicId': _invitation!['clinicId'],
      'role': _invitation!['role'],
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerBlock(width: 100, height: 100),
              SizedBox(height: 24),
              ShimmerBlock(width: 200, height: 20),
            ],
          ),
        ),
      );
    }

    if (!_valid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invalid Invitation')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Invitation Invalid',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'This invitation link is not valid.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invitation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You\'re Invited!',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildInfoRow(
                    context,
                    Icons.business,
                    'Clinic',
                    _invitation!['clinicName'],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.badge,
                    'Role',
                    _invitation!['role'],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    Icons.email,
                    'Email',
                    _invitation!['recipientEmail'],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _acceptInvitation,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Accept & Sign Up'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
