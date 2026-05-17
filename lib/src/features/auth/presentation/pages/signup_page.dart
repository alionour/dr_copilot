import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
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
  bool _isLoading = false;

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

      log(
        'Attempting signup for email: $email, name: $name, password: $password',
      );
      setState(() {
        _isLoading = true;
      });

      try {
        // --- 1. Sign up user with Firebase via AuthUseCase ---
        final signupResult = await sl<AuthUseCase>().signUpWithEmailAndPassword(email, password);

        String? signedInUserId;
        await signupResult.fold(
          (failure) async {
            throw Exception(failure.message);
          },
          (userModel) async {
            signedInUserId = userModel?.uid;
            log('Firebase user created successfully with UID: $signedInUserId');
          },
        );

        if (signedInUserId == null) {
          throw Exception('Failed to retrieve user ID after registration.');
        }

        // --- 2. Update display name in user profile ---
        final updateProfileResult = await sl<AuthUseCase>().updateProfile(displayName: name);
        updateProfileResult.fold(
          (failure) => log('Warning: Failed to set display name: ${failure.message}'),
          (_) => log('Display name updated to: $name'),
        );

        // --- 3. Accept Invitation via Backend ---
        if (widget.invitationToken != null && widget.clinicId != null) {
          log(
            'Processing invitation acceptance with token: ${widget.invitationToken}',
          );

          final acceptResult = await BackendService.acceptInvitation(
            token: widget.invitationToken!,
            userId: signedInUserId!,
          );

          if (!mounted) return; // Fix for use_build_context_synchronously

          if (acceptResult['success'] == true) {
            log(
              'Invitation accepted successfully for user $signedInUserId. Redirecting to home.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(
                  'invitationAccepted'.tr(
                    args: [widget.clinicName ?? 'your clinic'],
                  ),
                )),
              ),
            );
            // Navigate to home after successful acceptance
            context.go('/home'); // Using context.go from GoRouter
          } else {
            log(
              'Failed to accept invitation: ${acceptResult['error']}. Displaying error message.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(
                  'invitationAcceptanceFailed'.tr(
                    args: [acceptResult['error']],
                  ),
                )),
              ),
            );
          }
        } else {
          // Regular signup flow if no invitation token
          log('Performing regular signup for $email.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text('regularSignupSuccessful'.tr()))),
          );
          context.go('/home'); // Using context.go from GoRouter
        }
      } catch (e) {
        log('Error during signup/invitation acceptance for $email: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text('signupFailed'.tr(args: [e.toString()])))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('signUp'.tr()), centerTitle: true),
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
                        'welcomeTo'.tr(
                          args: [widget.clinicName ?? 'Dr. Copilot'],
                        ),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.invitationToken != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'invitationMessage'.tr(
                            args: [widget.role ?? 'member'],
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'name'.tr(),
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'enterName'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        readOnly: widget.email != null,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(),
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: widget.email != null,
                          fillColor: widget.email != null
                              ? Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha((255 * 0.5).round())
                              : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'enterValidEmail'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'password'.tr(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'enterPassword'.tr();
                          }
                          if (value.length < 6) {
                            return 'passwordLengthError'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'confirmPassword'.tr(),
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'confirmPasswordError'.tr();
                          }
                          if (value != _passwordController.text) {
                            return 'passwordsDoNotMatch'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                widget.invitationToken != null
                                    ? 'acceptInvitationAndCreateAccount'.tr()
                                    : 'createAccount'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          'alreadyHaveAccount'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
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

