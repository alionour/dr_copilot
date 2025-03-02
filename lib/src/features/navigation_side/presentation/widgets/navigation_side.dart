import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/copilot/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart'; // Import PatientsPage
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return Scaffold(
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
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
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
                                  leading: const Icon(Icons.crop_5_4_outlined),
                                  title: const Text(
                                    'Dr Copilot',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ).showOrNull(data.isOpen),
                                  trailing: const Icon(Icons.search)
                                      .showOrNull(data.isOpen),
                                ),
                                // if (data.isOpen) const ChipTabBar()
                              ],
                            ),
                            items: [
                              SideMenuItemDataTile(
                                isSelected:
                                    state.destination == Destination.copilot,
                                onTap: () {
                                  context.read<NavigationBloc>().add(
                                      const NavigateToEvent(
                                          Destination.copilot));
                                },
                                title: Destination.copilot.model.title,
                                icon: Icon(
                                  Destination.copilot.model.icon,
                                  color: const Color(0xff0055c3),
                                ),
                              ),
                              SideMenuItemDataTile(
                                isSelected:
                                    state.destination == Destination.calendar,
                                onTap: () {
                                  context.read<NavigationBloc>().add(
                                      const NavigateToEvent(
                                          Destination.calendar));
                                },
                                title: Destination.calendar.model.title,
                                icon: Icon(
                                  Destination.calendar.model.icon,
                                  color: const Color(0xff0055c3),
                                ),
                              ),
                              SideMenuItemDataTile(
                                isSelected:
                                    state.destination == Destination.patients,
                                onTap: () {
                                  context.read<NavigationBloc>().add(
                                      const NavigateToEvent(
                                          Destination.patients));
                                },
                                title: Destination.patients.model.title,
                                icon: Icon(
                                  Destination.patients.model.icon,
                                  color: const Color(0xff0055c3),
                                ),
                              ),
                              SideMenuItemDataTile(
                                isSelected: state.destination ==
                                    Destination.notifications,
                                onTap: () {
                                  context.read<NavigationBloc>().add(
                                      const NavigateToEvent(
                                          Destination.notifications));
                                },
                                title: Destination.notifications.model.title,
                                icon: Icon(
                                  Destination.notifications.model.icon,
                                  color: const Color(0xff0055c3),
                                ),
                              ),
                              SideMenuItemDataTile(
                                isSelected:
                                    state.destination == Destination.settings,
                                onTap: () {
                                  context.read<NavigationBloc>().add(
                                      const NavigateToEvent(
                                          Destination.settings));
                                },
                                title: Destination.settings.model.title,
                                icon: Icon(
                                  Destination.settings.model.icon,
                                  color: const Color(0xff0055c3),
                                ),
                              ),
                            ],
                            footer: data.isOpen
                                ? BlocBuilder<NavigationBloc, NavigationState>(
                                    builder: (context, NavigationState state) {
                                    final String profileImageUrl =
                                        state.user?.userMetadata?['picture'] ??
                                            '';
                                    return ListTile(
                                      title: Text(state.user?.userMetadata?[
                                                  'full_name'] ??
                                              '')
                                          .showOrNull(data.isOpen),
                                      trailing: IconButton(
                                          onPressed: () async {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            context.go('/');
                                          },
                                          icon: const Icon(
                                              Icons.logout_outlined)),
                                      leading: profileImageUrl.isNotEmpty
                                          ? Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle),
                                              child: CachedNetworkImage(
                                                imageUrl: profileImageUrl,
                                                placeholder: (ctx, url) =>
                                                    const Icon(
                                                        Icons.person_pin),
                                                errorWidget:
                                                    (context, url, error) {
                                                  debugPrint(
                                                      'Failed to load image: $error');
                                                  return const SizedBox();
                                                },
                                              ),
                                            )
                                          : const Icon(Icons.person_3_outlined),
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
                        } else if (state.destination == Destination.calendar) {
                          return const Center(
                            child: CalendarPage(),
                          );
                        } else if (state.destination == Destination.settings) {
                          return const Center(
                            child: SettingsPage(),
                          );
                        } else if (state.destination ==
                            Destination.notifications) {
                          return const Center(
                            child: NotificationsPage(),
                          );
                        } else if (state.destination == Destination.patients) {
                          return const PatientsPage();
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
    );
  }
}

/// Extension method to conditionally show a widget.
extension on Widget {
  Widget? showOrNull(bool isShow) => isShow ? this : null;
}
