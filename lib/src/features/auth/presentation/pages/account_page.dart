import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerNotifier = context.watch<OwnerNotifier>();

    final phoneNumber = user?.phoneNumber;
    final creationTime = user?.metadata?.creationTime;
    final lastSignInTime = user?.metadata?.lastSignInTime;

    return Scaffold(
      appBar: AppBar(
        title: Text('account'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user?.photoURL != null)
                GestureDetector(
                  onTap: () {
                    final photoUrl = user?.photoURL;
                    final highResUrl = photoUrl != null
                        ? photoUrl.replaceAll(RegExp(r's\d+-c'), 's400-c')
                        : '';
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: InteractiveViewer(
                            child: ClipOval(
                              child: Image.network(
                                highResUrl,
                                fit: BoxFit.cover,
                                width: 300,
                                height: 300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user?.photoURL ?? ''),
                  ),
                ),
              const SizedBox(height: 24), // Increased spacing
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('personalInfo'.tr(), style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('name'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                            Row(
                              children: [
                                if (user?.displayName != null)
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: user!.displayName!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('copiedToClipboard'.tr())),
                                      );
                                    },
                                  ),
                                Text(user?.displayName ?? 'not_available'.tr(), style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('email'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                            Row(
                              children: [
                                if (user?.email != null)
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: user!.email!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('copiedToClipboard'.tr())),
                                      );
                                    },
                                  ),
                                Text(user?.email ?? 'not_available'.tr(), style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (user?.uid != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('userId'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: user!.uid));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('copiedToClipboard'.tr())),
                                      );
                                    },
                                  ),
                                  Text(user!.uid, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (phoneNumber != null && phoneNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('phoneNumber'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                              Text(phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('emailVerified'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                            Text(user?.emailVerified == true ? 'yes'.tr() : 'no'.tr(), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      if (creationTime != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('accountCreationTime'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                              Text(DateFormat.yMd().add_jm().format(creationTime), style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      if (lastSignInTime != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('lastSignInTime'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                              Text(DateFormat.yMd().add_jm().format(lastSignInTime), style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // Spacing between sections
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('clinicInfo'.tr(), style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (ownerNotifier.clinicId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('primaryClinic'.tr(), style: Theme.of(context).textTheme.bodyLarge),
                              Text(ownerNotifier.clinics.firstWhereOrNull((c) => c.id == ownerNotifier.clinicId)?.name ?? 'not_available'.tr(), style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      if (ownerNotifier.clinics.length > 1 && ownerNotifier.clinicId != null)
                        ExpansionTile(
                          title: Text('otherClinics'.tr()),
                          children: ownerNotifier.clinics
                              .where((c) => c.id != ownerNotifier.clinicId)
                              .map((clinic) => ListTile(
                                    title: Text(clinic.name),
                                    subtitle: Text(clinic.id),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // Spacing before button
              ElevatedButton(
                onPressed: () async {
                  debugPrint('Sign-out button pressed');
                  context.read<AuthBloc>().add(SignOutEvent());
                },
                child: Text('signOut'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}