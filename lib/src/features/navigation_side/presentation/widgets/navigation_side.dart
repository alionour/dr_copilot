import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/copilot/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/evaluations/presentation/pages/evaluations_page.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart'; // Import PatientsPage
import 'package:dr_copilot/src/features/sessions/presentation/pages/sessions_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';
import 'package:go_router/go_router.dart';

/// A widget that provides a side navigation menu and displays the selected page.
class NavigationSide extends StatefulWidget {
  final Widget child;
  const NavigationSide({super.key, required this.child});

  @override
  State<NavigationSide> createState() => _NavigationSideState();
}

class _NavigationSideState extends State<NavigationSide> {
  final FocusNode _navigationFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationFocusNode.requestFocus();
      debugPrint('Navigation focus node requested focus');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NavigationBloc>();
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSignedOut) {
          debugPrint('User signed out');
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            BlocBuilder<NavigationBloc, NavigationState>(
              builder: (context, state) {
                return Focus(
                  focusNode: _navigationFocusNode,
                  onKeyEvent: (FocusNode node, KeyEvent event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        _contentFocusNode.requestFocus();
                        bloc.add(const ChangeFocusEvent(false));
                        debugPrint('Content focus node requested focus');
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowDown) {
                        context.read<NavigationBloc>().add(NavigateDownEvent());
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        context.read<NavigationBloc>().add(NavigateUpEvent());
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                    color: bloc.state.isNavigationFocused
                        ? Colors.blue.withAlpha((0.2 * 255).toInt())
                        : Colors.transparent,
                    padding: const EdgeInsets.all(8.0),
                    child: BlocBuilder<NavigationBloc, NavigationState>(
                      builder: (context, state) {
                        return SideMenu(
                          mode: SideMenuMode.open,
                          hasResizer: false,
                          hasResizerToggle: true,
                          resizerToggleData: const ResizerToggleData(),
                          builder: (data) {
                            return SideMenuData(
                              header: Column(
                                children: [
                                  ListTile(
                                    leading:
                                        const Icon(Icons.crop_5_4_outlined),
                                    title: const Text(
                                      'Dr Copilot',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ).showOrNull(data.isOpen),
                                    trailing: const Icon(Icons.search)
                                        .showOrNull(data.isOpen),
                                  ),
                                  // if (data.isOpen) const ChipTabBar()
                                ],
                              ),
                              items: [
                                ...[
                                  Destination.calendar,
                                  Destination.chat,
                                  Destination.copilot,
                                  Destination.patients,
                                  Destination.settings,
                                  Destination.notifications,
                                ].map(
                                  (e) => SideMenuItemDataTile(
                                    isSelected: state.destination == e,
                                    onTap: () {
                                      context
                                          .read<NavigationBloc>()
                                          .add(NavigateToEvent(e));
                                    },
                                    title: e.model.title,
                                    tooltip: e.message,
                                    icon: Icon(
                                      e.model.icon,
                                      color: const Color(0xff0055c3),
                                    ),
                                  ),
                                ),
                                if (data.isOpen)
                                  const SideMenuItemDataTitle(
                                      title: 'Appointments',
                                      padding: EdgeInsetsDirectional.all(8)),
                                ...[
                                  Destination.sessions,
                                  Destination.evaluations
                                ].map(
                                  (e) => SideMenuItemDataTile(
                                    isSelected: state.destination == e,
                                    onTap: () {
                                      context
                                          .read<NavigationBloc>()
                                          .add(NavigateToEvent(e));
                                    },
                                    title: e.model.title,
                                    tooltip: e.message,
                                    icon: Icon(
                                      e.model.icon,
                                      color: const Color(0xff0055c3),
                                    ),
                                  ),
                                ),
                              ],
                              footer: data.isOpen
                                  ? BlocBuilder<NavigationBloc,
                                          NavigationState>(
                                      builder:
                                          (context, NavigationState state) {
                                      final String profileImageUrl =
                                          state.user?.photoURL ?? '';
                                      return ListTile(
                                        title:
                                            Text(state.user?.displayName ?? '')
                                                .showOrNull(data.isOpen),
                                        leading: profileImageUrl.isNotEmpty
                                            ? InkWell(
                                                onTap: () {
                                                  context.go(
                                                      '/account'); // Navigate to the account page when tapped
                                                },
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle),
                                                  child: ClipOval(
                                                    child: CachedNetworkImage(
                                                      imageUrl: profileImageUrl,
                                                      cacheKey: state.user
                                                          ?.uid, // Use the user's UID as a unique cache key
                                                      placeholder: (ctx, url) =>
                                                          const Icon(Icons
                                                              .person_pin), // Placeholder icon while loading
                                                      errorWidget: (context,
                                                          url, error) {
                                                        debugPrint(
                                                            'Failed to load image: $error'); // Log errors if the image fails to load
                                                        return const SizedBox(); // Return an empty widget on error
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const Icon(Icons
                                                .person_3_outlined), // Default icon if no profile image is available
                                      );
                                    })
                                  : const SizedBox(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<NavigationBloc, NavigationState>(
                builder: (context, state) {
                  return Focus(
                    focusNode: _contentFocusNode,
                    onKeyEvent: (FocusNode node, KeyEvent event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          _navigationFocusNode.requestFocus();
                          bloc.add(const ChangeFocusEvent(true));
                          debugPrint('Navigation focus node requested focus');
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Container(
                      color: !bloc.state.isNavigationFocused
                          ? Colors.blue.withAlpha((0.2 * 255).toInt())
                          : Colors.transparent,
                      padding: const EdgeInsets.all(8),
                      child: BlocBuilder<NavigationBloc, NavigationState>(
                        builder: (context, state) {
                          if (state.destination == Destination.copilot) {
                            return const Center(
                                child: CopilotPage(
                              title: 'Dr Copilot',
                            ));
                          } else if (state.destination ==
                              Destination.calendar) {
                            return const Center(
                              child: CalendarPage(),
                            );
                          } else if (state.destination ==
                              Destination.settings) {
                            return const Center(
                              child: SettingsPage(),
                            );
                          } else if (state.destination ==
                              Destination.notifications) {
                            return const Center(
                              child: NotificationsPage(),
                            );
                          } else if (state.destination ==
                              Destination.patients) {
                            return const PatientsPage();
                          } else if (state.destination ==
                              Destination.sessions) {
                            return const Center(
                              child: SessionsPage(),
                            );
                          } else if (state.destination ==
                              Destination.evaluations) {
                            return const Center(
                              child: EvaluationsPage(),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension method to conditionally show a widget.
extension on Widget {
  Widget? showOrNull(bool isShow) => isShow ? this : null;
}
