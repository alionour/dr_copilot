// import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class UpdatePasswordPage extends StatelessWidget {
//   final TextEditingController _currentPasswordController =
//       TextEditingController();
//   final TextEditingController _newPasswordController = TextEditingController();
//   final TextEditingController _confirmPasswordController =
//       TextEditingController();

//   UpdatePasswordPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Update Password'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: BlocProvider(
//           create: (context) => AuthBloc(),
//           child: BlocListener<AuthBloc, AuthState>(
//             listener: (context, state) {
//               if (state is Authenticated) {
//                 Navigator.pop(context);
//               } else if (state is AuthError) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(state.message)),
//                 );
//               }
//             },
//             child: BlocBuilder<AuthBloc, AuthState>(
//               builder: (context, state) {
//                 if (state is AuthLoading) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return Column(
//                   children: <Widget>[
//                     TextField(
//                       controller: _currentPasswordController,
//                       decoration:
//                           const InputDecoration(labelText: 'Current Password'),
//                       obscureText: true,
//                     ),
//                     TextField(
//                       controller: _newPasswordController,
//                       decoration:
//                           const InputDecoration(labelText: 'New Password'),
//                       obscureText: true,
//                     ),
//                     TextField(
//                       controller: _confirmPasswordController,
//                       decoration:
//                           const InputDecoration(labelText: 'Confirm Password'),
//                       obscureText: true,
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () {
//                         final currentPassword = _currentPasswordController.text;
//                         final newPassword = _newPasswordController.text;
//                         final confirmPassword = _confirmPasswordController.text;
//                         if (newPassword == confirmPassword) {
//                           BlocProvider.of<AuthBloc>(context).add(
//                             UpdatePasswordEvent(
//                               currentPassword: currentPassword,
//                               newPassword: newPassword,
//                             ),
//                           );
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                                 content: Text('Passwords do not match')),
//                           );
//                         }
//                       },
//                       child: const Text('Update Password'),
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
