import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

const optionText = Text(
  'Or',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  textAlign: TextAlign.center,
);

const spacer = SizedBox(
  height: 12,
);

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
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
          body: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Dark theme example
              // Card(
              //     elevation: 10,
              //     color: const Color.fromARGB(255, 24, 24, 24),
              //     child: Padding(
              //       padding: const EdgeInsets.all(30),
              //       child: Theme(
              //         data: darkModeThemeData,
              //         child: SupaEmailAuth(
              //             redirectTo: kIsWeb ? null : 'io.supabase.flutter://',
              //             onSignInComplete: navigateHome,
              //             onSignUpComplete: navigateHome,
              //             prefixIconEmail: null,
              //             prefixIconPassword: null,
              //             localization: const SupaEmailAuthLocalization(
              //                 enterEmail: "email",
              //                 enterPassword: "password",
              //                 dontHaveAccount: "sign up",
              //                 forgotPassword: "forgot password"),
              //             metadataFields: [
              //               MetaDataField(
              //                 prefixIcon: const Icon(Icons.person),
              //                 label: 'Username',
              //                 key: 'username',
              //                 validator: (val) {
              //                   if (val == null || val.isEmpty) {
              //                     return 'Please enter something';
              //                   }
              //                   return null;
              //                 },
              //               ),
              //               BooleanMetaDataField(
              //                 label:
              //                     'Keep me up to date with the latest news and updates.',
              //                 key: 'marketing_consent',
              //                 checkboxPosition: ListTileControlAffinity.leading,
              //               ),
              //               BooleanMetaDataField(
              //                 key: 'terms_agreement',
              //                 isRequired: true,
              //                 checkboxPosition: ListTileControlAffinity.leading,
              //                 richLabelSpans: [
              //                   const TextSpan(
              //                       text: 'I have read and agree to the '),
              //                   TextSpan(
              //                     text: 'Terms and Conditions.',
              //                     style: const TextStyle(
              //                       color: Colors.blue,
              //                     ),
              //                     recognizer: TapGestureRecognizer()
              //                       ..onTap = () {
              //                         //ignore: avoid_print
              //                         print('Terms and Conditions');
              //                       },
              //                   ),
              //                 ],
              //               ),
              //             ]),
              //       ),
              //     )),
              // spacer,
              Center(
                child: IconButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(SignInWithGoogle());
                    },
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/svg/icons8-google-ios-17-filled/icons8-google-50.svg',
                          semanticsLabel: 'Google Logo',
                          width: 24,
                          height: 24,
                        ),
                        const Text('Sign in with Google'),
                      ],
                    )),
              ),
              // SupaSocialsAuth(
              //   colored: true,
              //   nativeGoogleAuthConfig: const NativeGoogleAuthConfig(
              //     webClientId:
              //         '991809114105-7st6rs7ntt1a8j2rdp8iveffjhobsn93.apps.googleusercontent.com',
              //     iosClientId:
              //         '991809114105-gjmdi9v4bjvhbh11a3khbb3ah1606fqb.apps.googleusercontent.com',
              //   ),
              //   enableNativeAppleAuth: false,
              //   socialProviders: const [
              //     // OAuthProvider.apple,
              //     OAuthProvider.google,
              //     // OAuthProvider.facebook
              //   ],
              //   onSuccess: (session) {
              //     context.go('/home');
              //   },
              //   onError: (error) {
              //     debugPrint('Auth Error: $error');
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
