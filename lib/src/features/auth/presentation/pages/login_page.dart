import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSignedIn) {
          // Ensure router is properly initialized
          final router = RoutingConfig.router;
          router.go('/home');
        } else if (state is AuthError) {
          // Handle error state if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
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
              color: Colors.white,
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
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/svg/logo.svg',
                        semanticsLabel: 'App Logo',
                        width: 100,
                        height: 100,
                        placeholderBuilder: (context) => const Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Please sign in to continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                Center(
                  child: ElevatedButton.icon(
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
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.grey),
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
  }
}
