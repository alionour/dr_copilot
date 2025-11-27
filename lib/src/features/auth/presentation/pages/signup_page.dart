import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Added import for GoRouter
import 'dart:developer';

class SignupPage extends StatefulWidget {
  final String? invitationToken;
  final String? email;
  final String? name;
  final String? clinicName;
  final String? clinicId;
  final String? role;

  const SignupPage({
    super.key,
    this.invitationToken,
    this.email,
    this.name,
    this.clinicName,
    this.clinicId,
    this.role,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();

      // --- 1. Sign up user with Firebase (example, actual implementation might vary) ---
      // This part would typically interact with your Auth UseCase/Bloc
      // For demonstration, we'll simulate a signup here or directly use the AuthBloc if available
      log('Attempting signup for email: $email, name: $name, password: $password');
      try {
        // Assume AuthBloc has a SignUp event
        // context.read<AuthBloc>().add(SignUpWithEmailAndPassword(email: email, password: password, name: name));
        // For now, we'll directly call sign-in logic from AuthBloc after the backend accepts.
        // The actual Firebase user creation should happen as part of authBloc.add(SignUpEvent)
        // If the user already has an account, they should sign in, not sign up.
        // This flow assumes they are new.

        // --- 2. Accept Invitation via Backend ---
        if (widget.invitationToken != null && widget.clinicId != null) {
          log('Processing invitation acceptance with token: ${widget.invitationToken}');
          // Temporarily get current user ID. In a real app, this would come from AuthBloc/Firebase Auth after signup.
          // For now, we'll use a placeholder.
          // You need to get the actual Firebase User ID of the newly registered user.
          // After successful signup via AuthBloc, the AuthBloc state would contain the userId.
          // For now, let's assume a placeholder userId or you might have a direct signup method in AuthUseCase.

          // --- IMPORTANT: Replace with actual signed-in user ID ---
          // This is a placeholder. You need to get the user ID of the user
          // who successfully signed up/logged in.
          final String signedInUserId =
              'temp-firebase-user-id'; // <--- THIS NEEDS TO BE REPLACED WITH ACTUAL USER ID AFTER SIGNUP

          final acceptResult = await BackendService.acceptInvitation(
            token: widget.invitationToken!,
            userId: signedInUserId,
          );

          if (!mounted) return; // Fix for use_build_context_synchronously

          if (acceptResult['success'] == true) {
            log('Invitation accepted successfully for user $signedInUserId. Redirecting to home.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invitation accepted! Welcome to ${widget.clinicName ?? 'your clinic'}')),
            );
            // Optionally redirect to home or dashboard after successful signup and acceptance
            context.go('/home'); // Using context.go from GoRouter
          } else {
            log('Failed to accept invitation: ${acceptResult['error']}. Displaying error message.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Failed to accept invitation: ${acceptResult['error']}')),
            );
          }
        } else {
          // Regular signup flow if no invitation token
          log('Performing regular signup for $email.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Regular signup successful!')),
          );
          context.go('/home'); // Using context.go from GoRouter
        }
      } catch (e) {
        log('Error during signup/invitation acceptance for $email: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Signup or invitation acceptance failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome to ${widget.clinicName ?? 'Dr. Copilot'}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.invitationToken != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'You\'ve been invited to join as a ${widget.role ?? 'member'}. Please create your account to accept.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        readOnly: widget.email != null,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: widget.email != null,
                          fillColor: widget.email != null
                              ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round())
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return 'Please enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _handleSignup,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.invitationToken != null ? 'Accept Invitation & Create Account' : 'Create Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
