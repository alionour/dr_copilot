import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return StreamBuilder(
      stream: authBloc.userAuthenticationStream(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OwnerNotifier().loadOwnerIdAndClinicId();
            RoutingConfig.router.go('/home');
          });
          return const SizedBox.shrink();
        }
        // ...existing login page UI...
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSignedIn) {
              final router = RoutingConfig.router;
              router.go('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(state.message ?? 'Unexpected error occurred')),
              );
            }
          },
          child: Scaffold(
            // appBar: appBar('Sign In'),
            body: Center(
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.85, // Make box smaller in width
                margin: const EdgeInsets.all(24.0),
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15, // Increase blur radius for more shadow
                      offset: Offset(0, 10), // Increase offset for more shadow
                    ),
                  ],
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: SvgPicture.asset(
                          'assets/svg/drcopilot_logo.svg',
                          semanticsLabel: 'App Logo',
                          width: 250,
                          height: 250,
                          placeholderBuilder: (context) => const Icon(
                            Icons.person,
                            size: 100,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'welcomeBack'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'signIn'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      key: const Key('email_text_field'),
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      key: const Key('password_text_field'),
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: () {
                        authBloc.add(SignInWithEmailAndPassword(
                          email: emailController.text,
                          password: passwordController.text,
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'login'.tr(),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('or'.tr(),
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        key: const Key('google_sign_in_button'),
                        onPressed: () {
                          authBloc.add(SignInWithGoogle());
                        },
                        icon: SvgPicture.asset(
                          'assets/svg/icons8-google-ios-17-filled/icons8-google-50.svg',
                          semanticsLabel: 'Google Logo',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.blue,
                            BlendMode.srcIn,
                          ),
                        ),
                        label: Text(
                          'SignInWithGoogle'.tr(),
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          elevation: 6,
                          shadowColor: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
