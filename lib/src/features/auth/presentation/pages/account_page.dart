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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectionArea(
          child: Text('copiedToClipboard'.tr()),
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
    String? copyValue,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: textTheme.bodyLarge,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (copyValue != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).copyButtonLabel,
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(context, copyValue),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerNotifier = context.watch<OwnerNotifier>();
    final locale = context.locale.toString();

    final userId = user?.uid;
    final phoneNumber = user?.phoneNumber;
    final creationTime = user?.metadata.creationTime;
    final lastSignInTime = user?.metadata.lastSignInTime;

    return Scaffold(
      appBar: AppBar(
        title: Text('account'.tr()),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back),
          onPressed: () {
            context.pop();
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
                    final photoUrl = user.photoURL;
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
                                width: MediaQuery.of(context).size.shortestSide * 0.7,
                                height: MediaQuery.of(context).size.shortestSide * 0.7,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user!.photoURL!),
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
                        child: Text(
                          'personalInfo'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: _infoRow(
                          context,
                          label: 'name'.tr(),
                          value: user?.displayName ?? 'not_available'.tr(),
                          copyValue: user?.displayName,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: _infoRow(
                          context,
                          label: 'email'.tr(),
                          value: user?.email ?? 'not_available'.tr(),
                          copyValue: user?.email,
                        ),
                      ),
                      if (userId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: _infoRow(
                            context,
                            label: 'userId'.tr(),
                            value: userId,
                            copyValue: userId,
                          ),
                        ),
                      if (phoneNumber != null && phoneNumber.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: _infoRow(
                            context,
                            label: 'phoneNumber'.tr(),
                            value: phoneNumber,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: _infoRow(
                          context,
                          label: 'emailVerified'.tr(),
                          value: user?.emailVerified == true
                              ? 'yes'.tr()
                              : 'no'.tr(),
                        ),
                      ),
                      if (creationTime != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: _infoRow(
                            context,
                            label: 'accountCreationTime'.tr(),
                            value: DateFormat.yMd(locale)
                                .add_jm()
                                .format(creationTime),
                          ),
                        ),
                      if (lastSignInTime != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: _infoRow(
                            context,
                            label: 'lastSignInTime'.tr(),
                            value: DateFormat.yMd(locale)
                                .add_jm()
                                .format(lastSignInTime),
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
                        child: Text(
                          'clinicInfo'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (ownerNotifier.clinicId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 16.0,
                          ),
                          child: Builder(
                            builder: (context) {
                              final primaryClinic = ownerNotifier.clinics
                                  .firstWhereOrNull(
                                    (c) => c.id == ownerNotifier.clinicId,
                                  );

                              return _infoRow(
                                context,
                                label: 'primaryClinic'.tr(),
                                value:
                                    primaryClinic?.name ?? 'not_available'.tr(),
                              );
                            },
                          ),
                        ),
                      if (ownerNotifier.clinics.length > 1 &&
                          ownerNotifier.clinicId != null)
                        ExpansionTile(
                          title: Text('otherClinics'.tr()),
                          children: ownerNotifier.clinics
                              .where((c) => c.id != ownerNotifier.clinicId)
                              .map(
                                (clinic) => ListTile(
                                  title: Text(clinic.name),
                                  subtitle: Text(clinic.id),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('logout_button'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('signOut'.tr()),
                      content: Text('signOutConfirm'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<AuthBloc>().add(SignOutEvent());
                          },
                          child: Text(
                            'signOut'.tr(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
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

